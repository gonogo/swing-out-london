# frozen_string_literal: true

require "dates_string_parser"
require "day_names"

class Event < ApplicationRecord
  audited

  include Frequency

  CONSIDERED_NEW_FOR = 1.month

  belongs_to :venue
  belongs_to :class_organiser, class_name: "Organiser", optional: true
  belongs_to :social_organiser, class_name: "Organiser", optional: true
  has_many :events_swing_dates, dependent: :destroy
  has_many :swing_dates, -> { distinct(true) }, through: :events_swing_dates
  has_many :events_swing_cancellations, dependent: :destroy
  has_many :swing_cancellations, -> { distinct(true) }, through: :events_swing_cancellations, source: :swing_date

  has_many :event_instances, dependent: :destroy

  validates :frequency, presence: true
  validates :url, presence: true, uri: true

  validates :course_length, numericality: { only_integer: true, greater_than: 0, allow_nil: true }

  validates :organiser_token, uniqueness: true, allow_nil: true

  validate :has_class_or_social
  validate :must_be_weekly_if_no_social
  validate :cannot_be_weekly_and_have_dates

  validates_with ValidSocialOrClass
  validates_with ValidWeeklyEvent

  strip_attributes only: %i[title url]

  # display constants:
  NOTAPPLICABLE = "n/a"
  UNKNOWN_ORGANISER = "Unknown"
  SEE_WEB = "(See Website)"

  class << self
    def socials_on_date(date)
      result = weekly_socials_on(date).includes(:venue)
      result += occasional_socials_on(date).includes(:venue)
      result
    end

    def socials_on_date_for_venue(date, venue)
      result = weekly_socials_on(date).where(venue_id: venue.id)
      result += occasional_socials_on(date).where(venue_id: venue.id)
      result
    end

    def weekly_socials_on(date)
      weekly.socials.active_on(date).on_same_day_of_week(date)
    end

    def occasional_socials_on(date)
      swing_date = SwingDate.find_by(date:)
      return none unless swing_date

      swing_date.events.occasional.socials
    end

    def cancelled_on_date(date)
      swing_date = SwingDate.find_by(date:)
      return [] unless swing_date

      swing_date.cancelled_events.pluck :id
    end
  end

  def has_class_or_social # rubocop:disable Naming/PredicateName
    return true if has_class? || has_social?

    errors.add(:base, "Events must have either a Social or a Class, otherwise they won't be listed")
  end

  def must_be_weekly_if_no_social
    return if has_social? || weekly? || frequency.nil?

    errors.add(:frequency, "must be 1 (weekly) for events without a social")
  end

  def cannot_be_weekly_and_have_dates
    return unless weekly? && swing_dates.any?

    errors.add(:swing_dates, "must be empty for weekly events")
  end

  # ----- #
  # Venue #
  # ----- #

  delegate :name, to: :venue, prefix: true
  delegate :area, to: :venue, prefix: true
  delegate :postcode, to: :venue, prefix: true
  delegate :coordinates, to: :venue, prefix: true

  # ---------- #
  # Event Type #
  # ---------- #

  # scopes to get different types of event:
  scope :classes, -> { where(has_class: true) }
  scope :socials, -> { where(has_social: true) }
  scope :weekly, -> { where(frequency: 1) }
  scope :weekly_or_fortnightly, -> { where(frequency: [1, 2]) }
  scope :occasional, -> { where(frequency: 0) }

  scope :active, -> { where("last_date IS NULL OR last_date > ?", Date.current) }
  scope :ended, -> { where("last_date IS NOT NULL AND last_date < ?", Date.current) }
  scope :active_on, ->(date) { where("(first_date IS NULL OR first_date <= ?) AND (last_date IS NULL OR last_date >= ?)", date, date) }

  scope :listing_classes, -> { active.weekly_or_fortnightly.classes }
  scope :listing_classes_on_day, ->(day) { listing_classes.where(day:) }
  scope :listing_classes_at_venue, ->(venue) { listing_classes.where(venue_id: venue.id) }
  scope :listing_classes_on_day_at_venue, ->(day, venue) { listing_classes_on_day(day).where(venue_id: venue.id) }

  scope :on_same_day_of_week, ->(date) { where(day: DayNames.name(date)) }

  def caching_key(suffix)
    "event_#{id}_#{suffix}"
  end

  # ----- #
  # Dates #
  # ----- #

  def dates_cache_key
    caching_key("dates")
  end

  def dates
    Rails.cache.fetch(dates_cache_key) do
      swing_dates.order("date ASC").collect(&:date)
    end
  end

  after_save :clear_dates_cache
  def clear_dates_cache
    Rails.cache.delete(dates_cache_key)
  end

  def cancellations
    swing_cancellations.collect(&:date)
  end

  def future_cancellations
    filter_future(cancellations)
  end

  private

  # Given an array of dates, return only those in the future
  def filter_future(input_dates)
    # TODO: - should be able to simply replace this with some variant of ".future?", but need to test
    input_dates.select { |d| d >= Date.current }
  end

  public

  # COMPARISON METHODS #

  def future_dates?
    return true if weekly? # Weekly events don't have date arrays but implicitly will be running in the future
    return false if last_date
    return false unless latest_date

    latest_date > Date.current
  end

  # Is the event new? (probably only applicable to classes)
  def new?
    return false if first_date.nil?

    first_date > Date.current - CONSIDERED_NEW_FOR
  end

  # Has the first instance of the event happened yet?
  def started?
    return false if first_date.nil?

    first_date < Date.current
  end

  # Has the last instance of the event happened?
  def ended?
    return false if last_date.nil?

    last_date < Date.current
  end

  def latest_date_cache_key
    caching_key("latest_date")
  end

  # What's the Latest date in the date array
  # N.B. Assumes the date array is sorted!
  def latest_date
    Rails.cache.fetch(latest_date_cache_key) do
      swing_dates.maximum(:date)
    end
  end

  after_save :clear_latest_dates_cache
  def clear_latest_dates_cache
    Rails.cache.delete(latest_date_cache_key)
  end

  ###########
  # ACTIONS #
  ###########

  def archive!
    # If there's already a last_date in the past, then the event should already be archived!
    return false if !last_date.nil? && last_date < Date.current

    ended_date =
      if weekly?
        Date.current.prev_occurring(day.downcase.to_sym)
      elsif dates.blank?
        Date.new # Earliest possible ruby date
      else
        latest_date
      end

    update!(last_date: ended_date)
  end
end
