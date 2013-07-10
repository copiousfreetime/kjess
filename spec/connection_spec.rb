require 'spec_helper'

describe KJess::Connection do

  it "Returns a callable for the factory" do
    KJess::Connection.socket_factory.respond_to?(:call).must_equal true
  end

  it "Default Factory returns a KJess::Socket" do
    factory = KJess::Connection.socket_factory
    s = factory.call( :port => KJess::Spec.memcache_port, :host => 'localhost' )
    s.instance_of?(KJess::Socket).must_equal true
  end

end
