require 'sqlite3'
require 'sequel'

DB = Sequel.sqlite('db')

class User < Sequel::Model
  plugin :validation_helpers

  def validate
    super
    validates_presence [:pseudo, :pubkey, :token, :data]
    validates_unique :pseudo, :pubkey, :token, :data
  end
end

class Key < Sequel::Model
  plugin :validation_helpers

  def validate
    super
    validates_presence [:tag, :user_id, :dest_id, :data]
    validates_unique :tag # temporary : no Circles. I also want [:user_id, :dest_id]
    #validates_unique [[:tag, :user_id], [:tag, :user_id ,:dest_id]]
  end
end

class Msg < Sequel::Model
  plugin :validation_helpers

  def validate
    super
    validates_presence [:key_tag, :user_id, :data]
  end
end
