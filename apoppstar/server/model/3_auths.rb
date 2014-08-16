Sequel.migration do
  change do 
    create_table :auths do

      primary_key :id

      foreign_key :user_id, :users
      foreign_key :circle_id, :circles

      String :data

      #index [:circle_id, :user_id], :unique => true
    end
  end
end
