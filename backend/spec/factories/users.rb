FactoryBot.define do
  factory :user do
    name { "HR Manager" }
    sequence(:email) { |n| "hr-manager-#{n}@acme.test" }
    password { "correct-horse-battery-staple" }
  end
end
