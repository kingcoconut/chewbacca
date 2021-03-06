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

  if ENV["RACK_ENV"] == "production"
    ActiveRecord::Base.establish_connection(
      adapter: "mysql2",
      database: "production",
      hostname: "chewbacca-prod.cxas9fabzgkq.ap-southeast-2.rds.amazonaws.com",
      username: "root",
      password: ENV["MYSQL_PASSWORD"]
    )
  else
    ActiveRecord::Base.establish_connection(
      adapter: "sqlite3",
      database: "database.db"
    )
  end
end

after {ActiveRecord::Base.clear_active_connections!}

get "/" do
  @status = Status.where(ip: request.ip).order("created_at DESC").first
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

get "/instructor" do
  @average = Status.average_value
  erb :instructor
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
