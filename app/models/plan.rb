class Plan
  include Dynamoid::Document
  table :name => :event_plan, :key => :event_id, :read_capacity => 10, :write_capacity => 10

  range :id 

  has_many :attendees
  
  field :title
  field :location_title
  field :location
  field :dtstart, :datetime
  field :duration, :float
  field :latitude, :float
  field :longitude, :float
  field :event_organizer_id
  field :event_organizer_phone
  field :event_plan_organizer_phone 
  field :event_plan_organizer_user_id
  field :event_organizer_user_id
  field :dstart
  field :event_plan_id
  field :replaced_by
  field :status
  field :status_datetime, :datetime

  def attendees
    Attendee.where(:event_plan_id => self.id)
  end
  

  def prep_for_json
    build_json = {}
    build_json['event_plan_id'] = self.id
    build_json['title'] = self.title.nil? ? "<empty>" : self.title
    build_json['location_title'] = self.location_title.nil? ? "<empty>" : self.location_title
    build_json['location'] = self.location.nil? ? "<empty>" : self.location
    build_json['dtstart'] = self.dtstart.strftime('%FT%R')
    build_json['duration'] = self.duration
    build_json['latitude'] = self.latitude
    build_json['longitude'] = self.longitude
    build_json['status'] = self.status
    build_json['status_datetime'] = self.status_datetime.nil? ? "" : self.status_datetime.rfc3339
    build_json['replaced_by'] = self.replaced_by
    build_json['attendees'] = self.attendees.map {|attendee| attendee.prep_for_json }
    build_json['created_at'] = self.created_at.rfc3339
    build_json['updated_at'] = self.updated_at.rfc3339
    build_json['event_plan_organizer_user_id'] = self.event_plan_organizer_user_id


    build_json
  end
  
end