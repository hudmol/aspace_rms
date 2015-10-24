module PreserveRmsImportBatch

  def update_from_json(json, opts = {}, apply_nested_records = true)
    # make sure we don't blat rms_import_batch
    # if the update is coming from the frontend
    # currently not sending it in a hidden to avoid overriding the template
    json["rms_import_batch"] ||= self[:rms_import_batch]
    super
  end

end
