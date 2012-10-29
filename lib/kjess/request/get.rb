class KJess::Request
  class Get < KJess::Request
    keyword 'GET'
    arity   1
    valid_responses [ KJess::Response::Value ]

    def parse_options_to_args( opts )
      a = [ opts[:queue_name] ]

      a << "t=#{opts[:wait_for]}" if opts[:wait_for]

      [ :open, :close, :abort, :peek ].each do |o|
        a << o.to_s if opts[o]
      end

      [ a.join("/") ]
    end
  end
end


