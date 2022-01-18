require 'jubibot'

RSpec.describe(JubiBot, '#initialize') {
  before {
    allow(Discordrb::Bot).to(receive(:new))
  }

  it('passes params onward to Discordrb::Bot') {
    JubiBot.new(token: 'one', command_bot: nil)
    expect(Discordrb::Bot).to(have_received(:new).with(
                                  log_mode: :warn,
                                  token: 'one',
                                  intents: %i[
                                    servers
                                    server_members
                                    server_messages
                                    server_message_reactions
                                  ]))

    JubiBot.new(token: 'two', command_bot: nil, intents: %i[one two])
    expect(Discordrb::Bot).to(have_received(:new).with(
                                  log_mode: :warn,
                                  token: 'two',
                                  intents: %i[one two]))
  }
}
