# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  has_one :refresh_token, dependent: :destroy

  validate :email_used?
  validates_format_of :email, with: /@/
  validates_format_of :unconfirmed_email, with: /@/, allow_nil: true

  validates_uniqueness_of :email, :username, case_sensitive: false
  validates_presence_of :username

  validates :password, length: { in: 8..40 }

  before_save :downcase_email
  before_create :generate_confirmation_token
  after_create :create_refresh_token

  def downcase_email
    self.email = email.delete(' ').downcase
  end

  def generate_confirmation_token
    self.confirmation_token = generate_token
    self.confirmation_sent_at = Time.now.utc
  end

  def confirmation_token_valid?
    (confirmation_sent_at + 3.hours) > Time.now.utc
  end

  def mark_as_confirmed!
    self.confirmation_token = nil
    self.confirmed_at = Time.now.utc
    save!
  end

  def generate_password_token!
    self.update_attributes(
        reset_password_token: generate_token,
        reset_password_sent_at: Time.now.utc
    )
  end

  def password_token_valid?
    (reset_password_sent_at + 20.minutes) > Time.now.utc
  end

  def reset_password!(password, confirmation)
    if update(password: password, password_confirmation: confirmation)
      self.reset_password_token = nil
      save
    else
      false
    end
  end

  def update_new_email!(email)
    self.unconfirmed_email = email
    generate_confirmation_token
    save
  end

  def confirm_new_email!
    self.email = unconfirmed_email
    self.unconfirmed_email = nil
    mark_as_confirmed!
    save
  end

  def email_used?
    existing_user = User.where('id <> ? AND email = ?', id, unconfirmed_email&.downcase)&.first
    waiting_for_confirmation = User.where('id <> ? AND unconfirmed_email = ?', id, unconfirmed_email&.downcase)&.first

    unless existing_user.nil?
      errors.add(:email, 'has already been taken') if existing_user
    end

    unless waiting_for_confirmation.nil?
      errors.add(:email, 'has already been taken') if waiting_for_confirmation.confirmation_token_valid? && waiting_for_confirmation.id != id
    end
  end

  private

  def generate_token
    SecureRandom.hex(10)
  end

  def create_refresh_token
    RefreshToken.create(user_id: id)
  end
end
