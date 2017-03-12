require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/json'
require 'pry'
require 'faye/websocket'
require 'thin'
require 'active_record'

require_relative 'models/status.rb'

Faye::WebSocket.load_adapter('thin')

configure do
  set :sockets, {instructor: []}
  ActiveRecord::Base.establish_connection(
    adapter: "sqlite3",
    database: "database.db"
  )
end

after {ActiveRecord::Base.clear_active_connections!}

get "/instructor" do
  @average = Status.average_value
  erb :instructor
end

get "/" do
  @value = Status.where(ip: request.ip).order("created_at DESC").first
  erb :student
end

post "/status" do
  params[:ip] = request.ip
  if !Status.create(params)
    response.status = 400
  else
    settings.sockets[:instructor].each do |socket|
      socket.send(Status.average_value)
    end
  end
  json({}, encoder: :to_json, content_type: :json)
end

get "/socket" do
  if Faye::WebSocket.websocket?(request.env)
    ws = Faye::WebSocket.new(request.env)
    settings.sockets[:instructor] << ws

    ws.on :close do |event|
      settings.sockets[:instructor].reject! {|sock| sock.object_id == ws.object_id}
    end

    ws.rack_response
  end
end
