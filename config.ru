require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'sinatra/base'
require 'eventmachine'
require 'em-http'
require 'em-mongo'
require 'json'
require 'mongo'
require './app'

run Sinatra::Application