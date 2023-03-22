# frozen_string_literal: true

require 'rails_helper'
require 'support/shoulda_matchers'

describe Event do
  describe '#title' do
    it 'strips whitespace before saving' do
      event = build(:event, title: " \tDance time! ")

      event.valid?

      expect(event.title).to eq('Dance time!')
    end
  end

  describe '#url' do
    it 'strips whitespace before saving' do
      event = build(:event, url: " \thttps://dancetime.co.uk ")

      event.valid?

      expect(event.url).to eq('https://dancetime.co.uk')
    end
  end

  describe '.dates' do
    it 'returns an ordered list of dates' do
      recent_date = create(:swing_date, date: Time.zone.today)
      old_date = create(:swing_date, date: Time.zone.today - 1.year)

      event = create(:event)
      event.swing_dates << recent_date
      event.swing_dates << old_date
      event.save!

      expect(event.reload.dates).to eq([Time.zone.today - 1.year, Time.zone.today])
    end
  end

  describe '.self.socials_dates' do
    context 'when there is only one social' do
      it 'returns the correct array when that social has only one date in the future' do
        one_date = Time.zone.today + 7
        event = create(:intermittent_social, dates: [one_date])

        aggregate_failures do
          expect(described_class.socials_dates(Time.zone.today).length).to eq(1)
          expect(described_class.socials_dates(Time.zone.today)[0][0]).to eq(one_date)
          expect(described_class.socials_dates(Time.zone.today)[0][1]).to eq([event])
        end
      end

      it 'returns the correct array when that social has two dates in the future' do
        later_date = Time.zone.today + 7
        earlier_date = Time.zone.today + 1
        event = create(:intermittent_social, dates: [later_date, earlier_date])

        aggregate_failures do
          expect(described_class.socials_dates(Time.zone.today).length).to eq(2)
          expect(described_class.socials_dates(Time.zone.today)[0][0]).to eq(earlier_date)
          expect(described_class.socials_dates(Time.zone.today)[0][1]).to eq([event])
          expect(described_class.socials_dates(Time.zone.today)[1][0]).to eq(later_date)
          expect(described_class.socials_dates(Time.zone.today)[1][1]).to eq([event])
        end
      end

      it 'returns the correct array when that social has one date today, one at the limit and one outside the limit' do
        lower_limit_date = Time.zone.today
        upper_limit_date = Time.zone.today + 13
        outside_limit_date = Time.zone.today + 14
        event = create(:intermittent_social, dates: [upper_limit_date, outside_limit_date, lower_limit_date])

        aggregate_failures do
          expect(described_class.socials_dates(Time.zone.today).length).to eq(2)
          expect(described_class.socials_dates(Time.zone.today)).to eq(
            [[lower_limit_date, [event], []], [upper_limit_date, [event], []]]
          )
        end
      end

      it 'returns the correct array when that social has one date in the future and one in the past' do
        past_date = Time.zone.today - 1.month
        future_date = Time.zone.today + 5
        event = create(:intermittent_social, dates: [past_date, future_date])

        aggregate_failures do
          expect(described_class.socials_dates(Time.zone.today).length).to eq(1)
          expect(described_class.socials_dates(Time.zone.today)).to eq([[future_date, [event], []]])
        end
      end
    end

    pending 'add more tests for socials_dates which return multiple events'
    pending 'add tests including weekly events!'

    context 'when things are complex' do
      def date(offset)
        Time.zone.today + offset
      end

      pending 'do more complex examples!'

      # class_with_social = FactoryBot.create(:class, :event_type =>"class_with_social", :day => "Tuesday")

      # rubocop:disable RSpec/ExampleLength
      it 'returns the correct array with a bunch of classes and socials' do
        # create one class for each day, starting on monday. None of these should be included
        create_list(:class, 7)

        # not included events:
        create(:intermittent_social, dates: [date(-10)])
        create(:intermittent_social, dates: [date(-370)])
        create(:intermittent_social, dates: [date(20)])

        # included events:
        event_d1 = create(:intermittent_social, dates: [date(1)])
        event_d10_d11 = create(:social, frequency: 4, dates: [date(10), date(11)])
        event_1_d8 = create(:social, frequency: 4, dates: [date(8)], title: 'A')
        event_2_d8 = create(:social, frequency: 2, dates: [date(8)], title: 'Z')

        expect(described_class.socials_dates(Time.zone.today)).to eq(
          [
            [date(1), [event_d1], []],
            [date(8), [event_1_d8, event_2_d8], []],
            [date(10), [event_d10_d11], []],
            [date(11), [event_d10_d11], []]
          ]
        )
      end
      # rubocop:enable RSpec/ExampleLength
    end
  end

  describe '.socials_on_date' do
    it 'returns intermittent socials on a given date' do
      date = Date.current
      social = create(:intermittent_social, dates: [date])

      socials = described_class.socials_on_date(date)

      expect(socials).to eq [social]
    end

    it 'returns weekly socials on the same day as a given date' do
      date = Date.current.next_occurring(:thursday)
      social = create(:weekly_social, day: 'Thursday')

      socials = described_class.socials_on_date(date)

      expect(socials).to eq [social]
    end

    it 'returns nil if there are no socials on that date' do
      date = Date.current

      socials = described_class.socials_on_date(date)

      expect(socials).to be_empty
    end

    it 'sorts the results by title' do
      date = Date.current.next_occurring(:thursday)
      create(:intermittent_social, dates: [date], title: 'Casablanca')
      create(:weekly_social, day: 'Thursday', title: 'Alhambra')
      create(:intermittent_social, dates: [date], title: 'Boogaloo')
      socials = described_class.socials_on_date(date)

      expect(socials.pluck(:title)).to eq %w[Alhambra Boogaloo Casablanca]
    end
  end

  # ultimately do away with date_array and test .dates= instead"
  describe '.date_array =' do
    describe 'empty strings' do
      it 'handles an event with with no dates and adding no dates' do
        event = create(:event)
        event.date_array = ''
        expect(event.swing_dates).to eq([])
      end

      it 'handles an event with with no dates and adding nil dates' do
        event = create(:event)
        event.date_array = nil
        expect(event.swing_dates).to eq([])
      end

      it 'handles an event with no dates and adding unknown dates' do
        event = create(:event)
        event.date_array = 'Unknown'
        expect(event.swing_dates).to eq([])
      end

      it 'handles an event with no dates and a weekly event' do
        event = create(:event)
        event.date_array = 'Weekly'
      end
    end

    it 'successfully adds one valid date to an event' do
      event = create(:event)
      event.date_array = '01/02/2012'
      expect(event.dates).to eq([Date.new(2012, 2, 1)])
    end

    it 'successfully adds two valid dates to an event with no dates and orders them' do
      event = create(:event)
      event.date_array = '01/02/2012, 30/11/2011'
      expect(event.dates).to eq([Date.new(2011, 11, 30), Date.new(2012, 2, 1)])
    end

    it 'blanks out a date array where there existing dates' do # rubocop:disable RSpec/MultipleExpectations
      event = create(:event, date_array: '01/02/2012, 30/11/2011')
      expect(event.dates).to eq([Date.new(2011, 11, 30), Date.new(2012, 2, 1)])
      event.date_array = ''
      expect(event.dates).to eq([])
    end

    it 'does not create multiple instances of the same date' do
      event1 = create(:event)
      event1.date_array = '05/05/2005'
      event1.save!
      event2 = create(:event)
      event2.date_array = '05/05/2005'
      event2.save!
      expect(SwingDate.where(date: Date.new(2005, 5, 5)).length).to eq(1)
    end

    pending 'multiple valid dates, one invalid date on the end'
    pending 'multiple valid dates, one invalid date in the middle'
    pending 'blanking out where there are existing dates'
    pending 'fails to add an invalid date to an event'

    pending 'save with an invalid dates array'

    pending 'test with multiple dates, different orders, whitespace'
  end

  describe '.cancellation_array =' do
    describe 'empty strings' do
      it 'handles an event with with no cancellations and adding no cancellations' do
        event = described_class.new
        event.cancellation_array = ''
        expect(event.swing_cancellations).to eq([])
      end

      it 'handles an event with with no cancellations and adding nil cancellations' do
        event = described_class.new
        event.cancellation_array = nil
        expect(event.swing_cancellations).to eq([])
      end

      it 'handles an event with no cancellations and adding unknown cancellations' do
        event = described_class.new
        event.cancellation_array = 'Unknown'
        expect(event.swing_cancellations).to eq([])
      end

      it 'handles an event with no cancellations and a weekly event' do
        event = described_class.new
        event.cancellation_array = 'Weekly'
        expect(event.swing_cancellations).to eq([])
      end
    end

    it 'successfully adds one valid cancellation to an event with no cancellations' do
      event = described_class.new
      event.cancellation_array = '01/02/2012'
      expect(event.cancellations).to eq([Date.new(2012, 2, 1)])
    end

    it 'successfully adds two valid cancellations to an event with no cancellations and orders them' do
      event = described_class.new
      event.cancellation_array = '01/02/2012, 30/11/2011'
      expect(event.cancellations).to eq([Date.new(2012, 2, 1), Date.new(2011, 11, 30)])
    end

    it 'blanks out a cancellation array where there existing dates' do # rubocop:disable RSpec/MultipleExpectations
      event = create(:event, cancellation_array: '01/02/2012')
      expect(event.cancellations).to eq([Date.new(2012, 2, 1)])
      event.cancellation_array = ''
      expect(event.cancellations).to eq([])
    end

    pending 'multiple valid cancellations, one invalid date on the end'
    pending 'multiple valid cancellations, one invalid date in the middle'
    pending 'fails to add an invalid date to an event'

    pending 'save with an invalid cancellations array'

    pending 'test with multiple cancellations, different orders, whitespace'
  end

  describe 'active.classes' do
    it "returns classes with no 'last date'" do
      event = create(:class, last_date: nil)
      expect(described_class.active.classes).to eq([event])
    end

    it "does not return classes with a 'last date' in the past" do
      create(:class, last_date: Time.zone.today - 1)
      expect(described_class.active.classes).to eq([])
    end

    it 'does not return non-classes' do
      create(:event, last_date: nil, has_class: 'false')
      create(:event, last_date: nil, has_taster: 'true')

      expect(described_class.active.classes).to eq([])
    end

    it 'returns the correct list of classes' do # rubocop:disable RSpec/ExampleLength
      create(:social, last_date: nil)
      create(:class, last_date: Time.zone.today - 5)
      returned = [
        create(:class),
        create(:class, last_date: nil),
        create(:class, last_date: Time.zone.today + 1)
      ]
      create(:social)
      create(:event, has_class: 'false', has_taster: 'true')

      aggregate_failures do
        expect(described_class.active.classes.length).to eq(returned.length)
        expect(returned).to include(described_class.active.classes[0])
        expect(returned).to include(described_class.active.classes[1])
        expect(returned).to include(described_class.active.classes[2])
      end
    end
  end

  describe '(validations)' do
    it 'is invalid if it has neither a class nor a social nor a taster' do
      expect(build(:event, has_taster: false, has_social: false, has_class: false)).not_to be_valid
    end

    it 'is invalid if it has a taster but no class or social' do
      expect(build(:event, has_taster: true, has_social: false, has_class: false)).not_to be_valid
    end

    it 'is valid if it has a class but no taster or social (and everything else is OK)' do
      expect(build(:event, has_taster: false, has_social: false, has_class: true, class_organiser_id: 7)).to be_valid
    end

    it 'is valid if it has a social but no taster or class (and everything else is OK)' do
      expect(build(:event, has_taster: false, has_social: true, has_class: false)).to be_valid
    end

    it 'is invalid with no venue' do
      event = build(:event, venue_id: nil)
      event.valid?
      expect(event.errors.messages).to eq(venue: ['must exist'])
    end

    it "is valid if it's a class without a title" do
      expect(build(:event, has_taster: false, has_social: false, has_class: true, title: nil, class_organiser_id: 7)).to be_valid
    end

    it "is invalid if it's a social without a title" do
      event = build(:event, has_taster: false, has_social: true, has_class: false, title: nil)
      event.valid?
      expect(event.errors.messages).to eq(title: ['must be present for social dances'])
    end

    it { is_expected.to validate_uniqueness_of(:organiser_token).allow_nil }

    it "is invalid if it has a class and doesn't have a class organiser" do
      event = build(:event, has_taster: false, has_social: false, has_class: true, class_organiser: nil)
      event.valid?
      expect(event.errors.messages).to eq(class_organiser_id: ['must be present for classes'])
    end
  end

  describe 'expected_date' do
    it 'is a month after the previous date for monthly events' do
      event = build(:event, frequency: 4)
      # FIXME: EVIL!!!: Stubbing object under test
      allow(event).to receive(:latest_date).and_return Date.new(1970, 1, 1)
      expect(event.expected_date).to eq Date.new(1970, 1, 29)
    end

    it 'is a year after the previous date for monthly events' do
      event = build(:event, frequency: 52)
      # FIXME: EVIL!!!: Stubbing object under test
      allow(event).to receive(:latest_date).and_return Date.new(1970, 1, 1)
      expect(event.expected_date).to eq Date.new(1970, 12, 31)
    end

    it 'is after a far-future date if there are no dates' do
      event = build(:event, frequency: 4) # No dates by default
      expect(event.expected_date).to be > Time.zone.today + 1.year
    end

    it 'is after a far-future date if the event is weekly' do
      event = build(:event, frequency: 1)
      expect(event.expected_date).to be > Time.zone.today + 1.year
    end

    it 'is after a far-future date if the event has frequency 0 and other dates' do
      event = build(:event, frequency: 0)
      # FIXME: EVIL!!!: Stubbing object under test
      allow(event).to receive(:latest_date).and_return Date.new(1970, 1, 1)
      expect(event.expected_date).to be > Time.zone.today + 1.year
    end
  end
end
