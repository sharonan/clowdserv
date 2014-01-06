require 'spec_helper'

describe Plan do
  before :all do 
    @event = Event.create(:title => "Lunch", :id => SecureRandom.uuid)
    @plan = Plan.create(:title => "Plan A", :id => SecureRandom.uuid, :event_id => @event.id)
    Attendee.create(:event_plan_id => @plan.id, :event_id => @event.id, :id => SecureRandom.uuid, :phone_number => "77777", :status => "pending")
  end
  
  it "cannot be created without any parameters" do
    expect {Plan.create}.to raise_error AWS::DynamoDB::Errors::ValidationException
  end
  
  it "can be created with an event" do    
    expect {
      Plan.create(:event_id => @event.id, :id => SecureRandom.uuid)      
    }.to change{Plan.count}.by(1)
  end
  
  it "has attendees" do
    @plan.attendees.should_not be_nil
  end
  
  it "has zero attendees when first created" do 
    event = Event.find_by_id(@plan.event_id)
    Plan.create(:event_id => event.id, :id => SecureRandom.uuid).attendees.count.should == 0
  end
end
