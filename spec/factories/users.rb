FactoryGirl.define do
  factory :user do
    first_name            { Faker::Name.first_name }
    last_name             { Faker::Name.last_name }
    username              { Faker::Internet.user_name + "_#{rand(1000)}" }
    email                 { Faker::Internet.email }
    password              { 'password' }
    password_confirmation { 'password' }
    confirmed_at          { Time.now }
  end

  factory :unconfirmed_user, class: User do
    first_name            { Faker::Name.first_name }
    last_name             { Faker::Name.last_name }
    username              { Faker::Internet.user_name + "_#{rand(1000)}" }
    email                 { Faker::Internet.email }
    password              { 'password' }
    password_confirmation { 'password' }
  end
end