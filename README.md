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

### RMS Import Stamp

Resource Component (Archival Object) records have a new field
'RMS Import Stamp' (rms_import_stamp). A value in this field is used
to identify a batch of imported records. The importer sets the value to
today's date (YYYY-MM-DD). This value is indexed.
