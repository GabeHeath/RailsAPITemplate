require 'rails_helper'
require 'jwt'

RSpec.describe 'V1 Password API', :type => :request do
  let(:user) { create :user }
  let(:auth_token) { JWT.encode({ user_id: user.id, exp: 6.minutes.from_now.to_i, iss: 'issuer_name', aud: 'client' }, Rails.application.secrets.secret_key_base) }
  let(:authenticated_headers) { {'Content-Type': 'application/json', 'accept': 'version=1', 'Authorization': "Bearer #{auth_token}"} }
  let(:unversioned_authenticated_headers) { {'Content-Type': 'application/json', 'Authorization': "Bearer #{auth_token}"} }
  let(:unauthenticated_headers) { {'Content-Type': 'application/json', 'accept': 'version=1'} }
  let(:params) { { current_password: user.password, password: 'new_password', password_confirmation: 'new_password' }.to_json }
  let(:short_password_params) { { current_password: user.password, password: '1234567', password_confirmation: '1234567' }.to_json }
  let(:long_password) {Faker::Internet.password(41)}
  let(:long_password_params) { { current_password: user.password, password: long_password, password_confirmation: long_password }.to_json }
  let(:nil_password_params) { { current_password: user.password, password: nil, password_confirmation: nil }.to_json }
  let(:mismatch_password_params) { { current_password: user.password, password: 'password', password_confirmation: 'password'.upcase }.to_json }
  let(:incorrect_password_params) { { current_password: user.email.upcase, password: 'password', password_confirmation: 'password' }.to_json }

  describe 'update password' do

    it 'should succeed' do
      patch '/password/update', params: params, headers: authenticated_headers
      expect(response).to be_success
      expect(response.content_type).to eq('application/json')
      expect(response.body).to eq('{"status":"ok"}')
    end

    it 'should fail if request is not authenticated' do
      patch '/password/update', params: params, headers: unauthenticated_headers
      expect(response.status).to eq(401)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to eq('{"errors":["Invalid Request"]}')
    end
  end

  it 'should fail if the request is not versioned' do
    expect {patch '/password/update', params: params, headers: unversioned_authenticated_headers}.to raise_error(ActionController::RoutingError)
  end

  it 'should fail if password is shorter than 8 characters' do
    patch '/password/update', params: short_password_params, headers: authenticated_headers
    expect(response.status).to eq(422)
    expect(response.content_type).to eq('application/json')
    expect(response.body).to eq('{"errors":["Password is too short (minimum is 8 characters)"]}')
  end

  it 'should fail if password is more than 40 characters' do
    patch '/password/update', params: long_password_params, headers: authenticated_headers
    expect(response.status).to eq(422)
    expect(response.content_type).to eq('application/json')
    expect(response.body).to eq('{"errors":["Password is too long (maximum is 40 characters)"]}')
  end

  it 'should fail if password is nil' do
    patch '/password/update', params: nil_password_params, headers: authenticated_headers
    expect(response.status).to eq(422)
    expect(response.content_type).to eq('application/json')
    expect(response.body).to include('Password can\'t be blank')
  end

  it 'should fail if password and password_confirmation do not match and is case sensitive' do
    patch '/password/update', params: mismatch_password_params, headers: authenticated_headers
    expect(response.status).to eq(422)
    expect(response.content_type).to eq('application/json')
    expect(response.body).to eq('{"errors":["Password confirmation doesn\'t match Password"]}')
  end

  it 'should fail if current password is incorrect and is case sensitive' do
    patch '/password/update', params: incorrect_password_params, headers: authenticated_headers
    expect(response.status).to eq(422)
    expect(response.content_type).to eq('application/json')
    expect(response.body).to eq('{"errors":["Invalid current password"]}')
  end

end