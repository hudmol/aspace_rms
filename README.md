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

### RMS Import Date

Resource Component (Archival Object) records have a new field
'RMS Import Date' (rms_import_date). A date in this field indicates
the day that the record was imported from Records Management.
