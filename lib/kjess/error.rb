module KJess
  class Error < ::StandardError; end
  class NetworkError < Error; end

  class ProtocolError < Error; end
  class ClientError < ProtocolError; end
  class ServerError < ProtocolError; end
end
