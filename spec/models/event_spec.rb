# frozen_string_literal: true

require "rails_helper"
require "support/shoulda_matchers"
require "spec/support/shared_examples/events/validates_class_and_social"
require "spec/support/shared_examples/events/validates_weekly"
require "spec/support/shared_examples/events/validates_event_with_dates"
require "spec/support/shared_examples/events/validates_course_length"
require "spec/support/shared_examples/validates_url"

RSpec.describe Event do
  describe "(associations)" do
    it { is_expected.to have_many(:event_instances).dependent(:destroy) }
  end

  describe "#title" do
    it "strips whitespace before saving" do
      event = build(:event, title: " \tDance time! ")

      event.valid?

      expect(event.title).to eq("Dance time!")
    end
  end

  describe "#url" do
    it "strips whitespace before saving" do
      event = build(:event, url: " \thttps://dancetime.co.uk ")

      event.valid?

      expect(event.url).to eq("https://dancetime.co.uk")
    end
  end

  describe ".dates" do
    it "returns an ordered list of dates" do
      recent_date = create(:swing_date, date: Time.zone.today)
      old_date = create(:swing_date, date: Time.zone.today - 1.year)

      event = create(:event)
      event.swing_dates << recent_date
      event.swing_dates << old_date
      event.save!

      expect(event.reload.dates).to eq([Time.zone.today - 1.year, Time.zone.today])
    end
  end

  describe ".socials_on_date" do
    it "returns intermittent socials on a given date" do
      date = Date.current
      social = create(:intermittent_social, dates: [date])

      socials = described_class.socials_on_date(date)

      expect(socials).to eq [social]
    end

    it "returns weekly socials on the same day as a given date" do
      date = Date.current.next_occurring(:thursday)
      social = create(:weekly_social, day: "Thursday")

      socials = described_class.socials_on_date(date)

      expect(socials).to eq [social]
    end

    it "returns nil if there are no socials on that date" do
      date = Date.current

      socials = described_class.socials_on_date(date)

      expect(socials).to be_empty
    end
  end

  describe "active.classes" do
    it "returns classes with no 'last date'" do
      event = create(:class, last_date: nil)
      expect(described_class.active.classes).to eq([event])
    end

    it "does not return classes with a 'last date' in the past" do
      create(:class, last_date: Time.zone.today - 1)
      expect(described_class.active.classes).to eq([])
    end

    it "does not return non-classes" do
      create(:event, last_date: nil, has_class: "false")
      create(:event, last_date: nil, has_taster: "true")

      expect(described_class.active.classes).to eq([])
    end

    it "returns the correct list of classes" do # rubocop:disable RSpec/ExampleLength
      create(:social, last_date: nil)
      create(:class, last_date: Time.zone.today - 5)
      returned = [
        create(:class),
        create(:class, last_date: nil),
        create(:class, last_date: Time.zone.today + 1)
      ]
      create(:social)
      create(:event, has_class: "false", has_taster: "true")

      aggregate_failures do
        expect(described_class.active.classes.length).to eq(returned.length)
        expect(returned).to include(described_class.active.classes[0])
        expect(returned).to include(described_class.active.classes[1])
        expect(returned).to include(described_class.active.classes[2])
      end
    end
  end

  describe "(validations)" do
    subject { build(:event) }

    it_behaves_like "validates class and social", :event
    it_behaves_like "validates weekly", :event
    it_behaves_like "validates event with dates", :event
    it_behaves_like "validates course length", :event
    it_behaves_like "validates url", :event

    it "is invalid with no venue" do
      event = build(:event, venue_id: nil)
      event.valid?
      expect(event.errors.messages).to eq(venue: ["must exist"])
    end

    it { is_expected.to validate_presence_of(:frequency) }
    it { is_expected.to validate_presence_of(:url) }

    it { is_expected.to validate_uniqueness_of(:organiser_token).allow_nil }
  end

  describe "#future_dates?" do
    context "when the event has no dates" do
      it "is false" do
        event = create(:event, dates: [])

        expect(event.future_dates?).to be false
      end
    end

    context "when the event has one date which is today" do
      it "is true" do
        event = create(:event, dates: [Time.zone.today])

        expect(event.future_dates?).to be false
      end
    end

    context "when the event has one date in the future" do
      it "is true" do
        event = create(:event, dates: [Time.zone.today + 1])

        expect(event.future_dates?).to be true
      end
    end

    context "when the event has one date in the past" do
      it "is false" do
        event = create(:event, dates: [Time.zone.today - 2])

        expect(event.future_dates?).to be false
      end
    end

    context "when the event is weekly" do
      it "is true" do
        event = create(:weekly_social)

        expect(event.future_dates?).to be true
      end
    end

    context "when the event has an end date" do
      it "is true" do
        event = create(:event, dates: [], last_date: (Time.zone.today + 1.year))

        expect(event.future_dates?).to be false
      end
    end
  end

  describe "ended?" do
    it "is always false if there is no last date" do
      events = [
        build(:event, dates: ["March 12 1926".to_date], last_date: nil),
        build(:event, dates: [Date.current.tomorrow], last_date: nil),
        build(:event, dates: [], last_date: nil)
      ]
      expect(events).not_to include(be_ended)
    end

    it "is true if there is a last date in the past" do
      events = [
        build(:event, dates: ["March 12 1926".to_date], last_date: "October 1st 1958".to_date),
        build(:event, dates: [Date.current.tomorrow], last_date: "October 1st 1958".to_date),
        build(:event, dates: [], last_date: "October 1st 1958".to_date)
      ]
      expect(events).to all(be_ended)
    end

    it "is false if there is a last date in the future" do
      events = [
        build(:event, dates: ["March 12 1926".to_date], last_date: Date.current.tomorrow),
        build(:event, dates: [Date.current.tomorrow], last_date: Date.current.tomorrow),
        build(:event, dates: [], last_date: Date.current.tomorrow)
      ]
      expect(events).not_to include(be_ended)
    end
  end
end
