Sequel.migration do
  up do
    add_column :tweets, :reply_user_id, Bignum
  end

  down do
    drop_column :tweets, :reply_user_id
  end
end