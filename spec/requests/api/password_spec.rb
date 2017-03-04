require 'rails_helper'

RSpec.describe 'Password API', :type => :request do

  headers = { 'Content-Type' => 'application/json' }

  describe 'forgot password' do
    it 'should return as a success' do
      existing_user = create :user

      params = { email: existing_user.email }.to_json

      patch '/password/forgot', params: params, headers: headers
      expect(response).to be_success
      expect(response.content_type).to eq('application/json')
      expect(response.body).to eq('{"status":"ok"}')
    end

    it 'should fail if email is blank' do
      params = { email: "" }.to_json

      patch '/password/forgot', params: params, headers: headers
      expect(response.status).to eq(401)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to eq('{"errors":["Email cannot be blank"]}')
    end

    it 'should fail if email is not found' do
      params = { email: Faker::Internet.email }.to_json

      patch '/password/forgot', params: params, headers: headers
      expect(response.status).to eq(401)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to eq('{"errors":["Email address not found. Please check and try again."]}')
    end
  end

  describe 'reset password with token' do
    it 'should succeed' do
      existing_user = create :user

      params = { email: existing_user.email }.to_json

      patch '/password/forgot', params: params, headers: headers
      expect(response).to be_success
      expect(response.content_type).to eq('application/json')
      expect(response.body).to eq('{"status":"ok"}')
    end
  end
end