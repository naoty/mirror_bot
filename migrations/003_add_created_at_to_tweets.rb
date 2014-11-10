Sequel.migration do
  up do
    add_column :tweets, :created_at, "timestamp with time zone"
  end

  down do
    drop_column :tweets, :created_at
  end
end