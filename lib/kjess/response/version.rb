class KJess::Response
  class Version < KJess::Response
    keyword 'VERSION'
    arity    1

    def version
      args.first
    end
  end
end
