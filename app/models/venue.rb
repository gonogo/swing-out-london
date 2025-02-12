# frozen_string_literal: true

class Venue < ApplicationRecord
  geocoded_by :postcode,
              latitude: :lat,
              longitude: :lng
  audited

  has_many :events, dependent: :restrict_with_exception

  scope :all_with_classes_listed, -> { where(id: Event.listing_classes.select("distinct venue_id")) }
  scope :all_with_classes_listed_on_day, ->(day) { where(id: Event.listing_classes_on_day(day).select("distinct venue_id")) }

  validates :address, presence: true
  validates :area, presence: true
  validates :name, presence: true
  validates :website, format: URI::DEFAULT_PARSER.make_regexp(%w[http https])

  strip_attributes only: %i[name postcode area website]

  before_validation do
    if (lat.nil? || lng.nil?) && !geocode
      errors.add :lat, "The address information could not be geocoded.
          Please check the address information or manually enter
          latitude and longitude"
    end
  end

  def name_and_area
    "#{name} - #{area}"
  end

  def no_future_dates?
    events.none?(&:future_dates?)
  end

  def coordinates
    return unless lat && lng

    "[ #{lat}, #{lng} ]"
  end

  def can_delete?
    raise "Can't delete a Venue which is not persisted" unless persisted?

    events.empty?
  end
end
