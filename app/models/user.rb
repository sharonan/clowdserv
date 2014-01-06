class User
  include Dynamoid::Document
  table :name => :users, :key => :phone_number, :read_capacity => 400, :write_capacity => 400

  field :first_name
  field :last_name
  field :friends_phones, :set
  field :picture_url
  field :user_id
  field :device_tokens, :set
  field :device_tokens_arns, :set
  field :email_address
  field :password
  
  def inspect
    "#{first_name} #{last_name}, #{phone_number}, #{email_address}, #{device_tokens}, #{device_tokens_arns}"
  end
  
  def events
    event_ids = Attendance.where(:id => phone_number).all.map {|a| a.event_id}
    events = event_ids.map { |id| Event.find_by_id(id) }
    events.delete_if { |event| event.nil? }   #Remove events we could not find
  end
  
  def to_json
    {"phone_number" => phone_number,
      "user_id" => user_id,
      "first_name" => first_name,
      "last_name" => last_name,
      "picture_url" => picture_url, 
      "is_registered" => true} 
  end

  # This method takes a device_token_arn so we can set it to something for testing without hitting SNS for real life
  def add_device_token(device_token, device_token_arn = nil)
    dt = DeviceToken.where(:phone_number => phone_number, :device_token => device_token).first
    if dt.nil?
      if device_token_arn.nil?
        dt = DeviceToken.build_with_arn(phone_number, device_token)
      else
        dt = DeviceToken.build(:phone_number => phone_number, :device_token => device_token, :device_token_arn => device_token_arn)
      end
    end
    self.device_tokens = [] if device_tokens.nil?
    self.device_tokens << device_token
    self.device_tokens_arns = [] if device_tokens_arns.nil?
    self.device_tokens_arns << dt.device_token_arn
    dt
  end
  
  
end