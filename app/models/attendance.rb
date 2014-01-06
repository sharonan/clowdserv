class Attendance
  include Dynamoid::Document
  table :name => :users_events, :key => :id, :read_capacity => 400, :write_capacity => 400
  range :event_id 
  
end