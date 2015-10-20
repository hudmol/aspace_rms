require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:archival_object) do
      add_column(:rms_import_date, Date, :null => true)
    end
  end

  down do
  end

end
