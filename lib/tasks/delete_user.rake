
# Use syntax "rake delete_user[+16502797365]"
task :delete_user, [:phone_number] => [:environment]   do |task, args|
  user = User.find(args.phone_number)
  
  unless user.nil?
    events = user.events
    puts "Deleting user from #{events.length} events"
    user.events.each do |event|
      if event.organizer == user
        puts "Deleting complete event with deleted organizer: #{event.id}"
        destroy_event_and_all(event)
      else
        strip_attendee_from_event(event, user.phone_number)
      end
    end
    user.destroy
  end
  
  Attendance.where(:id => args.phone_number).each do |attendance|
    puts "Delete users_events record for event #{attendance.event_id}" 
    attendance.destroy
  end
  
  Verification.where(phone_number: args.phone_number).each { |vfn| vfn.destroy }

  ddb = AWS::DynamoDB.new()
  dt_table = ddb.tables["#{ENV['DDB_TABLE_NAMESPACE']}_users_device_tokens"]
  dt_table.load_schema
  DeviceToken.where(phone_number: args.phone_number).each do |dt|
    puts "Delete device token #{dt.device_token}"
    # Tried both Dynamoid approaches to deleting item, but buggy:
    # DeviceToken.where(phone_number: user.phone_number, device_token: device_token.device_token).destroy_all
    # dt.destroy
    record = dt_table.items[args.phone_number, dt.device_token]
    puts "Deleting item #{ record.attributes.inspect}"
    record.delete
  end
end

def destroy_event_and_all(event)
  event.plans.each do |plan|
    plan.attendees.each { |attendee| attendee.destroy }
    plan.destroy
  end
  event.messages.each { |message| message.destroy }
  Attendance.where(:event_id => event.id).each { |attendance| attendance.destroy }
  event.destroy
end

def strip_attendee_from_event(event, phone_number)
  event.plans.each do |plan|
    plan.attendees.each do |attendee|
      if attendee.phone_number == phone_number
        puts "Destroy attendee #{attendee.inspect}"
        attendee.destroy
      end
    end
  end
  puts "Remove attendee from set in #{event.id}"
  event.attendees.delete(phone_number)
  event.save
  event.messages.each do |message|
    if message.phone_number == phone_number
      puts "Delete this chat message: #{message.id}"
      message.destroy
    end
  end
end
