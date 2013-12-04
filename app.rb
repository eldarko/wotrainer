configure do
	if ENV['MONGOHQ_URL']
		uri    = URI.parse(ENV['MONGOHQ_URL'])
		dbname = uri.path.gsub(/^\//, '')

		dbconn = EM::Mongo::Connection.new(uri.host, uri.port).db(dbname)
		dbconn.authenticate(uri.user, uri.password) unless (uri.user.nil? || uri.password.nil?)
	else
		dbconn = EM::Mongo::Connection.new('localhost').db('wotrainer')
	end

	dbcats = dbconn.collection('categories')
end

# configure do
#  if ENV['MONGOHQ_URL']
#    uri = URI.parse(ENV['MONGOHQ_URL'])
#    conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
#    DB = conn.db(uri.path.gsub(/^\//, ''))
#  else
#    DB = Mongo::Connection.new.db("mongo-twitter-streaming")
 # end
  
#  DB.create_collection("tweets", :capped => true, :size => 10485760)
#end

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

