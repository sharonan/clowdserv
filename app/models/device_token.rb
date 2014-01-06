class DeviceToken
  include Dynamoid::Document
  table :name => :users_device_tokens, :key => :phone_number, :read_capacity => 10, :write_capacity => 2
  field :device_token
  
  field :device_token_arn 
  
  def self.build_with_arn(phone_number, device_token)
    raise "Phone Number required" if phone_number.nil?
    client = AWS::SNS.new(:create_topic => true, :delete_topic => false, :create_subscription => true).client
    
    begin
      sns_response = client.create_platform_endpoint( {:platform_application_arn => "#{ENV['SNS_APPLICATION_ARN']}",
                                                      :attributes=>{"Enabled"=>"true", "CustomUserData"=>phone_number, "Token"=>device_token},
                                                      :token =>device_token,
                                                      :custom_user_data => phone_number})
      endpoint_arn = sns_response.data[:endpoint_arn]
    rescue AWS::SNS::Errors::InvalidParameter => ipe
      message_parts = ipe.message.split
      if message_parts.index("Endpoint") 
        endpoint_arn = message_parts[message_parts.index("Endpoint")+1]
      end
      S3Logger.log("SNS Error", "SNS Error", "attempted to extract #{endpoint_arn} from #{ipe.inspect}")
    end
    build(:phone_number => phone_number, :device_token => device_token, :device_token_arn => endpoint_arn)
    
  end
  
      
end