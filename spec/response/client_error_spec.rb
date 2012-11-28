require 'spec_helper'

describe KJess::ClientError do
  before do
    @client = KJess::Spec.kjess_client()
  end

  after do
    KJess::Spec.reset_server( @client )
  end

  it "raises a client error if we send an invalid command" do
    lambda { @client.send_recv( KJess::Request::Status.new ) }.must_raise KJess::ClientError
  end
end


