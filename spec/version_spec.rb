require 'spec_helper'
require 'kjess'

describe KJess::VERSION do
  it 'should have a #.#.# format' do
    KJess::VERSION.must_match( /\A\d+\.\d+\.\d+\Z/ )
    KJess::VERSION.to_s.must_match( /\A\d+\.\d+\.\d+\Z/ )
  end
end
