require 'csv'
require 'discordrb'

require 'core'
require 'rstruct'

require_relative 'exceptions'

class JubiBot
  JUBI = 205164078761508864
  public_constant :JUBI

  ##### PRIVATE STRUCTS #####
  Command = KVStruct.new(%i[aliases num_args whitelist owners proc])
  private_constant :Command

  Reaction = RStruct.new(:regex, :emojis)
  private_constant :Reaction

  CommandDoc = KVStruct.new(:description, %i[usage arg_notes])
  private_constant :CommandDoc

  class PaginatedMessage
    def initialize(messages, index = 0)
      @messages = messages
      @index = index
    end

    def move(direction)
      if direction == LEFT_ARROW
        @index -= 1
      elsif direction == RIGHT_ARROW
        @index += 1
      else
        raise ArgumentError, 'Direction must be LEFT_ARROW or RIGHT_ARROW'
      end
    end

    def message
      index = @index % @messages.length
      index += @messages.length if index.negative?

      return <<~MESSAGE.chomp
        #{@messages[index].strip}
        *page #{index + 1} of #{@messages.length}*
      MESSAGE
    end
    alias to_s message
  end
  private_constant :PaginatedMessage
  ###########################

  ##### PRIVATE CONSTANTS #####
  LEFT_ARROW = "\u{2B05}".freeze
  private_constant :LEFT_ARROW

  RIGHT_ARROW = "\u{27A1}".freeze
  private_constant :RIGHT_ARROW
  #############################

  attr_accessor :bot

  def initialize(token:,
                 command_bot:,
                 prefix: '!',
                 doc_file: nil,
                 homepage: nil,
                 permissions: 8,
                 error_message: 'Sorry, something went wrong.')
    @bot = Discordrb::Bot.new(log_mode: :warn, token: token)
    @command_bot = command_bot
    @prefix = prefix
    @docs = import_doc(doc_file)
    @homepage = homepage
    @permissions = permissions
    @error_message = error_message
    @commands = {}
    @aliases = {}
    @paginated_messages = {}
    @reactions = []
  end

  def command(command,
              aliases: [],
              num_args: 0,
              whitelist: false,
              owners: false,
              &block)
    command = command.to_sym
    num_args = (num_args..num_args) if num_args.is_a?(Numeric)
    @commands[command] = Command.new(aliases: aliases,
                                     num_args: num_args,
                                     whitelist: whitelist,
                                     owners: owners,
                                     proc: block)
    aliases.each { |alias_| @aliases[alias_.to_sym] = command }
  end

  # Only emojis or &block is needed.
  def react(regex, emojis = nil, &block)
    @reactions.push(Reaction.new(regex, emojis.nil? ? block : emojis))
  end

  def send_paginated_message(channel, messages)
    paginated_message = PaginatedMessage.new(messages)
    message = channel.send_message(paginated_message)
    @paginated_messages[message.id] = paginated_message
    message.react(LEFT_ARROW)
    message.react(RIGHT_ARROW)
  end

  def run(async: false)
    bot.reaction_add { |event| paginated_reaction(event) }
    bot.reaction_remove { |event| paginated_reaction(event) }

    bot.message { |event|
      if event.message.text.start_with?("#{prefix}debug")
        debugger(binding) if event.author == JUBI
        next
      end

      process_reactions(event)

      response = process_command(event)
      event.respond(response) if response.is_a?(String) && !response.empty?
    }

    bot.run(async)
  end

  # Helper functions for getting member(s) from name(s), defaulting to author.
  def members(event, names = [])
    return [event.author] if names.empty?

    return names.map { |name| member(event, name) }
  end

  def member(event, name = nil)
    return event.author if name.nil?

    mentioned_id = mentioned_id(name)
    return bot.member(event.server, mentioned_id) if mentioned_id

    member = event.server.members.find { |m| [m.name, m.nick].include?(name) }
    raise MemberNotFound, name if member.nil?

    return member
  end

  def invite
    return bot.invite_url(permission_bits: @permissions)
  end

  ##### PRIVATE #####
  private

  def prefix(event)
    return @prefix.is_a?(Proc) ? @prefix.run(event) : @prefix.to_s
  end

  def cmd(command)
    return "#{prefix}#{command}"
  end

  def command_name(command)
    command = command.to_sym
    return @aliases.fetch(command, command)
  end

  def mentioned_id(name)
    mentioned_id = name[/^<@!?(?<id>\d+)>$/, :id]
    return if mentioned_id.nil?

    return Integer(mentioned_id, 10)
  end

  def import_doc(doc_file)
    return if doc_file.nil?

    docs = JSON.parse(File.read(doc_file)).deep_symbolize_keys!
    docs.transform_values! { |command_doc|
      CommandDoc.new(command_doc)
    }
    return docs
  end

  def paginated_reaction(event)
    return unless [LEFT_ARROW, RIGHT_ARROW].include?(event.emoji.name) &&
                  @paginated_messages.key?(event.message.id)

    paginated_message = @paginated_messages.fetch(event.message.id)
    paginated_message.move(event.emoji.name)
    event.message.edit(paginated_message)
  end

  def process_reactions(event)
    message = event.message
    @reactions.each { |reaction|
      match_data = message.text.match(reaction.regex)
      next unless match_data

      emojis = reaction.emojis
      emojis = emojis.run(event, match_data) if emojis.is_a?(Proc)
      Array(emojis).each { |emoji|
        message.react(emoji.is_a?(String) ? emoji : bot.emoji(emoji))
      }
    }
  end

  def process_command(event)
    message = shift_command(event.message)
    return unless message

    begin
      params = CSV.parse_line(message.strip, col_sep: ' ').compact
    rescue CSV::MalformedCSVError
      return 'It appears you used an unclosed " in your command.'
    end

    command_name = command_name(params.shift)
    return help_message(params) if command_name == :help

    return unless @commands.key?(command_name)

    Discordrb::LOGGER.info("#{event.server.name} => " \
                           "#{event.author.display_name} :: " \
                           "#{command_name}: #{params.join(',')}")

    command = @commands[command_name]
    unless command_allowed(command, event.author)
      return "`#{command_name}` is executable by admins only."
    end

    num_args = params.length
    unless command.num_args.include?(num_args)
      qualifier = num_args > command.num_args.max ? 'Too many' : 'Not enough'
      response = "#{qualifier} args passed to `#{command_name}`."
      if @docs.key?(command_name)
        response << "  Try `#{cmd('help')} #{command_name}`."
      end
      return response
    end

    return execute_command(command_name, command, event, params)
  end

  def command_allowed(command, author)
    return true unless command.whitelist || command.owners

    return true if command.whitelist.is_a?(Enumerable) &&
                   command.whitelist.include?(author.id)

    return true if command.whitelist == author.id

    return true if command.owners && author.owner?

    return false
  end

  def shift_command(message)
    return shift_prefix(message) || shift_mention(message)
  end

  def shift_prefix(message)
    return unless message.text.start_with?(prefix)

    return message.text[prefix.length..]
  end

  def shift_mention(message)
    return unless message.text.start_with?("<@!#{bot.profile.id}>")

    message.mentions.shift
    return message.text["<@!#{bot.profile.id}>".length..]
  end

  def execute_command(command_name, command, event, params)
    args = command.proc.nil? ? params : command.proc.run(event, *params)
    return @command_bot.public_send(command_name, *args)
  rescue InvalidParam => e
    return "Error with parameters to `#{command_name}`:\n  #{e.message}."
  rescue MemberNotFound => e
    name = e.message
    return "#{name} not found on #{event.server.name}."
  rescue UserIDError => e
    member = event.server.member(e.user_id)
    return e.message.gsub('{name}', member.display_name)
  rescue JubiBotError => e
    return e.message
  rescue Discordrb::Errors::NoPermission => e
    return e.message
  rescue StandardError => e
    Discordrb::LOGGER.error(e.full_message)
    return @error_message
  end

  def help_message(params)
    return <<-HELP.strip if params.empty?
**List of commands**
    *For detailed command info, add it after `#{cmd('help')}`.*
#{@docs.map { |command, command_doc|
  "  `#{command}`: #{command_doc.description}"
}.join("\n")}
#{"For more info see #{@homepage}" if @homepage}
    HELP

    if params.length > 1
      return "Too many args passed to `help`.  It's just `help [command]`."
    end

    return help_command(command_name(params.first))
  end

  def help_command(command_name)
    doc = @docs[command_name]
    if doc.nil?
      return "No help exists for `#{command_name}`. Try `#{cmd('help')}`."
    end

    command = @commands.fetch(command_name)
    response = "`#{command_name}`: #{doc.description}"
    unless command.aliases.empty?
      response << "\n  *aliases:* `#{command.aliases.join('`, `')}`"
    end
    response << "\n  *Usage:* `#{cmd(command_name)}"
    response << (doc.usage.nil? ? '`' : " #{doc.usage}`")
    if doc.arg_notes
      response << "\n  *Note:*" << "\n    #{doc.arg_notes.join("\n    ")}"
    end
    return response
  end
end
