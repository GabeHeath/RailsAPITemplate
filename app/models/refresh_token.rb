require 'json_web_token'

class RefreshToken < ApplicationRecord
  belongs_to :user

  def self.create_refresh_token(user_id)
    self.create(
        user_id: user_id,
        value: JsonWebToken.encode({user_id: user_id}, 'refresh')
    )
  end

  def self.refresh(token)
    payload = JsonWebToken.decode(token)[0]
    destroy_old_token(payload['user_id'], token)
    create_refresh_token(payload['user_id'])
  end

  private

  def self.destroy_old_token(user_id, value)
    self.find_by(user_id: user_id, value: value).destroy
  end

end