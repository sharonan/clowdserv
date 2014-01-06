class Attendee
  include Dynamoid::Document
  table :name => :event_plan_user, :key => :event_plan_id, :read_capacity => 10, :write_capacity => 5

  range :phone_number

  field :id
  field :event_id
  field :status
  field :role
  field :organizer_phone   #LMD Why is this in attendee
  field :status_datetime, :datetime
  field :organizer_id
  field :attendee_user_id
  field :event_id   # Not actually used but may exist
  field :plan_id    # Not actually used but may exist

  def prep_for_json
    build_json = {}
    build_json['phone_number'] = self.phone_number
    if (!self.attendee_user_id.nil?)      ## might be nil for non_user
      build_json['user_id'] = self.attendee_user_id
    end
    build_json['status'] = self.status
    build_json['role'] = self.role

    build_json
  end
  # LMD Issue: the phone _number is NOT the organizer's phoen #.


end