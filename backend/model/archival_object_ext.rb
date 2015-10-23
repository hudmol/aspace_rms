class ArchivalObject < Sequel::Model(:archival_object)

  def update_from_json(json, opts = {}, apply_nested_records = true)
    # make sure we don't blat rms_import_stamp
    # if the update is coming from the frontend
    # currently not sending it in a hidden to avoid overriding the template
    # also also I probably need to worry about obscuring other update_from_json's
    # sheesh - ready to be led on this one!
    json["rms_import_stamp"] ||= self[:rms_import_stamp]
    super
  end

end
