task :delete_unwanted_tables do
  ddb = AWS::DynamoDB.new(:secret_access_key => ENV['AWS_SECRET_KEY'], 
    :access_key_id => ENV['AWS_ACCESS_KEY_ID'], :dynamo_db_endpoint => "dynamodb.us-west-2.amazonaws.com")
  
  ddb.tables.each do |table|
  	if table.name.include?("123456") 
  		puts "\ndeleting #{table.name}"
  		table.delete
  		begin
  		  sleep 1
  			while table.status == :deleting
  				sleep 1
  				print "."
  			end
  		rescue AWS::DynamoDB::Errors::ResourceNotFoundException
  		end
  	end
  end
end