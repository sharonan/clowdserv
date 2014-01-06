class UsersController < ApplicationController
  include ApplicationHelper
  
  skip_before_action :authenticate, only: [:create, :verify_me]
  before_action :internal_verify_code, only: [:create]
  before_action :require_device_token, only: [:create]
  before_action :require_first_name, only: [:create]

  
  def verify_me
    @user = User.find(params[:id])
    v = Verification.generate(params[:id])
    send_verification(v.id, params[:id])
    if @user.nil?
      render json: {:exists => false}
    else
      render json: {:exists => true}
    end
    
  end
  

  def create
    @user = User.find(params["user"][:phone_number])
    ### added a check for non_user anyways:
    ### since we already have users that have non_user record , if they will
    ### delete the app and re-register ,next time their record will be deleted from non_users
    non_user = Nonuser.find(params["user"][:phone_number])
    if (!non_user.nil?)
      non_user.destroy
    end
    if @user.nil?
      params_we_want = params["user"].select{ |key| ["phone_number", "first_name", "last_name", "picture_url"].include?(key)}
      @user = User.new(params_we_want.merge({:password => SecureRandom.urlsafe_base64(n=6),:user_id => SecureRandom.uuid}))
    end
    
    device_token = params["user"]["device_token"] 
    dt_record = @user.add_device_token(device_token) if device_token
        
    raise "Somehow the user device token is not in the user record" if @user.device_tokens.nil? || @user.device_tokens_arns.nil?
    @user.save! 
    dt_record.save!
    Verification.find(params["verification_code"]).destroy
    render json: {:password => @user.password}.to_json 
  end
   
  def update
    @user = User.find(params["id"])
    if @user.nil? 
      head :not_found
    elsif @user.phone_number != current_user.phone_number
      head :forbidden
    elsif params["user"].nil?
      head :bad_request
    else
      if params["user"]["first_name"] && !params["user"]["first_name"].blank? 
        @user.first_name = params["user"]["first_name"]
      end
      if params["user"]["last_name"] && !params["user"]["last_name"].blank? 
        @user.last_name = params["user"]["last_name"]
      end
      if params["user"]["picture_url"] && !params["user"]["picture_url"].blank?
        @user.picture_url = params["user"]["picture_url"]
      end
      if @user.save
        head 200
      else
        
        head 500
      end
    end 
  end
  
  def index
    if params["users"].nil? || params["users"].empty?
      head 400
      return
    end
    results = []
    params["users"].each do |number|
      user = User.find(number)
      if user
        results << user.to_json 
      else
        nonuser = Nonuser.find(number)
        if nonuser
          results << nonuser.to_json
        end
      end
    end
    render json: {"users" => results}
  end
  
  private
  
  def internal_verify_code
    if !params["user"]
      logger.warn("create request invalid, #{request.body}")
      head 400
    elsif !Verification.verify(params["verification_code"], params["user"]["phone_number"])
      logger.warn("Verification code failure on user creation request for #{params.inspect}")
      render text: "Verification code incorrect", status: 403
    end
  end
  
  def send_verification(code, phone_number)
    unless Rails.env.test?
      account_sid = ENV['TWILIO_ACCOUNT_SID']
      auth_token = ENV['TWILIO_AUTH_TOKEN']
      client = Twilio::REST::Client.new account_sid, auth_token
      unless phone_number.start_with?('+')
        phone_number = "+1#{phone_number}"
      end
      client.account.sms.messages.create(
            :from => ENV['TWILIO_FROM_NUMBER'],
            :to =>   phone_number,
            :body => "Use #{code} to verify your Clowder account")
    end
  end
  
  def require_device_token
    if params["user"]["device_token"].nil?
      head 400
    end
  end


  def require_first_name
    if params["user"]["first_name"].nil?  || params["user"]["first_name"].empty?
      head 400
    end
  end
  
  

end