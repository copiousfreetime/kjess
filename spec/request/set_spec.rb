require 'spec_helper'

describe KJess::Request::Set do
  it "converts to the protocol" do
    s = KJess::Request::Set.new( :queue => 'test', :data => 'a job' )
    s.to_protocol.must_equal "SET test 0 0 5\r\na job\r\n"
  end

  it "sets the expriation time" do
    s = KJess::Request::Set.new( :queue => 'test', :expiration => 42, :data => 'a job' )
    s.to_protocol.must_equal "SET test 0 42 5\r\na job\r\n"
  end
end
