class RmsImportBatchReport < AbstractReport


  register_report({
                    :uri_suffix => "rms_import_batch",
                    :description => "Report on a batch of boxes imported from Records Management",
                    :params => [["batch", Date, "Batch", {optional: false}]],
                  })


  def initialize(params)
    super
    @batch = params[:batch]
  end


  def title
    "Records Management Import Batch"
  end


  def headers
    ['BOXN', 'Description']
  end


  def processor
    {
      'BOXN' => proc {|record| record[:boxn]},
      'Description' => proc { |record|
        "#{ASUtils.json_parse(record[:resource_identifier] || '[]').compact.join('-')}; Box Number: #{record[:top_container_indicator]}; #{record[:title]}"
      },
    }
  end


  def scope_by_repo_id(dataset)
    # repo scope is applied in the query below
    dataset
  end


  def query(db)
    dataset = db[:archival_object].
      join(:external_id, :archival_object_id =>  Sequel.qualify(:archival_object, :id)).
      join(:instance, :archival_object_id => Sequel.qualify(:archival_object, :id)).
      join(:sub_container, :instance_id => Sequel.qualify(:instance, :id)).
      join(:top_container_link_rlshp, :sub_container_id => Sequel.qualify(:sub_container, :id)).
      join(:top_container, :id => Sequel.qualify(:top_container_link_rlshp, :top_container_id)).
      join(:resource, :id => Sequel.qualify(:archival_object, :root_record_id)).
      select(
        Sequel.qualify(:external_id, :external_id).as(:boxn),
        Sequel.qualify(:resource, :identifier).as(:resource_identifier),
        Sequel.qualify(:top_container, :indicator).as(:top_container_indicator),
        Sequel.qualify(:archival_object, :title),
      )

    dataset = dataset.where(Sequel.qualify(:archival_object, :repo_id) => @repo_id) if @repo_id
    dataset = dataset.where(Sequel.qualify(:archival_object, :rms_import_batch) => @batch)
    dataset = dataset.where(Sequel.qualify(:archival_object, :other_level) => 'box')
  end
end
