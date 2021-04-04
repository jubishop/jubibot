class FakeEvent
  include RSpec::Mocks::ExampleMethods

  attr_reader :message
  attr_accessor :server, :author

  Message = Struct.new(:text, keyword_init: true)
  private_constant :Message

  def initialize(message, server: spy('server'), author: spy('author'))
    @message = Message.new(text: message)
    @server = server
    @author = author
  end
end
