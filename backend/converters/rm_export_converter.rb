require 'date'
require 'rubyXL'
require 'zip'


class RMExportConverter < Converter

  def self.instance_for(type, input_file)
    if type == "rm_export"
      self.new(input_file)
    else
      nil
    end
  end


  def self.import_types(show_hidden = false)
    [
      {
        :name => "rm_export",
        :description => "Records Management export zip"
      }
    ]
  end


  def self.profile
    "Convert Records Management spreadsheets to ArchivesSpace JSONModel records"
  end


  def initialize(input_file)
    super
    @batch = ASpaceImport::RecordBatch.new
    @input_file = input_file
    @records = []
  end


  def run

    permit_partial = AppConfig.has_key?(:records_management_import_permit_partial) && AppConfig[:records_management_import_permit_partial]

    now = java.lang.System.currentTimeMillis
    box_file = File.join(Dir.tmpdir, "rm_export_box_#{now}")
    file_file = File.join(Dir.tmpdir, "rm_export_file_#{now}")
    puts "box_file #{box_file}"
    puts "file_file #{file_file}"

    box_sheet = nil
    file_sheet = nil

    box_uris = {}
    resource_uris = {}

    today = Date.today.strftime('%Y-%m-%d')

    Zip::File.open(@input_file) do |zip_file|
      zip_file.each do |entry|
        if entry.name.end_with? "ArchBoxExport.xlsx"
          entry.extract(box_file)
          box_sheet = RubyXL::Parser.parse(box_file)[0]
          File.unlink(box_file)
        elsif entry.name.end_with? "ArchFileExport.xlsx"
          entry.extract(file_file)
          file_sheet = RubyXL::Parser.parse(file_file)[0]
          File.unlink(file_file)
        end
      end
    end

    unless box_sheet && file_sheet
      raise "Zip file must contain files with names ending in 'ArchBoxExport.xlsx' and 'ArchFileExport.xlsx'"
    end


    # boxes
    rows = box_sheet.enum_for(:each)
    headers = row_values(rows.next)
    # box headers: ["Orig_SERN", "BOXN", "Box Location", "BOXNAME", "BEGINDATE", "ENDDDATE"]

    begin
      parent_aos = {}

      while(row = rows.next)
        values = row_values(row)

        next if values.compact.empty?

        values_map = Hash[headers.zip(values)]

        # find parent AO using Orig_SERN = external_id with source of RMS
        unless parent_aos[values_map["Orig_SERN"]]
          ext_id = ExternalId.select(:archival_object_id).
            where(:external_id => values_map["Orig_SERN"],
                  :source => AppConfig[:container_management_rms_source]).first
          if ext_id.nil?
            if permit_partial
              p "No series Archival Object with #{values_map["Orig_SERN"]} for Box #{values_map["BOXN"]}, skipping ..."
              next
            else
              raise "No series archival_object found with external_id of #{values_map["Orig_SERN"]} for Box #{values_map["BOXN"]}"
            end
          end
          # remember the archival_object for this Orig_SERN
          parent_aos[values_map["Orig_SERN"]] = ArchivalObject[ext_id[:archival_object_id]]
        end

        parent = parent_aos[values_map["Orig_SERN"]]

        external_id = {
          :source => AppConfig[:container_management_rms_source],
          :external_id => values_map["BOXN"],
        }

        date = {
          :date_type => "inclusive",
          :label => "creation",
          :begin => values_map["BEGINDATE"][0,10],
          :end => values_map["ENDDDATE"][0,10],
        }

        loc = Location.select(:id).where(:coordinate_1_indicator => values_map["Box Location"]).first
        loc_uri = if loc.nil?
                    loc = JSONModel::JSONModel(:location).
                      from_hash({
                                  :uri => "/locations/import_#{SecureRandom.hex}",
                                  :building => "RecordsCenter",
                                  :area => "RecordsManagement",
                                  :coordinate_1_label => "Shelf",
                                  :coordinate_1_indicator => values_map["Box Location"],
                                })
                    @batch << loc
                    loc.uri
                  else
                    JSONModel::JSONModel(:location).uri_for(loc[:id])
                  end

        instance = {
          :instance_type => "mixed_materials",
          :container => {
            :type_1 => "box",
            :indicator_1 => values_map["BOXN"],
            :container_locations => [{
              :ref => loc_uri,
              :status => "current",
              :start_date => today,
            }],
          }
        }

        # remember the uri for this box and its resource so we can ref them when creating file records
        uri = "/repositories/12345/archival_objects/import_#{SecureRandom.hex}"
        box_uris[values_map["BOXN"]] = uri
        resource_uris[values_map["BOXN"]] = JSONModel::JSONModel(:resource).uri_for(parent.root_record_id, :repo_id => parent.repo_id)

        ao_json = JSONModel::JSONModel(:archival_object).
          from_hash({
                      :uri => uri,
                      :title => values_map["BOXNAME"],
                      :level => "otherlevel",
                      :other_level => "box",
                      :external_ids => [external_id],
                      :dates => [date],
                      :instances => [instance],
                      :parent => {:ref => JSONModel::JSONModel(:archival_object).uri_for(parent.id, :repo_id => parent.repo_id)},
                      :resource => {:ref => resource_uris[values_map["BOXN"]]},
                      :rms_import_batch => today,
                    })

        @batch << ao_json
        
      end
    rescue StopIteration
    end


    # files
    rows = file_sheet.enum_for(:each)
    headers = row_values(rows.next)
    # file headers: ["BOXN", "FILN", "FILNAME"]

    begin
      while(row = rows.next)
        values = row_values(row)

        next if values.compact.empty?

        values_map = Hash[headers.zip(values)]

        unless box_uris[values_map["BOXN"]]
          if permit_partial
            p "No Box Archival Object with #{values_map["BOXN"]} for File #{values_map["FILN"]}, skipping ..."
            next
          else
            raise "No box archival_object found with external_id of #{values_map["BOXN"]} found for file #{values_map["FILN"]}"
          end
        end

        external_id = {
          :source => AppConfig[:container_management_rms_source],
          :external_id => values_map["FILN"],
        }

        @batch << JSONModel::JSONModel(:archival_object).
          from_hash({
                      :uri => "/repositories/12345/archival_objects/import_#{SecureRandom.hex}",
                      :title => values_map["FILNAME"],
                      :level => "file",
                      :external_ids => [external_id],
                      :parent => {:ref => box_uris[values_map["BOXN"]]},
                      :resource => {:ref => resource_uris[values_map["BOXN"]]},
                      :rms_import_batch => today,
                    })
      end
    rescue StopIteration
    end

  end


  def get_output_path
    output_path = @batch.get_output_path

    p "=================="
    p output_path
    p File.read(output_path)
    p "=================="

    output_path
  end

  private

  def row_values(row)
    (0...row.size).map {|i| (row[i] && row[i].value) ? row[i].value.to_s.strip : nil}
  end

end

