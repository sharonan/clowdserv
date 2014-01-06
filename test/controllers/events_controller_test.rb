require 'test_helper'

class EventsControllerTest < ActionController::TestCase
  setup do
    @event1 = Event.create(:title => "Hello World")
    @event2 = Event.create(:title => "Dorothy's Trip", :user_id => 9292)
  end
  
  teardown do
    @event1.delete
    @event2.delete
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:events)
  end
  
  test "should get index for user" do 
    get :index, { :user_id => 9292 }
    assert_response :success
    assert_not_nil assigns(:events)
    assert_equal( 1, assigns(:events).length)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create event" do
    assert_difference('Event.count') do
      post :create, event: { status: @event1.status, title: @event1.title }
    end

    assert_redirected_to event_path(assigns(:event))
  end

  test "should show event" do
    get :show, id: @event1
    assert_not_nil assigns(:plans)
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @event1
    assert_response :success
  end

  test "should update event" do
    patch :update, id: @event1, event: { status: "pending", title: @event1.title }
    assert_redirected_to event_path(assigns(:event))
  end

  test "should destroy event" do
    assert_difference('Event.count', -1) do
      delete :destroy, id: @event1
    end

    assert_redirected_to events_path
  end
end
