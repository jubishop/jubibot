require 'jubibot'

require_relative '../lib/fake_bot'
require_relative '../lib/fake_event'

RSpec.describe(JubiBot, '#command') {
  shared_examples('a ping bot') { |**params|
    before {
      @prefix = params.fetch(:prefix, '!')
      @prefix = @prefix.call if @prefix.is_a?(Proc)

      @fake_bot = Discordrb::FakeBot.new
      allow(Discordrb::Bot).to(receive(:new) { @fake_bot })
      @command_bot = double(Object, ping: nil)
      jubi_bot = JubiBot.new(token: 'tkn', command_bot: @command_bot, **params)
      jubi_bot.command('ping')
      jubi_bot.run
    }

    it('passes along basic ping command') {
      @fake_bot.incoming_message(FakeEvent.new("#{@prefix}ping"))
      expect(@command_bot).to(have_received(:ping))
    }

    it('ignores commands that are not registered') {
      @fake_bot.incoming_message(FakeEvent.new("#{@prefix}pong"))
    }

    it('ignores messages that are not commands') {
      @fake_bot.incoming_message(FakeEvent.new('ping'))
      expect(@command_bot).not_to(have_received(:ping))
    }
  }

  context('processing basic commands') {
    it_behaves_like('a ping bot')
  }

  context('changing the server prefix') {
    context('with a basic string') {
      it_behaves_like('a ping bot', { prefix: '#' })
    }

    context('with a proc') {
      it_behaves_like('a ping bot', { prefix: proc { '@' } })
    }
  }
}
