require 'spec_helper'

describe Event do
  before :all do
    @ball = TestData.ball
  end
  it "can be created without any parameters" do
    Event.create
  end
  
  it "has an organizer" do 
    @ball.organizer.should_not be_nil
    @ball.organizer.first_name.should == "Fitzwilliam"
  end
  
  it "generates json" do 
    @ball.prep_for_json.should include("event_id")
  end
  
  it "Generates json even when attendee is bogus" do
    @ball.attendees << "bogus"
    @ball.prep_for_json
    @ball.attendees.delete("bogus")
  end
  
  it "Generates json even when no attendees" do 
    event = Event.create
    event.prep_for_json["event_id"].should == event.id
  end
end
