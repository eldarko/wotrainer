set :protection, :except => [:http_origin]
use Rack::Protection::HttpOrigin, :origin_whitelist => ['http://127.0.0.1','http://eldarko.github.io']

register Sinatra::Async

def do_connect
	if ENV['MONGOHQ_URL']
		uri    = URI.parse(ENV['MONGOHQ_URL'])
		dbname = uri.path.gsub(/^\//, '')

		dbconn = EM::Mongo::Connection.new(uri.host, uri.port).db(dbname)
		resp = dbconn.authenticate(uri.user, uri.password) unless (uri.user.nil? || uri.password.nil?)
		resp.callback do |res|
			puts "auth result: #{res}"
		end.errback do |err|
			puts "auth error: #{err}"
		end

		puts "u=#{uri.user} p=#{uri.password}"
	else
		dbconn = EM::Mongo::Connection.new('localhost').db('wotrainer')
		puts "local connection #{dbconn}"
	end
	dbconn
end

$dbconn = nil
$dbcats = nil
$dbsets = nil

def dbconn
	$dbconn ||= do_connect
end

def dbcats
	$dbcats ||= dbconn.collection('categories')
end

def dbsets
	$dbsets ||= dbconn.collection('sets')
end

post '/categories' do
	stream :keep_open do |out|
	end
end

get '/categories' do
	stream :keep_open do |out|
		resp = dbcats.find.to_a
		resp.callback do |docs|
			out << docs.length
			out.close
		end
		resp.errback do |err|
			out << "e=#{err}"
			out.close
		end
	end
end

def cross_origin
	return unless request.env['HTTP_ORIGIN']

	headers 'Access-Control-Allow-Origin'  => request.env['HTTP_ORIGIN'],
		'Access-Control-Allow-Methods'     => 'GET, POST, OPTIONS',
		'Access-Control-Allow-Credentials' => 'true',
		'Access-Control-Max-Age'           => :development ? '10' : '259200'

	if x = request.env['HTTP_Access_Control_Request_Headers'.upcase]
		headers 'Access-Control-Allow-Headers' => x
	end
	nil
end

aget '/api/v1/set/:id' do
	puts "ID: #{params['id']}"
	cross_origin
	resp = dbsets.find_one :_id => params['id']
	resp.callback do |doc|
		puts "Returned doc: #{doc}"
		if doc
			body doc.to_json
		else
			status 404
			body ''
		end
	end
	resp.errback do |err|
		status = 500
		body err
	end
end

get '/api/v1/sets' do
	cross_origin
	stream :keep_open do |out|
		resp = dbsets.find.defer_as_a
		resp.callback do |docs|
			out << docs.map{ |doc| {:id => doc['_id'].to_s, :name => doc['name']} }.to_json
			out.close
		end
		resp.errback do |err|
			response.status = 500
			out << err
			out.close
		end
	end
end

post '/api/v1/sets' do
	cross_origin
	stream :keep_open do |out|
		doc = JSON.parse request.body.read

		if doc['id']
			resp = dbsets.safe_update({:_id => doc['id']}, doc)
		else
			resp = dbsets.safe_insert(doc)
		end
		resp.callback do |id|
			id = doc['id'] if id === true # update returns true
			out << {:id => id.to_s}.to_json
			out.close
		end
		resp.errback do |err|
			response.status = 500
			out << err
			out.close
		end
	end
end

options '/api/v1/sets' do
	cross_origin
end

# Force Mongo connection
EM.schedule do
	dbconn	
end

