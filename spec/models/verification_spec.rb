require 'spec_helper'

describe Verification do
  before :all do
    @darcy = TestData.darcy
    @ball = TestData.ball
  end
  before :each do
    @v = Verification.generate(@darcy.phone_number)
  end
  
  after :each do 
    @v.delete
  end

  it "generates itself" do
    @v.phone_number.should == @darcy.phone_number
    @v.id.should_not be_nil
    @v.id.should_not be_empty
  end
  
  it "verifies itself" do
    Verification.verify(@v.id, @darcy.phone_number).should be_true
    Verification.verify(@v.id, 'bogus').should be_false
    Verification.verify("bogus", @darcy.phone_number).should be_false
  end
  
  it "handles nil and empty code" do
    Verification.verify("", @darcy.phone_number).should be_false
    Verification.verify(nil, @darcy.phone_number).should be_false
  end
end
