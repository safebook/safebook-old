require 'rubygems'
require 'sinatra/base'
require 'haml'
require 'json'

require_relative 'models.rb'

class App < Sinatra::Base

  #Rack::Session::Cookie.new(App, {
  #  :coder => Rack::Session::Cookie::Identity.new
  #})
  
  #set :bind, '0.0.0.0'
  enable :sessions
  set :session_secret, 'screK@HFiLdsl;"QNK:FB'
  set :views, "./server/obselete_views"

  get '/' do
    redirect '/signin'
  end

  get '/signin' do
    haml :signin, :format => :html5
  end

  get '/signup' do
    haml :signup, :format => :html5
  end

  before do
    params.merge! JSON.parse(request.body.read) if request.request_method == "POST"
    # try
  end

  post '/signin' do
    content_type :json

    if user = User.first({ :pseudo => params[:pseudo], :token => params[:token] })
      session[:token] = params[:token]
      user = user.values
      user[:keys] = []
      contacts_id = []
      user[:msgs] = []
      key_tags = []
      Key.where(:dest_id => user[:id]).or(:user_id => user[:id]).each do |key|
        user[:keys].push(key.values)
        contacts_id.push key.user_id
        contacts_id.push key.dest_id
        key_tags.push key.tag
      end
      contacts_id.uniq!
      user[:contacts] = []
      User.where({ :id => contacts_id }).each do |contact|
        contact = { :id => contact.id, :pseudo => contact.pseudo, :pubkey => contact.pubkey }
        user[:contacts].push(contact)
      end
      Msg.where({ :key_tag => key_tags }).each do |msg|
        user[:msgs].push(msg.values)
      end
      halt 200, user.to_json
    else
      halt 401, {}
    end
  end

  post '/users' do
    content_type :json
    user = User.new(params)
    if user.valid?
      halt 200, user.save.values.to_json
    else
      halt 401, user.errors.to_json
    end
  end

  get '/users/:pseudo' do
    content_type :json
    user = User.first :pseudo => params[:pseudo]
    if user
      { :id => user.id, :pseudo => user.pseudo, :pubkey => user.pubkey }.to_json
    else
      halt 404, {}
    end
  end

  post '/keys' do
    content_type :json
    user = User.first :token => session[:token]
    halt 401 unless user and params[:user_id] == user.id

    key = Key.new(params)
    if key.valid?
      halt 200, key.save.values.to_json
    else
      halt 402
    end
  end

  post '/msgs' do
    content_type :json
    user = User.first :token => session[:token]
    halt 401 unless user and params[:user_id] == user.id

    msg = Msg.new(params)
    if msg.valid?
      halt 200, msg.save.values.to_json
    else
      halt 402
    end
  end

  get '/reset' do
    User.dataset.delete
    Key.dataset.delete
    Msg.dataset.delete
    "no users"
  end

end
