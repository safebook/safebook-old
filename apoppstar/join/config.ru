require 'sinatra/base'

class App < Sinatra::Base
  set :public_dir, '.'

  get '/' do
    redirect "index.html"
  end
end

run App
