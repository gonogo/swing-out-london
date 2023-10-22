# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Adding a new event", :js do
  it "with a social and a dance class" do
    visit "/events"

    click_button "Log in"

    # VENUE
    click_link "New Venue"

    fill_in "Name", with: "The Savoy Ballroom"
    fill_in "Address", with: "596 Lenox Avenue"
    fill_in "Postcode", with: "WC2R 0EZ"
    fill_in "Area", with: "Harlem"
    fill_in "Latitude", with: "40.817529"
    fill_in "Longitude", with: "73.938456"
    fill_in "Website", with: "https://www.savoyballroom.com"

    click_button "Create"

    # SOCIAL ORGANISER
    click_link "New Organiser"

    fill_in "Name", with: "Herbert White"
    fill_in "Shortname", with: "Whitey"
    fill_in "Website", with: "https://hoppingmainacs.org"
    fill_in "Description", with: "Architect of Whitey's Lindy Hoppers"

    click_button "Create"

    # CLASS ORGANISER
    click_link "New Organiser"

    fill_in "Name", with: "Frankie Manning"
    fill_in "Shortname", with: "Frankie"

    click_button "Create"

    click_link "New Event"

    # EVENT WITH CANCELLED DATE
    fill_in "Url", with: "https://www.savoyballroom.com/stompin"
    autocomplete_select "The Savoy Ballroom", from: "Venue"
    choose "Social dance"

    fill_in "Title", with: "Stompin at the Savoy"
    autocomplete_select "Herbert White", from: "Social organiser"

    check "Has a class?"
    autocomplete_select "Frankie Manning", from: "Class organiser"
    choose "Other (balboa, shag etc)"
    fill_in "Dance style", with: "Savoy Style"
    fill_in "Course length", with: ""

    choose "Weekly"
    select "Saturday", from: "Day"
    fill_in "Cancelled dates", with: "09/01/1937"
    fill_in "First date", with: "12/03/1926"
    fill_in "Last date", with: "11/10/1958"

    click_button "Create"

    # RECENTLY STARTED EVENT (NEW!)
    click_link "New Event"

    fill_in "Url", with: "https://www.savoyballroom.com/ladies"
    autocomplete_select "The Savoy Ballroom", from: "Venue"
    choose "Social dance"

    fill_in "Title", with: "Ladies night"
    choose "Monthly or occasionally"

    fill_in "Upcoming dates", with: "13/01/1937"
    fill_in "First date", with: "13/01/1937"

    click_button "Create"

    Timecop.freeze("01/01/1937") do
      click_link "Swing Out London"
    end

    venue_id = Venue.first.id

    within "#social_dances" do
      rows = page.all(".date_row")
      within rows[0] do
        aggregate_failures do
          expect(page).to have_content "Saturday 2nd January"
          expect(page).to have_link "WC2R", href: "/map/socials/1937-01-02?venue_id=#{venue_id}"
          expect(page).to have_link "Stompin at the Savoy - The Savoy Ballroom in Harlem", href: "https://www.savoyballroom.com/stompin"
        end
      end

      within rows[1] do
        aggregate_failures do
          expect(page).to have_content "Saturday 9th January"
          expect(page).to have_link "WC2R", href: "/map/socials/1937-01-09?venue_id=#{venue_id}"
          expect(page).to have_content "CANCELLED Stompin at the Savoy"
          expect(page).to have_link "Stompin at the Savoy - The Savoy Ballroom in Harlem", href: "https://www.savoyballroom.com/stompin"
        end
      end

      within rows[2] do
        aggregate_failures do
          expect(page).to have_content "Wednesday 13th January"
          expect(page).to have_link "WC2R", href: "/map/socials/1937-01-13?venue_id=#{venue_id}"
          expect(page).to have_content "NEW! Ladies night"
          expect(page).to have_link "Ladies night - The Savoy Ballroom in Harlem", href: "https://www.savoyballroom.com/ladies"
        end
      end
    end

    within "#classes" do
      rows = page.all(".day_row")
      within rows[5] do
        aggregate_failures do
          expect(page).to have_content "Saturday"
          expect(page).to have_link "WC2R", href: "/map/classes/Saturday?venue_id=#{venue_id}"
          expect(page).to have_link "Harlem (Savoy Style) at Stompin at the Savoy with Frankie", href: "https://www.savoyballroom.com/stompin"
          expect(page).to have_content "Cancelled on 9th Jan"
        end
      end
    end

    expect(page).not_to have_content("<")
    expect(page).not_to have_content(">")
    expect(page).not_to have_content("abbr title=")
  end
end
