class CommonIndexer

  add_indexer_initialize_hook do |indexer|

    indexer.add_document_prepare_hook {|doc, record|
      if record['record']['jsonmodel_type'] == 'archival_object'
        doc['rms_import_stamp_u_sstr'] = record['record']['rms_import_stamp']
      end
    }

  end

end
