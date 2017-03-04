FactoryGirl.define do
  factory :build do
    name          { Faker::Name.first_name }
    support_level { ['active','deprecated','unsupported'].sample }
  end
end