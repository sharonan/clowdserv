class Verification
  include Dynamoid::Document
  table :name => :verifications, :key => :id, :read_capacity => 40, :write_capacity => 10
  
  field :phone_number
  
  def self.generate(phone_number)
    chars = ('A'..'Z').to_a
    code = ''
    3.times{ code << chars[rand(chars.length)]}
    return Verification.create(phone_number: phone_number, id: code)
  end
  
  def self.verify(code, phone_number)
    return false if code.nil? || code.empty?
    lookup = Verification.find(code)
    !lookup.nil? && phone_number == lookup.phone_number
  end
  
end