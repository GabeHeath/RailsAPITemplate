require 'json_web_token'

# This is the long-lived token used to refresh the client's access token.
class RefreshToken < ApplicationRecord
  belongs_to :user

  def self.revoke(token)
    token = find_by_value(token)
    return nil unless token
    token.destroy
  end

  def self.validate_and_refresh(token)
    begin
      payload = JsonWebToken.decode(token)[0]
    rescue => error
      puts error
      old_token = find_by_value(token)
      old_token&.destroy
      return nil
    end

    return nil unless payload && find_by_value(token) && JsonWebToken.valid_payload(payload, 'refresh')
    user_id = payload['user_id']
    refresh_token = refresh(user_id)
    access_token = JsonWebToken.encode({ user_id: user_id }, 'access')

    return nil unless refresh_token || access_token
    { refresh: refresh_token.value, access: access_token }
  end

  def self.create_refresh_token(user_id)
    private
    create(
      user_id: user_id,
      value: JsonWebToken.encode({ user_id: user_id }, 'refresh')
    )
  end

  def self.destroy_old_token(user_id)
    private
    old_token = find_by(user_id: user_id)
    old_token&.destroy
  end

  def self.refresh(user_id)
    private
    destroy_old_token(user_id)
    create_refresh_token(user_id)
  end
end