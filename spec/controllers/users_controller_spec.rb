require 'spec_helper'

describe UsersController do
  before :all do
    @ball = TestData.ball
    @netherfield = TestData.netherfield
    @elizabeth = TestData.elizabeth
    @jane = TestData.jane
    @darcy = TestData.darcy
    @wickham = TestData.wickham
    @bingley = TestData.bingley
    @john_non_user = TestData.john_non_user
  end


  describe ".verify_me" do
    
    # POST /users/+15555551212/verify_me HTTP/1.1
    
    # HTTP/1.1 200 OK
    # Content-Type: application/json
    # 
    # "exists": "true"
    

    it "says if the user exists already" do
      post :verify_me, id: @darcy.phone_number, format: 'json'
      response.status.should == 200
      JSON.parse(response.body)["exists"].should == true
    end
    
    it "says if the user didn't exist already" do
      post :verify_me, id: '+15555555555', format: 'json'
      response.status.should == 200
      JSON.parse(response.body)["exists"].should == false
    end
    
    it "saves the verification code for checking later" do
      expect {post :verify_me, id: @darcy.phone_number, format:'json'}.to change{Verification.count}.by(1)
    end

    it "triggers a SMS" do
      expect(controller).to receive(:send_verification) { double("controller") }
      post :verify_me, id: @darcy.phone_number, format:'json'
    end    
    
  end
  
  
  describe ".create" do     
    # POST /users HTTP/1.1  
    # Content-Type: application/json
    # 
    # "user": { "phone_number": '+15555551212', "device_token": "XXX"}, "verification_code": 'XYZ' 
    
    # 200 OK
    # Content-Type: applicaton/json
    #
    # password: 129384655
    describe "setup user"  do
      before :each do

        aws_sns = double("aws_sns")
        client = double("client")
        sns_response = double("sns_response")
        expect(AWS::SNS).to receive(:new) { aws_sns }
        expect(aws_sns).to receive(:client) { client }
        client.should_receive(:create_platform_endpoint).and_return(sns_response)
        sns_response.should_receive(:data).and_return({endpoint_arn: "XXX"})
      end

      it "Creates a user that has a non user record and deletes his record there " do

        phone_number = @john_non_user.phone_number
        device_token = "28db13b2271f00c6c16e4efdaa9197311bc5c37a5ce31313a6ab1c8b84ab269-1"
        first_name = @john_non_user.first_name

        setup_user(phone_number,device_token,first_name)

        @response = response
        @response.status.should == 200

        user = User.find(phone_number)
        user.should_not be_nil

        result = JSON.parse(@response.body)
        result["password"].should_not be_nil

        DeviceToken.find(phone_number).should_not be_nil
        Verification.where(phone_number: phone_number).first.should be_nil
        user.device_tokens.should == [device_token]

        non_user = Nonuser.find(phone_number)
        non_user.should be_nil
      end

      it "creates a user, sets device token and returns password" do
        #setup
        phone_number = '+15555551212'
        device_token = "28db13b2271f00c6c16e4efdaa9197311bc5c37a5ce31313a6ab1c8b84ab2696"
        first_name = 'John'

        setup_user(phone_number,device_token,first_name)

        @response = response
        @response.status.should == 200

        user = User.find(phone_number)
        user.should_not be_nil

        result = JSON.parse(@response.body)
        result["password"].should_not be_nil

        DeviceToken.find(phone_number).should_not be_nil
        Verification.where(phone_number: phone_number).first.should be_nil
        user.device_tokens.should == [device_token]

      end
      context "when user exists" do

        it "returns a password" do
          v = Verification.generate(@bingley.phone_number)
          post :create, {user: {phone_number: @bingley.phone_number, device_token: "28db13b2271f00c6c16e4efdaa9197311bc5c37a5ce31313a6ab1c8b84ab2696",first_name: "John"},
                         verification_code: v.id, format: 'json'}
          response.status.should == 200
          result = JSON.parse(response.body)
          result["password"].should_not be_nil
        end

      end
    end

    context "checks required fields" do

      it "requires a valid verification code" do
        post :create, {user: {phone_number: "15555551234"}, format: 'json'}
        response.status.should == 403
        post :create, {user: {phone_number: "15555551234", device_token: "28db13b2271f00c6c16e4efdaa9197311bc5c37a5ce31313a6ab1c8b84ab2696",first_name: "John"},
            verification_code: 'ABC', format: 'json' }
        response.status.should == 403
      end


      
      it "requires device token" do
        Verification.create(phone_number: '+15555551215', id: 'JKL')
        post :create, {format: 'json', verification_code: "JKL",
                        user: {phone_number: '+15555551215',first_name: "John"}}
        response.status.should == 400
      end

      it "requires first_name" do
        Verification.create(phone_number: '+15555551216', id: 'JKM')
        post :create, {format: 'json', verification_code: "JKM",
                       user: {phone_number: '+15555551216',device_token: "28db13b2271f00c6c16e4efdaa9197311bc5c37a5ce31313a6ab1c8b84ab2695"}}
        response.status.should == 400
      end


      
      
    end
    

    
    context "when user and device token both exist" do
      it "succeeds" do
        v = Verification.generate('+15555551216')  
        dt = DeviceToken.create(phone_number: v.phone_number, device_token: "28db13b2271f00c6c16e4efdaa9197311bc5c37a5ce31313a6ab1c8b84ab2696", device_token_arn: "XXXXX")
        post :create, {user: {phone_number: v.phone_number, device_token: dt.device_token,first_name: "John"},
          verification_code: v.id, format: 'json'}
        response.status.should == 200
        result = JSON.parse(response.body)
        result["password"].should_not be_nil
      end
    end
  end
  

  
  describe ".update" do
    # POST /users/+15555551212 HTTP/1.1
    # Content-Type: application/json
    #
    # {"user":  {"first_name": "Lisa", "last_name": "Dusseault"}}
    
    # HTTP/1.1 200 OK 
    
    before :each do
      TestData.login(request, @elizabeth)
    end
    
    it "Changes the last name" do
      post :update, {id: @elizabeth.phone_number, user: {first_name: "Elizabeth", last_name: "Darcy"}, format: 'json'}
      response.status.should == 200
      ebeth = User.find(@elizabeth.phone_number)
      ebeth.last_name.should == "Darcy"
      ebeth.last_name = "Bennet"
      ebeth.save
    end

    it "DOESN't change the name if not specified" do
      post :update, {id: @elizabeth.phone_number, user: {picture_url: "http://example.com/img.jpg"}, format: 'json'}
      response.status.should == 200
      ebeth = User.find(@elizabeth.phone_number)
      ebeth.last_name.should == "Bennet"
      ebeth.picture_url.should == "http://example.com/img.jpg"
    end
    
    it "handles no parameters" do 
      post :update, {id: @elizabeth.phone_number, format: 'json'}
      response.status.should == 400
    end
    
    it "checks user authenticates as user updated" do      
      post :update, {id: @darcy.phone_number, user: {first_name: "Fitzwilliam", last_name: "Darcy"}, format: 'json'}
      response.status.should == 403
    end
    
  end
  
  
  describe ".index" do
    # GET /users HTTP/1.1
    # Content-Type: application/json
    # 
    # {"users": ["+15555551212", "+15558888888"]}
    
    # HTTP/1.1 200 OK 
    # Content-Type: application/json
    #
    # {"users": ["user": {"phone_number": "+15555551212", "first_name": "Elizabeth", "last_name": "Bennet", "is_registered": true},
    #             "user": ...]} 
    
    before :each do
      TestData.login(request, @elizabeth)
    end
    
    it "returns 400 if no phone numbers chosen" do
      get :index, {"users" => [], format: 'json'}
      response.status.should == 400
      get :index
      response.status.should == 400
    end
    
    it "returns first name etc if a valid number chosen" do
      get :index, {"users" => [@darcy.phone_number], format: 'json'}
      response.status.should == 200
      result = JSON.parse(response.body)
      result["users"][0]["phone_number"].should == @darcy.phone_number
      result["users"][0]["last_name"].should == @darcy.last_name
      result["users"][0]["is_registered"].should == true
    end
    
    it "skips a user who is not found at all" do
      get :index, {"users" => ["+18882288228"]}
      response.status.should == 200 
      result = JSON.parse(response.body)
      result["users"].should be_empty
    end
    
    it "shows nonusers as not registered" do
      get :index, {"users" => [@jane.phone_number], format: 'json'}
      response.status.should == 200
      result = JSON.parse(response.body)
      result["users"][0]["first_name"].should == @jane.first_name
      result["users"][0]["is_registered"].should == false
    end
  end
end