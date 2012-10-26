require 'spec_helper'

class KJess::Spec::TestRequest < KJess::Request
  keyword "TEST"
  arity   1

  def parse_options_to_args( opts )
    opts.values
  end
end

describe KJess::Response do
  it "defines a keyword for child classes" do
    KJess::Spec::TestRequest.keyword.must_equal 'TEST'
  end

  it "uses a callback to parse the options to args" do
    r = KJess::Spec::TestRequest.new( :foo => 'this' )
    r.args.must_equal %w[ this ]
  end

  it "converts the request into a protocol stream" do
    r = KJess::Spec::TestRequest.new( :foo => 'that' )
    r.to_protocol.must_equal "TEST that\r\n"
  end

  it "registers child classes" do
    KJess::Request.registry['TEST'].must_equal KJess::Spec::TestRequest
  end
end
