require 'spec_helper'

describe EventsController do
  before :all do
    @ball = TestData.ball
    @netherfield = TestData.netherfield
    @elizabeth = TestData.elizabeth
    @jane = TestData.jane
    @darcy = TestData.darcy
    @wickham = TestData.wickham
    @bingley = TestData.bingley
  end
  
  
  describe "show" do
    it "returns json event" do
      TestData.login(request, @darcy)
      get :show, id: @ball.id, format: 'json'
      response.body.to_json
    end
    it "checks the user is an attendee or organizer and can view event" do
      TestData.login(request, @wickham)
      get :show, id: @ball.id, format: 'json'
      response.status.should == 401
    end
    it "handles bogus organizer" do
      expect(S3Logger).to receive(:log) { double("logger") }
      TestData.login(request, @darcy)
      @new_event = Event.create(phone_number: "000", id: "abc", attendees: [@darcy.phone_number])
      get :show, id: @new_event.id, format: 'json'
      response.status.should == 200
      @new_event.delete
    end
    
  end
  
  describe "show response body" do
    before :each do
      if @rj.nil?
        TestData.login(request, @darcy)
        get :show, id: @ball.id, format: 'json' 
        begin
          @rj = JSON.parse(response.body)
        rescue
          raise "Non-JSON body: #{response.body}"
        end
      end
    end
    
    it "contains the event_id" do
      @rj["event_id"].should == @ball.id
    end
    it "contains the title" do
      @rj["title"].should == @ball.title
    end
    it "contains the status" do
      @rj["status"].should == "pending"
    end
    it "contains the organizer field" do
      @rj["organizer"]
    end
    it "contains the event_plan_id in case the event is booked" do
      @rj["event_plan_id"].should == @netherfield.id
    end


    describe "event_plans" do
      before :each do
        @planA = @rj["event_plans"][0]
        unless (@planA["title"] == @netherfield.title)
          @planA = @rj["event_plans"][1]
        end
      end

      it "contains event_plans" do
        @rj["event_plans"].length.should == @ball.plans.all.length
      end
      it "includes the event_plan_id of each event_plan" do
        @planA["event_plan_id"].should == @netherfield.id
      end
      it "includes the title of each event_plan" do
        @planA["title"].should == @netherfield.title
      end
      it "includes the location_title of each event_plan" do
        @planA["location_title"].should == @netherfield.location_title
      end
      it "includes the location of each event_plan" do
        @planA["location"].should == "<empty>"
      end
      it "includes the dtstart of each event_plan" do
        @planA["dtstart"].should == "2013-12-30T21:00"
        # LMD TODO: this should actually not include a tz
      end
      it "includes the lat and long of each event_plan" do
        @planA.keys.should include("latitude")
        @planA.keys.should include("longitude")
      end

      it "includes the status of each event_plan" do
        @planA.keys.should include("status")
      end

      it "includes the attendees in each event_plan" do
        @planA.keys.should include("attendees")
      end
      it "includes the phone number for each attendee" do
        @planA["attendees"][0].keys.should include("phone_number")
        [@bingley.phone_number, @darcy.phone_number, @elizabeth.phone_number, @jane.phone_number].should include(@planA["attendees"][0]["phone_number"])
      end
      it "includes the status for each attendee" do
        @planA["attendees"][0].keys.should include("status")
      end
      it "includes the role for each attendee" do
        @planA["attendees"][0].keys.should include("role")
      end
      it "includes the  attendee_user_id" do
        user = User.find(@planA["attendees"][0]["phone_number"])
        if (!user.nil?)
        @planA["attendees"][0].keys.should include("user_id")
      end
      end
      it "includes the attendee_user_id of the user phone_number key" do
        user = User.find(@planA["attendees"][0]["phone_number"])
        if (!user.nil?)
          @planA["attendees"][0]["user_id"].should == user.user_id
        end
      end
    end

    it "includes the attendees alongside the plans" do
      @rj.keys.should include("attendees")
    end
    it "includes the attendees names" do
      @rj["attendees"].length.should == 4
      @rj["attendees"].each do |attendee|
        if attendee["phone_number"] == @elizabeth.phone_number
          attendee["first_name"].should == @elizabeth.first_name
          attendee["last_name"].should == @elizabeth.last_name
        elsif attendee["phone_number"] == @jane.phone_number
          attendee["first_name"].should == @jane.first_name
        end
      end
    end
    it "includes the attendees phone #" do
      @rj["attendees"][0]["phone_number"].should == @elizabeth.phone_number
    end
    
    it "includes chat messages" do
      @rj["messages"].length.should == 6
    end
    
  end
  
  describe "index" do

    it "filters by the organizer user_id" do
      TestData.login(request, @darcy)
      @event2 = Event.create(:title => "Apres Lunch", :id => "16ede053-fc35-46d8-a005-fae071b2b6e1", :user_id => "888888")
      get :index, user_id: @ball.phone_number, format: 'json'
      @rj = JSON.parse(response.body)
      @rj["events"].length.should == 1
    end
    
    it "finds events by the attendee user_id" do
      TestData.login(request, @elizabeth)
      get :new
      get :index, user_id: @elizabeth.phone_number, format: 'json'
      @rj = JSON.parse(response.body)
      @rj["events"].length.should == 1
    end
  
    it "Checks the right identity" do
      TestData.login(request, @darcy)
      get :index, user_id: @elizabeth.phone_number, format: 'json'
      response.status.should == 403
    end
  end
  
  describe "authentication and version checking" do

    it "Checks the client version" do
      TestData.login(request, @darcy)
      request.headers['X-Calaborate-version'] = "1.0.3"
      get :index, user_id: @darcy.phone_number, format: 'json'
      response.status.should == 403
    end
    
    it "Checks the client version before checking auth" do
      request.headers['X-Calaborate-version'] = "1.0.2"
      get :index, user_id: @darcy.phone_number, format: 'json'
      response.status.should == 403
    end
      
    
    it "checks the client version is OK" do 
      TestData.login(request, @darcy)
      request.headers['X-Calaborate-version'] = "2.0.1"
      get :index, user_id: @darcy.phone_number, format: 'json'
      response.status.should == 200
    end
  end
  
  
  
  describe 'new' do
    it 'requires authentication' do
      get :new
      response.status.should == 401
    end
    it 'successfully authenticates' do
      TestData.login(request, @darcy)
      get :new
      response.status.should == 200
    end
    it 'fails the wrong password' do
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@darcy.phone_number,"bogus")
      get :new
      response.status.should == 401
    end
    it 'fails with bogus user' do
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials('12345',"bogus")
      get :new
      response.status.should == 401
    end
  end
  
  describe 'idindex' do
    it 'requires authentication' do
      get 'idindex',  user_id: @darcy.phone_number, format: 'json'
      response.status.should == 401
    end
    
    describe "authenticated" do
      before :each do
        TestData.login(request, @darcy)
      end
      it 'returns a JSON body' do
        get 'idindex',  user_id: @darcy.phone_number, format: 'json'
        JSON.parse(response.body)
      end
      it 'returns the event id' do 
        get 'idindex',  user_id: @darcy.phone_number, format: 'json'
        JSON.parse(response.body)["event_ids"].should == [@ball.id]
      end
      
      it 'returns multiple events' do
        event = Event.create(:title => "Proposal",  :id => "111", 
           :attendees => [@elizabeth.phone_number, @darcy.phone_number],   :phone_number => @darcy.phone_number)
        attendance = Attendance.create(:event_id => "111", :id => @darcy.phone_number)
        get 'idindex',  user_id: @darcy.phone_number, format: 'json'
        JSON.parse(response.body)["event_ids"].length.should == 2
        event.delete
        attendance.delete
      end
    end
                              
  end

end
