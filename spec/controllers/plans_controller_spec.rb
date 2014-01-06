require 'spec_helper'

describe PlansController do
  before :all do
    @ball = TestData.ball
    @netherfield = TestData.netherfield
    @elizabeth = TestData.elizabeth
    @jane = TestData.jane
    @darcy = TestData.darcy
    @wickham = TestData.wickham
  end
  plan_template = {duration: 3600, location: "100 High st", latitude: 0, longitude: 0, 
    location_title: "Coffee shop",  dtstart: DateTime.now.rfc3339, title: "plan A" }

  describe "create" do
    it "creates a plan" do
      TestData.login(request, @darcy)
      @event = Event.create(:title => "Test event", :id => SecureRandom.uuid, :phone_number => @darcy.phone_number, :attendees => [@darcy.phone_number])
      plan_data = plan_template.clone 
      plan_data["id"] = SecureRandom.uuid
      post_body = {:event_id => @event.id, :plan => plan_data}
      post :create, post_body
    end
  end
 
  describe "new" do
    it "shows the new plan page" do
      TestData.login(request, @darcy)
      @event = Event.create(:title => "Test event", :id => SecureRandom.uuid, :phone_number => @darcy.phone_number, :attendees => [@darcy.phone_number])
      get :new, {:event_id => @event.id}
      response.status.should == 200
    end
  end
 
end
