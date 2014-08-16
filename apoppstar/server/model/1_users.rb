Sequel.migration do
  change do 
    create_table :users do

      primary_key :id

      String :pseudo
      String :token
      String :email

      String :pubkey
      String :data

      index :pseudo, :unique => true
      index :token, :unique => true

    end
  end
end
