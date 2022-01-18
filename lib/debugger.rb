# rubocop:disable Style/TopLevelMethodDefinition
def debugger(binding = TOPLEVEL_BINDING)
  require 'readline'

  while (input = Readline.readline('>> ', true))
    if input == 'exit'
      puts 'Exiting'
      break
    end

    # rubocop:disable Security/Eval, Lint/RescueException
    begin
      puts JSON.pretty_generate(eval(input, binding))
    rescue Exception => error
      puts "#{error.class}: #{error}"
    end
    # rubocop:enable Security/Eval, Lint/RescueException
  end
end
# rubocop:enable Style/TopLevelMethodDefinition
