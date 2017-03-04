require 'rails_helper'
require 'jwt'

RSpec.describe 'V1 Password API', :type => :request do

  describe 'update password' do
    it 'should succeed' do
      user = create(:user)

      auth_token = JWT.encode(
          {
              user_id: user.id,
              exp: 7.days.from_now.to_i,
              iss: 'issuer_name',
              aud: 'client',
          },
          Rails.application.secrets.secret_key_base)

      authenticated_headers = {
          'Content-Type' => 'application/json',
          'accept' => 'version=1',
          'Authorization' => "Bearer #{auth_token}"
      }
      params = {
          current_password: user.password,
          password: 'new_password',
          password_confirmation: 'new_password'
      }.to_json

      patch '/password/update', params: params, headers: authenticated_headers
      expect(response).to be_success
      expect(response.content_type).to eq('application/json')
      expect(response.body).to eq('{"status":"ok"}')
    end

    it 'should fail if request is not authenticated' do
      user = create(:user)

      headers = {
          'Content-Type' => 'application/json',
          'accept' => 'version=1'
      }
      params = {
          current_password: user.password,
          password: 'new_password',
          password_confirmation: 'new_password'
      }.to_json

      patch '/password/update', params: params, headers: headers
      expect(response.status).to eq(401)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to eq('{"errors":["Invalid Request"]}')
    end
  end

  it 'should fail if the request is not versioned' do
    user = create(:user)

    auth_token = JWT.encode(
        {
            user_id: user.id,
            exp: 7.days.from_now.to_i,
            iss: 'issuer_name',
            aud: 'client',
        },
        Rails.application.secrets.secret_key_base)

    authenticated_headers = {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{auth_token}"
    }
    params = {
        current_password: user.password,
        password: 'new_password',
        password_confirmation: 'new_password'
    }.to_json


    expect {patch '/password/update', params: params, headers: authenticated_headers}.to raise_error(ActionController::RoutingError)
  end

  it 'should fail if password is shorter than 8 characters or blank' do
    user = create(:user)

    auth_token = JWT.encode(
        {
            user_id: user.id,
            exp: 7.days.from_now.to_i,
            iss: 'issuer_name',
            aud: 'client',
        },
        Rails.application.secrets.secret_key_base)

    authenticated_headers = {
        'Content-Type' => 'application/json',
        'accept' => 'version=1',
        'Authorization' => "Bearer #{auth_token}"
    }
    params = {
        current_password: user.password,
        password: 'seven77',
        password_confirmation: 'seven77'
    }.to_json

    patch '/password/update', params: params, headers: authenticated_headers
    expect(response.status).to eq(422)
    expect(response.content_type).to eq('application/json')
    expect(response.body).to eq('{"errors":["Password must be a minimum of 8 characters"]}')
  end

  it 'should fail if password and password_confirmation do not match and is case sensitive' do
    user = create(:user)

    auth_token = JWT.encode(
        {
            user_id: user.id,
            exp: 7.days.from_now.to_i,
            iss: 'issuer_name',
            aud: 'client',
        },
        Rails.application.secrets.secret_key_base)

    authenticated_headers = {
        'Content-Type' => 'application/json',
        'accept' => 'version=1',
        'Authorization' => "Bearer #{auth_token}"
    }
    params = {
        current_password: user.password,
        password: 'password',
        password_confirmation: 'password'.upcase
    }.to_json

    patch '/password/update', params: params, headers: authenticated_headers
    expect(response.status).to eq(422)
    expect(response.content_type).to eq('application/json')
    expect(response.body).to eq('{"errors":["Password confirmation doesn\'t match Password"]}')
  end

  it 'should fail if current password is incorrect and is case sensitive' do
    user = create(:user)

    auth_token = JWT.encode(
        {
            user_id: user.id,
            exp: 7.days.from_now.to_i,
            iss: 'issuer_name',
            aud: 'client',
        },
        Rails.application.secrets.secret_key_base)

    authenticated_headers = {
        'Content-Type' => 'application/json',
        'accept' => 'version=1',
        'Authorization' => "Bearer #{auth_token}"
    }
    params = {
        current_password: user.email.upcase,
        password: 'password',
        password_confirmation: 'password'
    }.to_json

    patch '/password/update', params: params, headers: authenticated_headers
    expect(response.status).to eq(422)
    expect(response.content_type).to eq('application/json')
    expect(response.body).to eq('{"errors":["Invalid current password"]}')
  end

end