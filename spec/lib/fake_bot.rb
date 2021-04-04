require 'jubibot'

module Discordrb
  class FakeBot
    include RSpec::Matchers
    include RSpec::Mocks::ExampleMethods

    attr_reader :reaction_add_block,
                :reaction_remove_block,
                :message_block,
                :async,
                :ran,
                :profile

    def initialize(**_)
      @ran = false
      @profile = double('profile').as_null_object
    end

    # Helpers for RSpec
    def incoming_message(event)
      message_block.call(event)
    end

    # Stubs incoming from JubiBot
    def reaction_add(&block)
      @reaction_add_block = block
    end

    def reaction_remove(&block)
      @reaction_remove_block = block
    end

    def message(&block)
      @message_block = block
    end

    def run(async)
      @async = async
      @ran = true
    end
  end
end
