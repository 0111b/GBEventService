#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'

require 'sinatra/base'
require 'erb'
require 'json'
require 'date'

class EventService < Sinatra::Base  
  configure do
    set :environment, :production
    set :bind, '0.0.0.0'
    # set :port, 4567
    set :server, "thin"
    set :lock, true
  end
  
  historyName = "history.json"

  get '/' do    
    @messages = fetchMessages historyName     
    erb @messages.length > 0 ? :index : :empty
  end

  post '/' do  
    content_type :json
    begin
      json = JSON.parse request.body.read
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
      
    
    response =  {
      "status" => 0,
      "message" => "ok"
    }
    JSON.pretty_generate response
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