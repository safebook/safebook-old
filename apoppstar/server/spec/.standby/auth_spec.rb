require 'rspec'
require 'rack/test'

require './spec/commons.rb'
require './router.rb'

describe 'auths' do
  include Rack::Test::Methods
  include Commons

  before :all do
    Auth.dataset.destroy
    Circle.dataset.destroy
    User.dataset.destroy

    u = User.create(user1)
    u.add_circle(circle)
    u.add_circle(circle2)
    User.create user2_1.merge(user2_2)
  end

  it "can be posted" do
    post "/auths?secret=#{user1["secret"]}", \
      :target => user1["pseudo"],
      :circle => circle["name"],
      :data => auth["data"]

    last_response.should be_ok
  end

  it "is accessible" do
    get "/auths?secret=#{user1["secret"]}"
    auths = JSON.parse(last_response.body)
    auths.first["data"].should == auth["data"]
  end

  it "can be posted (on circle2)" do
    post "/auths?secret=#{user1["secret"]}",
      :target => user1["pseudo"],
      :data => auth["data"],
      :circle => circle2["name"]
    last_response.should be_ok
  end

  it "is accessible" do
    get "/auths?secret=#{user1["secret"]}"
    auths = JSON.parse(last_response.body)
    auths.length.should == 2
  end

  it "is not accessible by someone else" do
    get "/auths?secret=#{user2_1["secret"]}"
    auths = JSON.parse(last_response.body)
    auths.length.should == 0
  end

  it "can be posted to someone else" do
    post "/auths?secret=#{user1["secret"]}",
      :target => user2_1["pseudo"],
      :data => auth["data"],
      :circle => circle2["name"]
    last_response.should be_ok
  end

  it "is accessible" do
    get "/auths?secret=#{user2_1["secret"]}"
    auths = JSON.parse(last_response.body)
    auths.length.should == 1
    auths.first["data"].should == auth["data"]
  end
end
