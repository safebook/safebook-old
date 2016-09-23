require 'sprockets'
require 'uglifier'

require './server/app'

map '/js' do
  assets = Sprockets::Environment.new
  assets.append_path 'assets/js'
  assets.append_path 'assets/coffee'
  #assets.js_compressor = Uglifier.new
  run assets
end

map '/' do
  run App
end
