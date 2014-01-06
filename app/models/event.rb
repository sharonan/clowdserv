class Event
  include Dynamoid::Document
  table :name => :event, :key => :id, :read_capacity => 400, :write_capacity => 400
  
  has_many :plans
  has_many :messages
  field :title
  field :status
  field :user_id
  field :event_attendees_push_end_points, :set
  field :event_plans, :set
  field :event_plan_id
  field :phone_number
  field :attendees, :set
  
  @user_dict = nil
    
  def prep_for_json 
    build_json = {}
    build_json['event_id'] = self.id
    build_json['title'] = self.title.nil? ? "<empty>" : self.title
    build_json['status'] = self.status.nil? ? "pending" : self.status
    build_json['organizer'] = self.phone_number
    build_json['user_id'] = self.user_id
    build_json['created_at'] = self.created_at.rfc3339
    build_json['updated_at'] = self.updated_at.rfc3339
    build_json['event_plan_id'] = self.event_plan_id
    build_json['event_plans'] = self.plans.map {|plan| plan.prep_for_json }
    build_json['attendees'] = self.attendees.nil? ? {} : self.attendees.map { |phone_number| prep_invitee_for_json(phone_number) }
    build_json['debug_number_plans'] = self.plans.count
    build_json['messages'] = self.messages.map { |message| message.prep_for_json }
    build_json
  end  
  
  def plans
    Plan.where(:event_id => self.id)
  end
  
  def messages
    Message.where(:event_id => self.id)
  end
  
  def add_message(user, content)
    Message.create(:event_id => self.id, :id => SecureRandom.uuid, :content => content, :phone_number => user.phone_number)
  end
  
  def prep_invitee_for_json(phone_number)
    build_json = {}
    build_json["phone_number"] = phone_number
    if users_dict[phone_number].nil?
      build_json["first_name"] = "Unknown" 
      build_json["last_name"] = "" 
      build_json["avatar_url"] = "" 
    else
      build_json["first_name"] = users_dict[phone_number][:first_name] 
      build_json["last_name"] = users_dict[phone_number][:last_name]
      build_json["avatar_url"] = users_dict[phone_number][:picture_url]
      if (users_dict[phone_number].has_key?("user_id"))
        build_json["user_id"] = users_dict[phone_number][:user_id]
      end
    end
    build_json
  end

  def users_dict
    if @user_dict.nil?
      @user_dict = {}
      @user_dict[organizer.phone_number] = organizer
      unless attendees.empty?
        attendees.each do |attendee_user_id|
          begin
            this_user = User.find_by_id(attendee_user_id)
            @user_dict[attendee_user_id] = {:first_name => this_user.first_name, :last_name => this_user.last_name, :picture_url => this_user.picture_url, :user_id => this_user.user_id}
          rescue NoMethodError
            non_user = Nonuser.find_by_id(attendee_user_id)
            if non_user.nil? 
              @user_dict[attendee_user_id] = {:first_name => "Unknown", :last_name => "", :picture_url => ""}
            else
              @user_dict[attendee_user_id] = {:first_name => non_user.first_name, :last_name => non_user.last_name, :picture_url => ""}
            end
          end
        end
      end
    end
    @user_dict
  end
  
  def organizer
    if @organizer.nil? 
      begin
        @organizer = User.where(:phone_number => phone_number).first
      rescue NoMethodError => e
        @organizer = User.new(phone_number: phone_number, first_name: "unknown"  )
        S3Logger.log("events", "#{id}", "Failed to lookup user for organizer #{phone_number} for event #{id}: #{e.inspect}")
      end
    end
    @organizer
  end
  
  def to_json
    JSON.generate(self.prep_for_json)    
  end
  
  def self.events_to_json(some_events)
    events_ht = { "events" => [ ], "debug_events_count" => some_events.length}
    some_events.each do |an_event|
      events_ht["events"] << an_event.prep_for_json
    end
    JSON.generate(events_ht)
  end
end
