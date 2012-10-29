require 'spec_helper'

describe KJess::Request::Version do

  it "has a keyword" do
    KJess::Request::Version.keyword.must_equal "VERSION"
  end

  it "converts to the protocol" do
    v = KJess::Request::Version.new
    v.to_protocol.must_equal "VERSION\r\n"
  end

  it "has a valid response" do
    KJess::Request::Version.valid_responses.size.must_equal 1
  end
end
