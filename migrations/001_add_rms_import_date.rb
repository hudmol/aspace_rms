require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:archival_object) do
      add_column(:rms_import_batch, String, :null => true)
    end
  end

  down do
  end

end
