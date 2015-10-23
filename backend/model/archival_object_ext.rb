class ArchivalObject < Sequel::Model(:archival_object)

  def update_from_json(json, opts = {}, apply_nested_records = true)
    # make sure we don't blat rms_import_date
    # if the update is coming from the frontend
    # currently not sending it in a hidden to avoid overriding the template
    # also it's blowing up in prepare_for_db (why?) if there is no value,
    #   hence the dummy value
    # also also I probably need to worry about obscuring other update_from_json's
    # sheesh - ready to be led on this one!
    unless json["rms_import_date"]
      json["rms_import_date"] = self[:rms_import_date].to_s
      json["rms_import_date"] = "1900-01-01" if json["rms_import_date"] == ""
    end
    super
  end

end
