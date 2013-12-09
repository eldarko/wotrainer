require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'sinatra/base'
require 'sinatra/async'
require 'eventmachine'
require 'em-http'
require 'em-mongo'
require 'json'
require 'mongo'
require './app'

$stdout.sync = true

run Sinatra::Application
