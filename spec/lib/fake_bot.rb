require 'jubibot'

module Discordrb
  class FakeBot
    include RSpec::Matchers
    # Stubs incoming from JubiBot
    def initialize(**_)
      @ran = false
    end

    attr_reader :reaction_add_block,
                :reaction_remove_block,
                :message_block,
                :async,
                :ran

    # Helpers for RSpec
    def incoming_message(event)
      message_block.call(event)
    end

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
