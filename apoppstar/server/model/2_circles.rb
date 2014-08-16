Sequel.migration do
  change do 
    create_table :circles do

      primary_key :id

      foreign_key :user_id, :users

      String :name
      String :data

      #index [:user_id, :name], :unique => true
    end
  end
end
