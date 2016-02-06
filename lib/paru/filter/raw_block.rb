module Paru
    module PandocFilter
        require_relative "./block"

        class RawBlock < Block
            attr_accessor :format, :string

            def initialize(contents)
                @format = contents[0]
                @string = contents[1]
            end
        end
    end
end