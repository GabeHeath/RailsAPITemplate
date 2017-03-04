require 'rails_helper'

RSpec.describe 'V1 Users Controller', :type => :controller do
  describe 'confirm a user via email link' do
    #TODO
  end

  describe 'creating a user should generate a confirmation_token and unconfirmed_email' do
    #TODO
  end

  describe 'confirming a user should make confirmation_token and unconfirmed_email nil while setting confirmed_at and updating email' do
    #TODO
  end
end