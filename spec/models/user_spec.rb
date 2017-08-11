require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create :user }
  let(:unconfirmed_user) { create :unconfirmed_user }
  let(:new_user) { build :user }
  let(:old_user) { build :user, confirmation_sent_at: 3.hours.ago }

  it 'is valid with valid attributes' do
    expect(new_user).to be_valid
    expect(unconfirmed_user).to be_valid
  end

  context 'email' do
    let(:existing_user) { create :user, email: Faker::Internet.email.downcase }
    let(:new_user) { build :user, email: existing_user.email.upcase }
    let(:user_without_email) {build :unconfirmed_user, email: nil}
    let(:user_with_improper_format) {build :unconfirmed_user, email: 'user.com'}

    it 'should validate presence' do
      expect(user_without_email).to_not be_valid
      expect(user_without_email.errors[:email]).to include('is invalid')
    end

    it 'should validate format' do
      expect(user_with_improper_format).to_not be_valid
      expect(user_with_improper_format.errors.messages[:email]).to include('is invalid')
    end

    it 'is unique disregarding case' do
      expect(new_user).not_to be_valid
      expect(new_user.errors[:email]).to include('has already been taken')
    end

    context 'confirmation token' do
      let(:unconfirmed_user) { create :unconfirmed_user }

      it 'is generated on user creation and is valid' do
        expect(user.confirmation_token).not_to be_nil
        expect(user.confirmation_token_valid?).to be true
      end

      it 'is invalid if it is more than 3 hours old' do
        expect(old_user.confirmation_token_valid?).to be false
      end

      it 'is cleared when email address is confirmed' do
        unconfirmed_user.mark_as_confirmed!
        expect(unconfirmed_user.confirmation_token).to be_nil
        expect(unconfirmed_user.confirmed_at.to_i).to eq(Time.now.utc.to_i)
      end
    end

    context 'update' do
      let(:new_email) { Faker::Internet.email }
      let(:update_new_email) { user.update_new_email!(new_email) }
      let(:confirm_new_email) { user.confirm_new_email! }

      it 'sets the new email address to unconfirmed_email' do
        update_new_email
        expect(user.unconfirmed_email).to eq(new_email)
      end

      it 'generates a new confirmation token' do
        old_token = user.confirmation_token
        update_new_email
        expect(user.confirmation_token).to_not eq(old_token)
        expect(user.confirmation_token).to_not be_nil
      end

      context 'conflicts' do
        let(:email) { Faker::Internet.email }
        let(:new_unconfirmed_user) { create :unconfirmed_user }
        let(:confirmed_user) { create :user, email: email }
        let(:unconfirmed_valid_token_user)   { create :unconfirmed_user, unconfirmed_email: email }
        let(:unconfirmed_invalid_token_user) { create :unconfirmed_user, unconfirmed_email: email }
        let(:update_new_email) { new_unconfirmed_user.update_new_email!(email) }

        it 'fails if another user is already using the confirmed email' do
          confirmed_user
          new_unconfirmed_user
          expect(update_new_email).to eq(false)
        end

        it 'fails if another user has the email as an unconfirmed_email, but the token is still valid' do
          unconfirmed_valid_token_user
          expect(update_new_email).to eq(false)
        end

        it 'succeeds if another user has the email as an unconfirmed_email, but the token is invalid' do
          # The before_create callback on User generates a confirmation token and will overwrite anything you set in let()
          # so the token always starts as valid by default
          unconfirmed_invalid_token_user
          unconfirmed_invalid_token_user.update_attribute(:confirmation_sent_at, 4.hours.ago.utc)
          new_unconfirmed_user
          update_new_email
          expect(new_unconfirmed_user.save).to eq(true)
        end
      end

      context 'and confirm new email' do

        it 'sets the new email address to unconfirmed_email' do
          update_new_email
          unconfirmed_email = user.unconfirmed_email
          confirm_new_email
          expect(user.email).to eq(unconfirmed_email)
        end

        it 'destroys the unconfirmed_email value' do
          update_new_email
          confirm_new_email
          expect(user.unconfirmed_email).to be_nil
        end

        it 'generates a new confirmation token' do
          old_token = user.confirmation_token
          update_new_email
          expect(user.confirmation_token).to_not eq(old_token)
          expect(user.confirmation_token).to_not be_nil
        end
      end
    end
  end

  context 'username' do
    let(:existing_user) {create :user, username: Faker::Internet.user_name(5..25).downcase }
    let(:new_user) { build :unconfirmed_user, username: existing_user.username.upcase }
    let(:user_without_username) { build :unconfirmed_user, username: nil }
    let(:user_with_same_username) { build :unconfirmed_user, username: existing_user.username }

    it 'should validate presence' do
      expect(user_without_username).to_not be_valid
      expect(user_without_username.errors[:username]).to include('can\'t be blank')
    end

    it 'should validate uniqueness' do
      expect(user_without_username).to_not be_valid
      expect(user_without_username.errors[:username]).to include('can\'t be blank')
    end

    it 'is unique disregarding case' do
      expect(user_with_same_username).not_to be_valid
      expect(user_with_same_username.errors[:username]).to include('has already been taken')
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