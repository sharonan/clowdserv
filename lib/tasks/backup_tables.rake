task :backup_tables => :environment do
  ddb = AWS::DynamoDB.new()
  timestamp = DateTime.now.strftime("%Y%m%d.%H%M")
  
  ddb.tables.each do |table|
    table.load_schema
  	if table.name.include?("dev_verifications") 
  		puts "Backing up #{table.name}"
      filename = "#{table.name}_backup_#{timestamp}"
      File.open(filename, "a")
  		table.items.each_batch(table_name: table.name) do |batch|
        batch.each do |item|
          record = item.attributes.to_h(:consistent_read => true)
          File.write(filename, record.to_json, File.size(filename), mode: 'a')   
          File.write(filename, ", \n", File.size(filename), mode: 'a')     
        end
  		end
  	end
  end
end


task :restore_backup => :environment do
  # THis is just a proof of concept.  Not yet made general, e.g. passing in filename.
  filename = "dev_verifications_backup_20131212.2159"
  tablename = "dev_test_restore_backup"
  ddb = AWS::DynamoDB.new()
  table = ddb.tables[tablename]
  table.load_schema
  
  File.open(filename, "r") do |file|
    file.each do |line|
      line = line[0..(line.rindex(',')-1)]
      record = JSON.parse line
      table.items.put(record)
    end
  end
end