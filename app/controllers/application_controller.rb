class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  skip_before_action :verify_authenticity_token
  protect_from_forgery with: :null_session
  before_action :authenticate, :except => [:home]
  prepend_before_action :clear_dynamoid_cache
  prepend_before_action :check_app_version
  
  unless  Rails.application.config.consider_all_requests_local
    rescue_from ActionController::RoutingError, :with => :render_404
  end
  
  def check_app_version
    obsoleted_versions = ["1.0.0", "1.0.1", "1.0.2", "1.0.3"]
    version = request.headers["X-Calaborate-version"]
    if version && obsoleted_versions.include?(version)
      S3Logger.log("Obsolete client version", version, request.inspect)
      render text: "Obsolete client version, please upgrade", status: 403
    end
  end
  
  def clear_dynamoid_cache
    Dynamoid::IdentityMap.clear
  end

  def home
    render :text => "Environment: #{Rails.env}/#{ENV['RAILS_ENV']}/#{ENV['RACK_ENV']}"
  end

  
  def render_404 
    user_info = @the_user.nil? ? "nil user" : "#{@the_user.phone_number}/{@the_user.first_name}"
    S3Logger.log("404 Not Found", "404", "#'{request.fullpath}'\nNot found by #{user_info}")
    render text: "404 Not Found", status: 404
  end
  
  # LMD: TODO: See if there's a better way to do this, e.g. an exception in protect_from_forgery above
  def verified_request?
      if request.content_type == "application/json"
        true
      else
        super()
      end
  end
  
  def current_user
    return @the_user
  end
  
  private

  
  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      begin
        @the_user = User.find_by_id(username, :consistent_read => true)
        return true if (password == "letmein" && !Rails.env.production? && !@the_user.nil?) 
      rescue StandardError => e
        logger.warn "Authentication of unknown user #{username} failed with #{e.inspect}"
        raise e
      end
      if @the_user && password != @the_user.password
        logger.warn "Authentication of #{username} rejected with #{password} instead of #{@the_user.password}"
      end
      @the_user && password == @the_user.password
    end
  end
  
  
end
