require 'sprockets'
require 'uglifier'

require './app.rb'

map '/js' do
  assets = Sprockets::Environment.new
  assets.append_path 'assets/vendor'
  assets.append_path 'coffee'
  #assets.js_compressor = Uglifier.new
  run assets
end

map '/' do
  run App
end
