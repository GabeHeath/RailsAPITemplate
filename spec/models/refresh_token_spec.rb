require 'rails_helper'

RSpec.describe RefreshToken, type: :model do
  let(:user) { create :user }

  context 'creates' do
    it 'a token for a user' do
      expect(user.refresh_token).to_not be_nil
      expect(user.refresh_token.value.length).to be > 40
    end
  end

  context 'refresh' do
    it 'returns a hash of tokens' do
      refresh = RefreshToken.validate_and_refresh(user.refresh_token.value)
      expect(refresh).to be_a_kind_of(Hash)
      expect(refresh).to include(:refresh)
      expect(refresh).to include(:access)
      expect(refresh[:refresh]).to_not be_nil
      expect(refresh[:access]).to_not be_nil
    end

    it 'generates a new token when given an existing token' do
      old_token = user.refresh_token.value
      sleep 1 # Because test happens so fast the jwt payload is identical if you don't let some time pass
      refresh = RefreshToken.validate_and_refresh(user.refresh_token.value)
      new_token = User.find(user.id).refresh_token.value

      expect(refresh).to_not be_nil
      expect(new_token).to_not be_nil
      expect(new_token).to_not eq(old_token)
    end

    it 'fails if given a non-existing token' do
      non_existent_token = 'this.token.does.not.exist'
      old_token = user.refresh_token.value
      RefreshToken.validate_and_refresh(non_existent_token)
      expect(user.refresh_token.value).to_not be_nil
      expect(user.refresh_token.value).to eq(old_token)
    end
  end

  context 'validate' do
    let(:expired_refresh_token)    { JsonWebToken.encode({ user_id: user.id, exp: 6.minutes.ago.to_i, expire_in: 360, iss: 'issuer_name', aud: 'client' }, 'refresh') }
    let(:bad_issuer_refresh_token) { JsonWebToken.encode({ user_id: user.id, exp: 6.minutes.from_now.to_i, expire_in: 360, iss: 'bad_issuer', aud: 'client' }, 'refresh') }
    let(:bad_client_refresh_token) { JsonWebToken.encode({ user_id: user.id, exp: 6.minutes.from_now.to_i, expire_in: 360, iss: 'issuer_name', aud: 'bad_client' }, 'refresh') }

    it 'fails if payload is expired and destroys old token' do
      user.refresh_token.update_attribute(:value, expired_refresh_token)
      expect(user.refresh_token).to_not be_nil
      expect(RefreshToken.validate_and_refresh(expired_refresh_token)).to be_nil
      expect(User.find(user.id).refresh_token).to be_nil
    end

    it 'fails if payload issuer is invalid and destroys old token' do
      user.refresh_token.update_attribute(:value, bad_issuer_refresh_token)
      expect(user.refresh_token).to_not be_nil
      expect(RefreshToken.validate_and_refresh(bad_issuer_refresh_token)).to be_nil
      expect(User.find(user.id).refresh_token).to be_nil
    end

    it 'fails if payload client is invalid and destroys old token' do
      user.refresh_token.update_attribute(:value, bad_client_refresh_token)
      expect(user.refresh_token).to_not be_nil
      expect(RefreshToken.validate_and_refresh(bad_client_refresh_token)).to be_nil
      expect(User.find(user.id).refresh_token).to be_nil
    end

    it 'destroys old token if payload can\'t be decoded and destroy old token' do
      invalid_signature = 'TJVA95OrM7E2cBab30RMHrHDcEfxjoYZgeFONFh7HgQ'
      invalidated_signature_token = user.refresh_token.value.rpartition('.').first + invalid_signature
      user.refresh_token.update_attribute(:value, invalidated_signature_token )
      expect(user.refresh_token.value).to include(invalid_signature)
      expect(RefreshToken.validate_and_refresh(invalidated_signature_token)).to be_nil
      expect(User.find(user.id).refresh_token).to be_nil
    end
  end

  context 'revoke' do
    it 'destroys the old token' do
      revoke = RefreshToken.revoke(user.refresh_token.value)
      expect(revoke).to be_a(RefreshToken)
      expect(User.find(user.id).refresh_token).to be_nil
    end

    it 'returns nil if token not found' do
      expect(RefreshToken.revoke('this.is.not.a.token')).to be_nil
    end
  end

  context 'destroy' do
    it 'removes the old token' do
      RefreshToken.destroy_old_token(user.id)
      expect(user.refresh_token).to be_nil
    end
  end

end