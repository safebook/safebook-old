require 'rspec'
require 'rack/test'

require './spec/commons.rb'
require './router.rb'

describe 'circles' do
  include Rack::Test::Methods
  include Commons

  before :all do
    Auth.dataset.destroy
    Circle.dataset.destroy
    User.dataset.destroy

    User.create user1
    User.create user2_1.merge(user2_2)
  end

  it "can store one" do
    post '/circles', :secret => user1["secret"], :circle => circle
    last_response.should be_ok
  end

  it "is accessible" do
    get "/circles?secret=#{user1["secret"]}"
    res = JSON.parse(last_response.body)

    res.length.should be 1
    res.first["name"].should == circle["name"]
    res.first["data"].should == circle["data"]
  end

  it "is not accessible without secret" do
    get "/circles?secret=anything"
    last_response.body.should eq ""
    last_response.status.should eq 401
  end

  it "can store another" do
    post '/circles', :secret => user1["secret"], :circle => circle2
    last_response.should be_ok
  end

  it "is still accessible" do
    get "/circles?secret=#{user1["secret"]}"
    res = JSON.parse(last_response.body)

    res.length.should be 2
    res.find { |c| c["name"] == circle["name"] }["data"].should eq circle["data"]
    res.find { |c| c["name"] == circle2["name"] }["data"].should eq circle2["data"]
  end

  it "can change the name" do
    get "/circles?secret=#{user1["secret"]}"
    res = JSON.parse(last_response.body)
    id = res.find { |c| c["name"] == "name" }["id"]

    put "/circles/#{id}?secret=#{user1["secret"]}", :name => "nnnn"
    last_response.should be_ok

    get "/circles?secret=#{user1["secret"]}"
    res = JSON.parse(last_response.body)
    res.find { |c| c["name"] == "nnnn" }.should be_true
    res.find { |c| c["name"] == "name" }.should be_nil
  end

  it "can be deleted" do
    get "/circles?secret=#{user1["secret"]}"
    res = JSON.parse(last_response.body)
    res.length.should be 2

    id = res.find { |c| c["name"] == "name2" }["id"]
    delete "/circles/#{id}?secret=#{user1["secret"]}"
    last_response.should be_ok

    get "/circles?secret=#{user1["secret"]}"
    res = JSON.parse(last_response.body)

    res.length.should be 1
    res.first["name"].should eq "nnnn"
  end

end
