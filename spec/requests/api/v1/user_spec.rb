require 'rails_helper'
require 'jwt'

RSpec.describe 'V1 User API', :type => :request do

  headers = {
      'Content-Type' => 'application/json',
      'accept' => 'version=1'
  }

  describe 'creating a user' do

    it 'should succeed' do
      params = {
          user: {
              first_name: Faker::Name.first_name,
              last_name: Faker::Name.last_name,
              username: Faker::Internet.user_name + "_#{rand(1000)}",
              email: Faker::Internet.email,
              password: 'password',
              password_confirmation: 'password'
          }
      }.to_json

      post '/users', params: params, headers: headers
      expect(response.content_type).to eq('application/json')
      expect(response).to be_success
    end

    it 'should fail if the request is not versioned' do
      unversioned_headers = { 'Content-Type' => 'application/json' }

      params = {
          user: {
              first_name: Faker::Name.first_name,
              last_name: Faker::Name.last_name,
              username: Faker::Internet.user_name + "_#{rand(1000)}",
              email: Faker::Internet.email,
              password: 'password',
              password_confirmation: 'password'
          }
      }.to_json

      expect { post '/users', params: params, headers: unversioned_headers }.to raise_error(ActionController::RoutingError)
    end

    it 'should fail if username is not unique disregarding case' do
      existing_user = create :user, username: Faker::Internet.user_name(5..25).downcase

      params = {
          user: {
              first_name: Faker::Name.first_name,
              last_name: Faker::Name.last_name,
              username: existing_user.username.upcase,
              email: Faker::Internet.email,
              password: 'password',
              password_confirmation: 'password'
          }
      }.to_json

      post '/users', params: params, headers: headers
      expect(response.status).to eq(400)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to eq('{"errors":["Username has already been taken"]}')
    end

    it 'should fail if email is not unique disregarding case' do
      existing_user = create :user, email: Faker::Internet.email.downcase

      params = {
          user: {
              first_name: Faker::Name.first_name,
              last_name: Faker::Name.last_name,
              username:  Faker::Internet.user_name + "_#{rand(1000)}",
              email: existing_user.email.upcase,
              password: 'password',
              password_confirmation: 'password'
          }
      }.to_json

      post '/users', params: params, headers: headers
      expect(response.status).to eq(400)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to eq('{"errors":["Email has already been taken"]}')
    end

    it 'should fail if passwords do not match' do
      params = {
          user: {
              first_name: Faker::Name.first_name,
              last_name: Faker::Name.last_name,
              username:  Faker::Internet.user_name + "_#{rand(1000)}",
              email: Faker::Internet.email,
              password: 'password',
              password_confirmation: 'password1'
          }
      }.to_json

      post '/users', params: params, headers: headers
      expect(response.status).to eq(400)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to eq('{"errors":["Passwords do not match"]}')
    end
  end

  describe 'logging in a user' do

    it 'should successfully log in' do
      password = Faker::Internet.password(8)
      new_user = create :user,
                        email: Faker::Internet.email,
                        username: Faker::Internet.user_name(5..25),
                        password: password,
                        password_confirmation: password,
                        confirmed_at: Time.now

      params = {
        email: new_user.email,
        password: new_user.password,
      }.to_json

    post '/users/login', params: params, headers: headers
    expect(response).to be_success
    expect(response.content_type).to eq('application/json')
    expect(response.body).to include('auth_token')
    end

    it 'should fail if the request is not versioned' do
      unversioned_headers = { 'Content-Type' => 'application/json' }

      password = Faker::Internet.password(8)
      new_user = create :user,
                        email: Faker::Internet.email,
                        username: Faker::Internet.user_name(5..25),
                        password: password,
                        password_confirmation: password,
                        confirmed_at: Time.now

      params = {
          email: new_user.email,
          password: new_user.password,
      }.to_json

      expect { post '/users/login', params: params, headers: unversioned_headers }.to raise_error(ActionController::RoutingError)
    end

    it 'should fail if password is incorrect and is case sensitive' do
      password = Faker::Internet.password(8).downcase
      new_user = create :user,
                        email: Faker::Internet.email,
                        username: Faker::Internet.user_name(5..25),
                        password: password,
                        password_confirmation: password,
                        confirmed_at: Time.now

      params = {
          email: new_user.email,
          password: new_user.password.upcase,
      }.to_json

      post '/users/login', params: params, headers: headers
      expect(response.status).to eq(401)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to eq('{"errors":["Invalid username / password"]}')
    end
  end

  describe 'email update request' do

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
          email: Faker::Internet.email + rand(1000).to_s,
      }.to_json

      patch '/users/email_update', params: params, headers: authenticated_headers

      expect(response).to be_success
      expect(response.content_type).to eq('application/json')
      expect(response.body).to eq('{"status":["Email Confirmation has been sent to your new Email"]}')
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

      unversioned_headers = {
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{auth_token}"
      }

      params = {
          email: Faker::Internet.email + rand(1000).to_s,
      }.to_json

      expect {  patch '/users/email_update', params: params, headers: unversioned_headers }.to raise_error(ActionController::RoutingError)
    end

    it 'should fail if unauthenticated' do
      params = {
          email: Faker::Internet.email + rand(1000).to_s,
      }.to_json

      patch '/users/email_update', params: params, headers: headers
      expect(response.status).to eq(401)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to eq('{"errors":["Invalid Request"]}')
    end

    it 'should fail if auth token is expired' do
      user = create(:user)

      auth_token = JWT.encode(
          {
              user_id: user.id,
              exp: 7.days.ago.to_i,
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
          email: Faker::Internet.email + rand(1000).to_s,
      }.to_json

      patch '/users/email_update', params: params, headers: authenticated_headers
      expect(response.status).to eq(401)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to eq('{"errors":["Invalid Request"]}')
    end

    it 'should fail if email is already taken' do
      @users = create_list(:user,2)
      auth_token = JWT.encode(
          {
              user_id: @users.last.id,
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
          email: @users.first.email,
      }.to_json

      patch '/users/email_update', params: params, headers: authenticated_headers

      expect(response.status).to eq(422)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to eq('{"errors":["Email is already in use"]}')
    end

    it 'should fail if email is blank' do
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
          email: nil,
      }.to_json

      patch '/users/email_update', params: params, headers: authenticated_headers

      expect(response.status).to eq(400)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to eq('{"errors":["Email cannot be blank"]}')
    end

    it 'should fail if new email is the same as current email' do
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
          email: user.email,
      }.to_json

      patch '/users/email_update', params: params, headers: authenticated_headers

      expect(response.status).to eq(400)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to eq('{"errors":["Current Email and New email cannot be the same"]}')
    end

    it 'should fail if new email format is invalid' do
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
          email: 'invalid.email',
      }.to_json

      patch '/users/email_update', params: params, headers: authenticated_headers

      expect(response.status).to eq(400)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to eq('{"errors":["Email is invalid"]}')
    end

  end
end