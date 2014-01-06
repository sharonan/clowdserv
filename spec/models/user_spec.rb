require 'spec_helper'

describe User do
  before :all do
    @darcy = TestData.darcy
    @ball = TestData.ball
  end

  it "can be created without any parameters" do
    User.create
  end
  
  it "returns all events it is participating in" do
    @darcy.events.first.id.should == @ball.id
  end
  
end
