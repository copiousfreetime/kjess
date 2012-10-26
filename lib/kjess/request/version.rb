require 'kjess/response'
class KJess::Request
  class Version < KJess::Request
    keyword         'VERSION'
    arity           0
    valid_responses KJess::Response::Version
  end
end
