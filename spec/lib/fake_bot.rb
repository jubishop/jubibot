require 'jubibot'

module Discordrb
  class FakeBot
    include RSpec::Matchers

    def initialize(**_); end

    def ==(*)
      true
    end
  end
end
