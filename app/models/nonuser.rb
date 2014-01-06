class Nonuser
  include Dynamoid::Document
  table :name => :non_users, :key => :phone_number, :read_capacity => 400, :write_capacity => 400

  field :first_name
  field :last_name
  field :inviter_phone_number 
  field :inviter_device_tokens_arns  
  
  def to_json
    {"phone_number" => phone_number, 
      "first_name" => first_name, 
      "last_name" => last_name,
      "is_registered" => false}
  end
end