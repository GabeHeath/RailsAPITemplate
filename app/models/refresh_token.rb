require 'json_web_token'

# This is the long-lived token used to refresh the client's access token.
class RefreshToken < ApplicationRecord
  belongs_to :user

  before_validation :set_token_value, on: :create
  validates_presence_of :value

  def set_token_value
    self.value = JsonWebToken.encode({ user_id: self.user_id }, 'refresh')
  end

  def self.revoke(token)
    token = find_by_value(token)
    return nil unless token
    token.destroy
  end

  def self.validate_and_refresh(token)
    begin
      payload = JsonWebToken.decode(token)[0]
    rescue => error
      logger.error error
      revoke(token)
      return nil
    end

    user_id = payload['user_id']

    if payload && find_by_value(token) && JsonWebToken.valid_payload(payload, 'refresh')
      refresh_token = refresh(user_id)
      access_token = JsonWebToken.encode({user_id: user_id}, 'access')
      return { refresh: refresh_token.value, access: access_token } if refresh_token && access_token
    else
      destroy_old_token(user_id)
    end

    nil
  end

  def self.destroy_old_token(user_id)
    private
    old_token = find_by(user_id: user_id)
    old_token&.destroy
  end

  def self.refresh(user_id)
    private
    RefreshToken.create(user_id: user_id) if destroy_old_token(user_id)
  end
end