require 'test_helper'

class PlansControllerTest < ActionController::TestCase
  setup do
    @event = Event.create(:title => "Hello World")
    @plan = Plan.create(:title => "Plan A", :event_id => @event.id)
  end

  test "should get new" do
    get :new, :event_id => @event.id
    assert_response :success
  end

  test "should create plan" do
    assert_difference('Plan.count') do
      post :create, {:event_id => @event, :plan => { duration: @plan.duration, location: @plan.location, latitude: @plan.latitude, longitude: @plan.longitude, location_title: @plan.location_title, dtstart: @plan.dtstart, title: @plan.title }}
    end

    assert_redirected_to event_path(@event)
  end
  
  test "JSON request should create plan" do
    plan_dict = { format: 'json', :event_id => @event, :plan => {duration: 3600, location: "100 High st", latitude: 0, longitude: 0, 
      location_title: "Coffee shop", dtstart: @plan.dtstart, title: "plan A" }}
    assert_difference('Plan.count') do
      post :create, plan_dict, "Content-Type"=> "application/json"
    end
    assert_response :success
  end

end
