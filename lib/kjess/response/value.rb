class KJess::Response
  class Value < KJess::Response
    keyword 'VALUE'
    arity    3

    attr_accessor :data

    def queue; args[0]; end
    def flags; args[1]; end
    def bytes; args[2]; end

  end
end
