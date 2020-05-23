class JubiBotError < RuntimeError; end

class InvalidParam < JubiBotError; end
class MemberNotFound < JubiBotError; end
class UserIDError < JubiBotError
  attr_reader :user_id

  def initialize(msg, user_id)
    @user_id = user_id
    super(msg)
  end
end
