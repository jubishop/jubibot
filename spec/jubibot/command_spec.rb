require 'jubibot'

require_relative '../lib/fake_bot'
require_relative '../lib/fake_event'

RSpec.describe(JubiBot, '#command') {
  it('processes basic command') {
    fake_bot = Discordrb::FakeBot.new
    allow(Discordrb::Bot).to(receive(:new) { fake_bot })

    command_bot = double(Object, ping: nil)
    jubi_bot = JubiBot.new(token: 'one', command_bot: command_bot)

    jubi_bot.command('ping')
    jubi_bot.run

    fake_bot.incoming_message(FakeEvent.new('!ping'))
    expect(command_bot).to(have_received(:ping))
  }
}
