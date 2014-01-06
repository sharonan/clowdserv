class TestData
  def self.create_test_data
    return if @darcy
    
    puts "Creating test data"
    begin
      @darcy = User.create(:phone_number => "+177777", :first_name => "Fitzwilliam", :last_name => "Darcy", :password => "ilovelizzy",:user_id => '1')
      @elizabeth = User.create(:phone_number => "+155555555555", :first_name => "Elizabeth", :last_name => "Bennet", :password => "ilovedarcy",:user_id => '2')
      @jane = Nonuser.create(:phone_number => "+19999999999", :first_name => "Jane", :last_name => "Bennet")
      @wickham = User.create(:phone_number => "+122222", :first_name => "George", :last_name => "Wickham", :password => "imacad",:user_id => '4')
      @bingley = User.create(:phone_number => "+111111", :first_name => "Charles", :last_name => "Bingley", :password => "ilovejane",:user_id => '5')
      planid = SecureRandom.uuid

      ## a non user that will later become a user...
      @john_non_user = Nonuser.create(:phone_number => "+12345678901", :first_name => "John", :last_name => "Non")




      @ball = Event.create(:title => "Ball",
                          :id => "22222222-2222-2222-2222-222222222222",
                          :attendees => [@elizabeth.phone_number, @jane.phone_number, @darcy.phone_number, @bingley.phone_number],
                          :phone_number => @darcy.phone_number,
                          :event_plan_id => planid)

      @netherfield = Plan.create(:title => "Plan A",
                              :id => planid,
                              :event_id => @ball.id,
                              :location_title => "Netherfield",
                              :dtstart => DateTime.new(2013,12,31,5),
                              :status_datetime => DateTime.new(2013,12,13,5))

      @meryton = Plan.create(:title => "Plan B",
                            :id => SecureRandom.uuid,
                            :event_id => @ball.id,
                            :location_title => "Meryton",
                            :dtstart => DateTime.new(2014,01,01,5),
                            :status_datetime => DateTime.new(2013,12,13,5))

      # LMD Note: should automate the creation of attendances wehen we create events from the REST protocol or in test
      [@elizabeth, @jane, @darcy, @bingley].each { |attendee| Attendance.create(:id => attendee.phone_number, :event_id => @ball.id) }
      [@elizabeth, @darcy, @bingley].each do  |person|
        Attendee.create(:event_plan_id => @netherfield.id,
                        :event_id => @ball.id,
                        :phone_number => person.phone_number,
                        :id => SecureRandom.uuid,
                        :attendee_user_id => person.user_id,
                        :status => "pending")
      end
      Attendee.create(:event_plan_id => @netherfield.id,
                      :event_id => @ball.id,
                      :phone_number => @jane.phone_number,
                      :id => SecureRandom.uuid,

                      :status => "pending")
      @ball.add_message(@bingley, "Come, Darcy, I must have you dance. I hate to see you standing about by yourself in this stupid manner. You had much better dance.")
      @ball.add_message(@darcy, "I certainly shall not. You know how I detest it, unless I am particularly acquainted with my partner. At such an assembly as this
        it would be insupportable. Your sisters are engaged, and there is not another woman in the room whom it would not be a punishment to me to stand up with.")
      @ball.add_message(@bingley, "I would not be so fastidious as you are for a kingdom! Upon my honour, I never met with so many pleasant girls in
        my life as I have this evening; and there are several of them you see uncommonly pretty.")
      @ball.add_message(@darcy, "You are dancing with the only handsome girl in the room.")
      @ball.add_message(@bingley, "Oh! she is the most beautiful creature I ever beheld! But there is one of her sisters sitting down just behind you, who is very pretty, and I dare say very agreeable. Do let me ask my partner to introduce you.")
      @ball.add_message(@darcy, "She is tolerable; but not handsome enough to tempt me; and I am in no humour at present to give consequence to young ladies who are slighted by other men. You had better return to your partner and enjoy her smiles, for you are wasting your time with me.")
      
      Verification.generate("+15559876543")

      DeviceToken.create(phone_number: @darcy.phone_number, device_token: "XXX", device_token_arn: "YYY")
      
    rescue StandardError => e
      puts "ERROR creating test data: #{e.inspect}"
      raise e
    end
    puts "Finished test data"
  end
  
  def self.ball 
    raise "Testdata failure" if @ball.nil?
    return @ball
  end
  def self.netherfield 
    return @netherfield
  end
  def self.elizabeth
    @elizabeth
  end
  
  def self.jane
    @jane
  end
  
  def self.darcy
    @darcy
  end
  def self.wickham
    @wickham
  end
  
  def self.bingley
    @bingley
  end
  def self.john_non_user
    @john_non_user
  end

  def self.login(request, user)
    raise "Error: no password" if user.password.nil?
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(user.phone_number,user.password)
  end
  
  def self.get_login_info(user)
    {'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(user.phone_number,user.password)}
  end


end