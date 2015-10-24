# ArchivesSpace Records Management Plugin

An ArchivesSpace plugin that adds integration with Dartmouth's Records Management System

## How to install it

To install, just activate the plugin in your config/config.rb file by
including an entry such as:

     # If you have other plugins loaded, just add 'box_search' to
     # the list
     AppConfig[:plugins] = ['local', 'other_plugins', 'aspace_rms']

And then clone the `box_search` repository into your
ArchivesSpace plugins directory.  For example:

     cd /path/to/your/archivesspace/plugins
     git clone https://github.com/hudmol/aspace_rms.git aspace_rms

Or if you are after a particular release, download and unzip it from here:

https://github.com/hudmol/aspace_rms/releases

When installing or upgrading this plugin it will be neceesary to run a database migration
like this:

      cd /path/to/archivesspace
      scripts/setup-database.sh


## How to use it

### Import from Records Management

To import from Records Management, create a new Background Job:

      Job Type:     Import Data
      Import Type:  Records Management Zipfile

The file provided should be a zip that contains at least two files those names end with:

      ArchBoxExport.xlsx
      ArchFileExport.xlsx

The Box file should have the following columns:

      "Orig_SERN", "BOXN", "Box Location", "BOXNAME", "BEGINDATE", "ENDDDATE"

The File file should have the following columns:

      "BOXN", "FILN", "FILNAME"


#### Box file

Rows from the Box file will be imported as archival_objects with the following values:

      title:             *BOXNAME*
      level:             otherlevel
      other_level:       box
      parent:            {ref: archival_object with external_id: {source: container_management_rms_source, external_id: *Orig_SERN*}}
      resource:          {ref: the same resource as the parent}
      external_ids:      [{source: container_management_rms_source, external_id: *BOXN*}]
      dates:             [{date_type: inclusive, label: creation, begin: *BEGINDATE*, end: *ENDDDATE*}]
      instances:         [{instance_type: mixed_materials,
                            container: {type_1: box, indicator_1: *BOXN*,
                              container_location: {status: current, start_date: today, ref: location with coordinate_1_indicator: *Box Location*}}}]
      rms_import_batch:  today as YYYY-MM-DD

Note:

The value matched in external_id.source is taken from config, for example:

      AppConfig[:container_management_rms_source] = "RMS"

If no archival_object is found with an external_id of *Orig_SERN*, then the row will be skipped. 

If no location is found with coordinate_1_indicator of *Box Location*, then a new location will be created:

      building:               RecordsCenter
      area:                   RecordsManagement
      coordinate_1_label:     Shelf
      coordinate_1_indicator: *Box Location*


#### File file

Rows from the File file will be imported as archival_objects value the following values:

      title:             *FILNAME*
      level:             file
      parent:            {ref: archival_object imported from the Box file with the same *BOXN*}}
      resource:          {ref: the same resource as the parent}
      external_ids:      [{source: container_management_rms_source, external_id: *FILN*}]
      rms_import_batch:  today as YYYY-MM-DD


### External IDs are editable

This plugin makes external_ids editable. This makes it possible to set external_ids in
series archival_object records that will match rows in the Box file.
Note that the source must equal the value set in AppConfig[:container_management_rms_source]

 
### archival_object.rms_import_batch

Resource Component (Archival Object) records have a new field
rms_import_batch. A value in this field is used
to identify a batch of imported records. The importer sets the value to
today's date (YYYY-MM-DD). This value is indexed, allowing a search like this:

      rms_import_batch_u_sstr:2015-10-24

To return all records imported on October 24, 2015.

