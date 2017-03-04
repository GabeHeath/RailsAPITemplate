require 'rails_helper'

RSpec.describe 'User API', :type => :request do
  describe 'confirm email' do
    it 'should successfully confirm new email address' do
      user = create(:unconfirmed_user)
      get "/users/confirm/#{user.confirmation_token}"
      expect(response).to be_success
      expect(response.content_type).to eq('application/json')
      expect(response.body).to eq('{"status":"User confirmed successfully"}')
    end

    it 'should fail if token does not exist' do
      get '/users/confirm/invalid_token'
      expect(response.status).to eq(400)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to eq('{"errors":["Invalid token"]}')
    end
  end

  describe 'update email' do
    it 'should successfully update new email address' do
      user = create(:unconfirmed_user)
      user.update_attributes(unconfirmed_email: Faker::Internet.email + rand(1000).to_s )
      get "/users/email_update/#{user.confirmation_token}"
      expect(response).to be_success
      expect(response.content_type).to eq('application/json')
      expect(response.body).to eq('{"status":"Email updated successfully"}')
    end

    it 'should fail if token does not exist' do
      user = create(:unconfirmed_user)
      user.update_attributes(unconfirmed_email: Faker::Internet.email + rand(1000).to_s )
      get '/users/email_update/invalid_token'
      expect(response.status).to eq(400)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to eq('{"errors":["The email link seems to be invalid / expired. Try requesting for a new one."]}')
    end

    it 'should fail if token is expired' do
      user = create(:unconfirmed_user)
      user.update_attributes(unconfirmed_email: Faker::Internet.email + rand(1000).to_s, confirmation_sent_at: 1.week.ago )
      get "/users/email_update/#{user.confirmation_token}"
      expect(response.status).to eq(400)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to eq('{"errors":["The email link seems to be invalid / expired. Try requesting for a new one."]}')
    end
  end
end