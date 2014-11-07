Sequel.migration do
  up do
    create_table(:tweets) do
      primary_key :id
      Bignum :tweet_id
      String :text
      Integer :minute
    end
  end

  down do
    drop_table(:tweets)
  end
end