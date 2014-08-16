require 'sequel'

Sequel.sqlite 'db.sqlite'
Sequel::Model.plugin :json_serializer
Sequel::Model.plugin :validation_helpers

#Sequel::Model.raise_on_save_failure = false

class User < Sequel::Model
  one_to_many :circles
  one_to_many :auths
  
  def validate
    super

    validates_presence [:pseudo, :email, :token]

    validates_unique :pseudo
    validates_unique :token
    validates_unique :email

    unless new?
      validates_presence [:pubkey, :data]
    end
  end
end

class Circle < Sequel::Model
  many_to_one :user
  one_to_many :auths

  def validate
    super
    validates_unique [:user_id, :name]
    validates_presence :data
  end
end

class Auth < Sequel::Model
  many_to_one :circle
  many_to_one :user

  def validate
    super
    validates_unique [:circle_id, :user_id]
  end
end
