require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:external_id) do
      add_index([:external_id, :source])
    end
  end

  down do
  end

end
