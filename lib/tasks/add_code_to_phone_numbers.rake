task :migrate_phone_numbers => :environment do  
  dynamo_db = AWS::DynamoDB.new(:region => 'us-west-2')

  tables = dynamo_db.tables
 
  prefix = "prod"
  @runtype = "print_only"
  ## Valid run types are "test_only", "print_only" and "real_run"
  
  
  if @runtype == "test_only"
    update_keyrange_table_field(tables["#{prefix}_test_migration"], "phone_number1")
    update_keyrange_table_field(tables["#{prefix}_test_migration"], "phone_number2")
    update_simple_table_field(tables["#{prefix}_test_migration"], "phone_number3")
    migrate_set(tables["#{prefix}_test_migration"], "phone_number_set")
  else
    # The users table and nonusers table were already migrated.  Verifications need not be migrated.
    # The nonusers table got moved to development enviornment so it's a special case.
    move_dev_nonusers_to_prod(tables["dev_non_users"], tables["prod_non_users"])
    
    # The rest of the tables just need to get migrated, phone_number field by field. 
    # Only difference is whether each field with a phone number is a set, a hash key or a range key.
    update_simple_table_field(tables["#{prefix}_event"], "phone_number")
    migrate_set(tables["#{prefix}_event"], "attendees")
  
    update_simple_table_field(tables["#{prefix}_event_plan"], "event_organizer_phone")
  
    event_plan_user_table = tables["#{prefix}_event_plan_user"]
    update_simple_table_field(event_plan_user_table, "organizer_phone")
    update_keyrange_table_field(event_plan_user_table, "phone_number")
    migrate_event_plan_user_id(event_plan_user_table)

    update_simple_table_field(tables["#{prefix}_message"], "phone_number")
    update_keyrange_table_field(tables["#{prefix}_users_device_tokens"], "phone_number")
    update_keyrange_table_field(tables["#{prefix}_users_events"], "id")
  end
end

# We can probably adapt these for re-use in future migrations, but that's not entirely clear yet.

def update_simple_table_field(table, field_name)
  table.load_schema  
  puts "Migrating #{table.name} #{field_name}"

  table.items.each do |item|
    record = update_one_field(item, field_name)
    puts "  Updating #{field_name} to #{record[field_name]}"
    table.items.put(record) if @runtype == "real_run" || @runtype == "test_only"
  end
end

def update_keyrange_table_field(table, field_name)
  table.load_schema
  puts "Migrating #{table.name} #{field_name}"

  table.items.each do |item|
    new_record = update_one_field(item, field_name)
    if new_record[field_name] != item.attributes.to_h(:consistent_read => true)[field_name]
      puts "  Creating #{table.name} record #{new_record[field_name]} and deleting #{item.attributes.to_h[field_name]}"
      if @runtype == "real_run"  || @runtype == "test_only"
        table.items.put(new_record) 
        item.delete
      end
    end
  end
end

def update_one_field(item, field_name)
  record = item.attributes.to_h(:consistent_read => true)
  if record.has_key?(field_name)
    unless record[field_name].start_with?('+')
      record[field_name] = "+1#{record[field_name]}" 
    end
  else
    puts "!! #{field_name} not found in record"
  end
  return record
end


def migrate_set(table, field_name)
  table.load_schema
  puts "Migrating #{table.name} #{field_name}"
  
  table.items.each do |item|
    record = item.attributes.to_h(:consistent_read => true)
  
    if record.has_key?(field_name) && !record[field_name].empty?
      new_set = Set.new
      record[field_name].each do |old_number|
        if old_number.start_with?('+')
          new_set.add(old_number)
        else
          new_set.add("+1#{old_number}")
        end
      end
      record[field_name] =  new_set
      puts "  New set for #{field_name} is #{record[field_name].inspect}"
      table.items.put(record) if @runtype == "real_run" || @runtype == "test_only"
    end
  end
end


def migrate_event_plan_user_id(table)
  table.load_schema
  puts "Migrating event_plan_user id"
  
  table.items.each do |item|    
    record = item.attributes.to_h(:consistent_read => true)
    record["id"] = "#{record["event_plan_id"]}-#{record["phone_number"]}"
    puts "  New event_plan_user id is #{record["id"]}"
    table.items.put(record) if @runtype == "real_run" || @runtype == "test_only"
  end
end

def move_dev_nonusers_to_prod(dev_table, prod_table)
  dev_table.load_schema
  prod_table.load_schema
  dev_table.items.each do |item|
    record = item.attributes.to_h(:consistent_read => true)
    puts "Saving nonuser #{record["phone_number"]} to production"
    prod_table.items.put(record) if @runtype == "real_run" || @runtype == "test_only"
  end 

end
  

