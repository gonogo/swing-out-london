# frozen_string_literal: true

require "faker"

FactoryBot.define do
  factory :event, aliases: %i[social intermittent_social] do
    title { Faker::Company.social_dance }
    has_taster { false }
    has_class { false }
    has_social { true }
    frequency { 0 }
    url { Faker::Internet.url }

    venue

    transient do
      dates { [] }
      cancellations { [] }
    end

    after(:create) do |event, evaluator|
      evaluator.dates.each do |date|
        create(:events_swing_date, event:, swing_date: build(:swing_date, date:))
      end
      evaluator.cancellations.each do |date|
        create(:events_swing_cancellation, event:, swing_date: build(:swing_date, date:))
      end
    end

    factory :class, class: "Event" do
      title { "" }
      has_class { true }
      has_social { false }
      weekly
      class_organiser factory: :organiser
    end

    factory :weekly_social do
      weekly

      trait :with_class do
        has_class { true }
        class_organiser factory: :organiser
      end
    end
  end

  trait :weekly do
    frequency { 1 }
    sequence(:day) { |wd| Date::DAYNAMES[wd % 7] }
  end

  trait :occasional do
    frequency { 0 }
  end

  factory :venue do
    name { "test_venue" }
    area { "test_area" }
    address { "London" }
    lat { 0.0 }
    lng { 0.0 }
    website { "http://www.example.com" }
  end

  factory :organiser do
    name { Faker::Name.lindy_hop_name }
  end

  factory :swing_date do
    date { Date.new }
  end

  factory :events_swing_date do
    event
    swing_date
  end

  factory :events_swing_cancellation do
    event
    swing_date
  end

  factory :event_instance do
    event
    date { rand(365).days.from_now }
  end

  trait :event_form do
    title { Faker::Company.social_dance }
    event_type { "social_dance" }
    frequency { 0 }
    url { Faker::Internet.url }
    venue_id { rand(999) }
  end

  factory :create_event_form do
    event_form
  end

  factory :edit_event_form do
    event_form
  end

  factory :organiser_edit_event_form do
    venue_id { rand(999) }
  end
end
