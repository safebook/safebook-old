require 'sinatra'

require_relative 'models'

before do
  headers "Access-Control-Allow-Origin" => "*"
end

options '*' do
  headers "Access-Control-Allow-Headers" => "content-type"
  headers "Access-Control-Allow-Methods" => "PUT, PATCH"
end

get '/users/:pseudo' do

  if params[:token]
    user = User.where(:pseudo => params[:pseudo], :token => params[:token]).first
    if user then user.to_json else 401 end
  else
    user = User.select(:pseudo, :pubkey).where(:pseudo => params[:pseudo]).first
    if user then user.to_json else 404 end
  end
end

put '/users/:pseudo' do
  
  content_type :json

  # begin rescue
  model = JSON.parse params[:model]
  model[:pseudo] = params[:pseudo]

  user = User.new model

  if user.valid?
    user.save.to_json
  else
    halt 401, user.errors.to_json
  end
end

patch '/users/:pseudo' do

  user = User.where(:pseudo => params[:pseudo], :token => params[:token]).first

  model = JSON.parse params[:model]

  user.pubkey = model["pubkey"]
  user.data = model["data"]

  content_type :json
  if user.valid?
    user.save.to_json
  else
    halt 401, "{ \"errors\": #{user.errors.to_json} }"
  end
end

get '/circles' do
  user = User.where(:token => params[:token]).first
  if user then user.circles.to_json else 401 end
end

post '/circles' do
  user = User.where(:token => params[:token]).first
  user.add_circle params[:circle]
end

put '/circles/:id' do
  circle = Circle.find(params[:id])
  #halt 401 if params[:token] != circle.user.token
  
  circle.name = params[:name]
  if circle.valid?
    circle.save.to_json
  else
    404
  end
end

delete '/circles/:id' do
  circle = Circle.where(:id => params[:id]).first
  #halt 401 unless circle.auth(params[:token])

  401 unless circle.destroy
end


get '/auths' do
  user = User.where(:token => params[:token]).first
  user.auths.to_json
  # user.circles.auths.to_json
  # mine and others
end

post '/auths' do
  user = User.where(:token => params[:token]).first
  target = User.where(:pseudo => params[:target]).first

  circle = Circle.where(:user_id => user.id, :name => params[:circle]).first

  Auth.create :data => params[:data], :circle_id => circle.id, :user_id => target.id
end

delete '/auths' do

end
