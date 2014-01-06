class Message
  include Dynamoid::Document
  table :name => :message, :key => :event_id, :read_capacity => 10, :write_capacity => 5
  
  range :id
  
  field :content
  field :phone_number
  field :user_id
  field :message_id

  
  def prep_for_json
    {"id" => id, "content" => content, "phone_number" => phone_number, "user_id" => user_id,  "created_at" => created_at,  "updated_at" => updated_at}
  end
end