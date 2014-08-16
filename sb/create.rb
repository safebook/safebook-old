require 'sqlite3'
require 'sequel'

DB = Sequel.sqlite('db')

DB.create_table :users do
  primary_key :id
  String      :pseudo
  String      :pubkey
  String      :token
  String      :data
  unique :pseudo
end

DB.create_table :keys do
  primary_key :id
  String      :tag
  Fixnum      :user_id
  Fixnum      :dest_id
  String      :data
end

DB.create_table :msgs do
  primary_key :id
  String      :key_tag
  Fixnum      :user_id
  String      :data
end
