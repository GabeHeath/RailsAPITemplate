require 'jwt'

class JsonWebToken
  # Encodes and signs JWT Payload with expiration
  def self.encode(payload, token_type)
    token_data = token_defaults(token_type)
    payload.reverse_merge!(token_data)
    JWT.encode(payload, Rails.application.secrets.secret_key_base)
  end

  # Decodes the JWT with the signed secret
  def self.decode(token)
    JWT.decode(token, Rails.application.secrets.secret_key_base)
  end

  # Validates the payload hash for expiration and meta claims
  def self.valid_payload(payload, token_type)
    token_data = token_defaults(token_type)
    if expired(payload) || payload['iss'] != token_data[:iss] || payload['aud'] != token_data[:aud]
      return false
    else
      return true
    end
  end

  # Default options to be encoded in the access token
  def self.access_token_data
    {
      expire_at: 1.hour.from_now,
      expire_in: 3600, # 1 hour
      iss: 'issuer_name',
      aud: 'client',
    }
  end

  # Default options to be encoded in the refresh token
  def self.refresh_token_data
    {
        expire_at: 14.days.from_now,
        expire_in: 1209600, #14 days
        iss: 'issuer_name',
        aud: 'client',
    }
  end

  # Validates if the token is expired by expire_at parameter
  def self.expired(payload)
    Time.at(payload['expire_at']) < Time.now
  end

  def self.token_defaults(token_type)
    token_type == 'access' ? access_token_data : refresh_token_data
  end
end
