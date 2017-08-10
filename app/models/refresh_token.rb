require 'json_web_token'

class RefreshToken < ApplicationRecord
  belongs_to :user

  def self.validate_and_refresh(token)
    begin
      payload = JsonWebToken.decode(token)[0]
    rescue => error
      puts error
      old_token = self.find_by_value(token)
      old_token.destroy if old_token
      return nil
    end

    if payload &&  self.find_by_value(token) && JsonWebToken.valid_payload(payload, 'refresh')
      user_id = payload['user_id']
      refresh_token = self.refresh(user_id)
      access_token = JsonWebToken.encode({user_id: user_id}, 'access')

      if refresh_token && access_token
        return {
            refresh: refresh_token.value,
            access: access_token
        }
      end
    end
  end

  private

  def self.create_refresh_token(user_id)
    self.create(
        user_id: user_id,
        value: JsonWebToken.encode({user_id: user_id}, 'refresh')
    )
  end

  def self.destroy_old_token(user_id)
    old_token = self.find_by(user_id: user_id)
    old_token.destroy if old_token
  end

  def self.refresh(user_id)
    destroy_old_token(user_id)
    create_refresh_token(user_id)
  end

end