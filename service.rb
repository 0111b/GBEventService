#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'

require 'sinatra/base'
require 'erb'
require 'json'
require 'date'

require 'rest-client'
GB = RestClient::Resource.new "https://app-qa.gwynniebee.com:4443"

class EventService < Sinatra::Base  
  configure do
    set :environment, :production
    set :bind, '0.0.0.0'
    # set :port, 4567
    set :server, "thin"
    set :lock, true
  end
  
  historyName = "history.json"

  post '/createOrUpdateDevice' do
    content_type :json
    response =  {
      "status" => {
        "code" => 0,
        "message" => "ok",
      },
      "fcmDeviceData" => {
        "userUuid" => "testUserUuid",
      },
    }
    JSON.pretty_generate response
  end
  
  delete "/deleteDevice" do
    content_type :json
    response =  {
      "status" => {
        "code" => 0,
        "message" => "ok",
      },
      "fcmDeviceData" => {
        "userUuid" => "testUserUuid",
      },
    }
    JSON.pretty_generate response    
  end

  get '/' do    
    @messages = fetchMessages historyName     
    erb @messages.length > 0 ? :index : :empty
  end

  post '/' do  
    content_type :json
    data = request.body.read
    begin
      json = JSON.parse data
    rescue Exception => e
      logError e.message
      response =  {
        "status" => 1,
        "message" => "#{e.message}"        
      }
      return JSON.pretty_generate response      
    end
    m = fetchMessages historyName
    m.push json
    f = File.open(historyName,"w")
    f.write(JSON.generate(m))
    f.close
      
    request_method = 'POST'.downcase.to_sym
    request_headers = {
          :accept => "application/json", 
          :content_type => "application/json",
      }
    proxy_response = GB['/v1/postEvent.json'].send(request_method, data, request_headers)
    proxy_response    
  end
  
  def logError(message)
    f = File.open("error.log", "a")
    current_time = DateTime.now.strftime "%d/%m/%Y %H:%M"    
    f.write("#{current_time}::#{message}\n")
    f.close
  end
  
  def fetchMessages(fname)    
    maxMessages = 100    
    begin
      f = File.open(fname, "r+")
      m = JSON.parse f.read
      f.truncate(0) if m.count > maxMessages
      f.close
      return m.kind_of?(Array) ? m : Array.new(m)
    rescue
      return Array.new
    end
  end
  
  # def self.run!
  #   super do |server|
  #     server.ssl = true
  #     server.ssl_options = {
  #       :cert_chain_file  => File.dirname(__FILE__) + "/ssl/server.crt",
  #       :private_key_file => File.dirname(__FILE__) + "/ssl/server.key",
  #       :verify_peer      => false
  #     }
  #   end
  # end

    run! if app_file == $0
  
end

# EventService.run!