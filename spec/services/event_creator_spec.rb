# frozen_string_literal: true

require "rails_helper"

RSpec.describe EventCreator do
  describe "#create!" do
    it "builds an event with the passed in params, except dates and cancellations" do
      repository = class_double("Event", create!: double)
      other_value = double
      params = { dates: [], cancellations: [], frequency: 0, other: other_value }

      described_class.new(repository).create!(params)

      expect(repository).to have_received(:create!).with(
        { other: other_value, frequency: 0, event_instances: [], swing_dates: [], swing_cancellations: [] }
      )
    end

    it "returns the created event" do
      created_event = instance_double("Event")
      repository = class_double("Event", create!: created_event)
      venue = create(:venue)
      params = attributes_for(:event, :occasional, venue_id: venue.id)

      result = described_class.new(repository).create!(params)

      expect(result).to eq created_event
    end

    context "when there are dates" do
      it "creates SwingDate records from the dates" do
        date1 = Date.tomorrow
        date2 = 2.days.from_now.to_date
        venue = create(:venue)
        params = attributes_for(:event, :occasional, venue_id: venue.id).merge(dates: [date1, date2])

        event = described_class.new(Event).create!(params)

        expect(event.swing_dates.map(&:date)).to contain_exactly(date1, date2)
      end

      it "creates event instances from the dates" do
        date1 = Date.tomorrow
        date2 = 2.days.from_now.to_date
        venue = create(:venue)
        params = attributes_for(:event, :occasional, venue_id: venue.id).merge(dates: [date1, date2])

        event = described_class.new(Event).create!(params)

        expect(event.event_instances.map(&:date)).to contain_exactly(date1, date2)
      end
    end

    context "when there are cancellations" do
      it "creates SwingDate records from the cancellations" do
        date1 = Date.tomorrow
        date2 = 2.days.from_now.to_date
        venue = create(:venue)
        params = attributes_for(:event, :occasional, venue_id: venue.id).merge(cancellations: [date1, date2])

        event = described_class.new(Event).create!(params)

        expect(event.swing_cancellations.map(&:date)).to contain_exactly(date1, date2)
      end

      it "ignores cancelled dates which don't match dates" do
        date1 = Date.tomorrow
        date2 = 2.days.from_now.to_date
        venue = create(:venue)
        params = attributes_for(:event, :occasional, venue_id: venue.id).merge(cancellations: [date1, date2])

        expect do
          described_class.new(Event).create!(params)
        end.not_to change(EventInstance, :count)
      end

      it "creates instances from the cancelled dates if weekly" do # rubocop:disable RSpec.example_length
        date1 = Date.tomorrow
        date2 = 2.days.from_now.to_date
        venue = create(:venue)
        params = attributes_for(:event, :weekly, venue_id: venue.id).merge(cancellations: [date1, date2])

        aggregate_failures do
          expect do
            event = described_class.new(Event).create!(params)
            instances = event.event_instances
            expect(instances.map(&:date)).to contain_exactly(date1, date2)
            expect(instances.map(&:cancelled)).to contain_exactly(true, true)
          end.to change(EventInstance, :count).by(2)
        end
      end
    end

    context "when there is a date in both dates and cancellations" do
      it "only creates one instance" do # rubocop:disable RSpec.example_length
        pending("removing swingdates, which don't work in this scenario")
        date1 = Date.tomorrow
        date2 = 2.days.from_now.to_date
        venue = create(:venue)
        params = attributes_for(:event, :occasional, venue_id: venue.id).merge(dates: [date1, date2], cancellations: [date1])

        aggregate_failures do
          expect do
            event = described_class.new(Event).create!(params)
            instances = event.event_instances
            expect(instances.map(&:date)).to contain_exactly(date1, date2)
            expect(instances.map(&:cancelled)).to contain_exactly(true, false)
          end.to change(EventInstance, :count).by(2)
        end
      end
    end

    context "when the dates already exist" do
      it "uses the existing dates" do # rubocop:disable RSpec.example_length
        date1 = Date.tomorrow
        date2 = 2.days.from_now.to_date
        swing_date1 = create(:swing_date, date: date1)
        swing_date2 = create(:swing_date, date: date2)
        venue = create(:venue)
        params = attributes_for(:event, :occasional, venue_id: venue.id).merge(dates: [date1, date2], cancellations: [date1])

        aggregate_failures do
          expect do
            event = described_class.new(Event).create!(params)
            expect(event.swing_dates).to eq [swing_date1, swing_date2]
            expect(event.swing_cancellations).to eq [swing_date1]
          end.not_to change(SwingDate, :count)
        end
      end
    end

    context "when no cancellations or dates are passed" do
      it "builds an event" do
        repository = class_double("Event", create!: double)
        other_value = double
        params = { other: other_value }

        described_class.new(repository).create!(params)

        expect(repository).to have_received(:create!).with(
          { other: other_value }
        )
      end
    end
  end
end
