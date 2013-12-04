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

def dbconn
	$dbconn ||= do_connect
end

def dbcats
	$dbcats ||= dbconn.collection('categories')
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

# Force Mongo connection
EM.schedule do
	dbconn
end

