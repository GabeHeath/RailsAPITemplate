require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { build :user }
  it 'is valid with valid attributes' do
    expect(user).to be_valid
  end

  context 'email' do
    let(:existing_user) { create :user, email: Faker::Internet.email.downcase }
    let(:new_user) { build :user, email: existing_user.email.upcase }

    it { should validate_presence_of(:email) }

    it 'is unique disregarding case' do
      expect(new_user).not_to be_valid
      expect(new_user.errors[:email]).to include('has already been taken')
    end
  end

  context 'username' do
    let(:existing_user) {create :user, username: Faker::Internet.user_name(5..25).downcase }
    let(:new_user) { build :user, username: existing_user.username.upcase }

    it { should validate_uniqueness_of(:email) }

    it 'is unique disregarding case' do
      expect(new_user).not_to be_valid
      expect(new_user.errors[:username]).to include('has already been taken')
    end
  end

  context 'password' do
    let(:short_password) { Faker::Internet.password(1, 7) }
    let(:long_password)  { Faker::Internet.password(41, 100) }
    let(:valid_password_1) { Faker::Internet.password(8, 20) }
    let(:valid_password_2) { Faker::Internet.password(21, 40) }
    let(:long_pw_user)  { build :user, password: long_password, password_confirmation: long_password }
    let(:short_pw_user) { build :user, password: short_password, password_confirmation: short_password }
    let(:mismatching_pw_user) { build :user, password: valid_password_1, password_confirmation: valid_password_2 }

    it { should have_secure_password }

    it 'is not exceeding 40 characters' do
      expect(long_pw_user).not_to be_valid
      expect(long_pw_user.errors[:password]).to include('is too long (maximum is 40 characters)')
    end

    it 'is not shorter than 8 characters' do
      expect(short_pw_user).not_to be_valid
      expect(short_pw_user.errors[:password]).to include('is too short (minimum is 8 characters)')
    end

    it 'is not valid when passwords mismatch' do
      expect(mismatching_pw_user).not_to be_valid
      expect(mismatching_pw_user.errors.messages[:password_confirmation]).to include('doesn\'t match Password')
    end
  end
end