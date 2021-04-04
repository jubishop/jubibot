require 'jubibot'

require_relative '../lib/fake_bot'
require_relative '../lib/fake_event'

RSpec.describe(JubiBot, '#command') {
  shared_context('ping bot') {
    before {
      @fake_bot = Discordrb::FakeBot.new
      allow(Discordrb::Bot).to(receive(:new) { @fake_bot })

      @command_bot = double(Object, ping: nil)
    }

    def create_jubibot(**params)
      jubi_bot = JubiBot.new(token: 'tkn', command_bot: @command_bot, **params)
      jubi_bot.command('ping')
      jubi_bot.run
    end
  }

  context('processing basic commands') {
    include_context('ping bot')
    before { create_jubibot }

    it('passes along basic ping command') {
      @fake_bot.incoming_message(FakeEvent.new('!ping'))
      expect(@command_bot).to(have_received(:ping))
    }

    it('ignores commands that are not registered') {
      @fake_bot.incoming_message(FakeEvent.new('!pong'))
    }

    it('ignores messages that aren not commands') {
      @fake_bot.incoming_message(FakeEvent.new('ping'))
      expect(@command_bot).not_to(have_received(:ping))
    }
  }

  context('changing the server prefix') {
    include_context('ping bot')

    context('works with a basic string') {
      before { create_jubibot(prefix: '#') }

      it('passes along basic ping command') {
        @fake_bot.incoming_message(FakeEvent.new('#ping'))
        expect(@command_bot).to(have_received(:ping))
      }
    }
  }
}
