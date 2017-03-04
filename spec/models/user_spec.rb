require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'responsibilities' do
    it { should validate_presence_of(:email) }

    it 'email must be unique disregarding case' do
      existing_user = create :user, email: Faker::Internet.email.downcase
      new_user = build :user, email: existing_user.email.upcase
      expect(new_user).not_to be_valid
      expect(new_user.errors[:email]).to include('has already been taken')
    end

    it 'username must be unique disregarding case' do
      existing_user = create :user, username: Faker::Internet.user_name(5..25).downcase
      new_user = build :user, username: existing_user.username.upcase
      expect(new_user).not_to be_valid
      expect(new_user.errors[:username]).to include('has already been taken')
    end

    it { should have_secure_password }

  end
end