# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Editors can archive events" do
  it "with a weekly event" do
    skip_login
    create(:event, frequency: 1, day: "Sunday")

    visit "/events"

    # 8th Jan 2000 was a saturday
    Timecop.freeze(Time.zone.local(2000, 1, 8)) do
      click_link "Archive", match: :first
    end

    click_show

    expect(page).to have_content("Last date: Sunday 2nd January")
  end

  it "with an occasional event" do
    skip_login
    create(:event, frequency: 0, dates: ["02/01/2000".to_date])

    visit "/events"

    Timecop.freeze(Time.zone.local(2000, 1, 8)) do
      click_link "Archive", match: :first
    end

    click_show

    expect(page).to have_content("Last date: Sunday 2nd January")
  end

  it "with an event with no dates" do
    skip_login
    create(:event, frequency: 0, dates: [])

    visit "/events"

    click_link "Archive", match: :first

    click_show

    expect(page).to have_content("Last date: Monday 1st January") # earliest possible Date
  end

  def click_show
    within ".actions.last", match: :first do
      click_link "Show"
    end
  end
end
