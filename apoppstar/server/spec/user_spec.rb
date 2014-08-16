require 'rspec'
require 'rack/test'

require './spec/commons.rb'
require './router.rb'

describe 'users' do
  include Rack::Test::Methods
  include Commons

  before :all do 
    Auth.dataset.destroy
    Circle.dataset.destroy
    User.dataset.destroy
  end

  it "can be saved" do
    put public_url(user1), model: user1.to_json
    last_response.should be_ok
  end

  it "fails if pseudo, email or secret are not unique, and fill errors" do
    put public_url(user1), model: user1.to_json
    last_response.status.should eq 401

    res = JSON.parse last_response.body
    res["errors"].has_key?("pseudo").should be_true
    res["errors"].has_key?("email").should be_true
    res["errors"].has_key?("token").should be_true
  end

  it "can be saved in two steps" do
    put public_url(user2), model: part_1(user2).to_json
    last_response.should be_ok

    patch private_url(user2), model: part_2(user2).to_json
    last_response.should be_ok
  end

  it "is accessible (without secret)" do
    get public_url(user1)
    last_response.should be_ok
    res = JSON.parse(last_response.body)
    res["pseudo"].should eq user1["pseudo"]
    res["pubkey"].should eq user1["pubkey"]

    get public_url(user2)
    last_response.should be_ok
    res = JSON.parse(last_response.body)
    res["pseudo"].should eq user2["pseudo"] 
    res["pubkey"].should eq user2["pubkey"]
  end

  it "is protected (without token)" do
    get public_url(user1)
    last_response.should be_ok
    res = JSON.parse(last_response.body)

    res.has_key?("secret").should be_false
    res.has_key?("data").should be_false
  end

  it "gives data back (with token)" do
    get private_url(user1)
    last_response.should be_ok
    res = JSON.parse last_response.body
    res["data"].should eq user1["data"]

    get private_url(user2)
    last_response.should be_ok
    res = JSON.parse last_response.body
    res["data"].should eq user2["data"]
  end

  it "fails without the good secret" do
    get  "/users/" + user1["pseudo"] + "?token=anything"
    last_response.status.should eq 401
    last_response.body.should eq ""

    get  "/users/" + user1["pseudo"] + "?token=" + user2["token"]
    last_response.status.should eq 401
    last_response.body.should eq ""
  end

end
