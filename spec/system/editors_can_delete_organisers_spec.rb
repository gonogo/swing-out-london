# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Editors can delete organisers" do
  context "when the organiser has no associated events", :js do
    it "can be deleted from the organiser list" do
      stub_login
      create(:organiser, name: "Herbert White")

      visit "/login"
      click_button "Log in"

      click_link "Organisers", match: :first

      accept_confirm do
        click_link "Delete", match: :first
      end

      expect(page).to have_content("Listing organisers")
      expect(page).not_to have_content("Delete")
      expect(page).not_to have_content("Herbert White")
    end

    it "can be deleted from the edit page" do
      stub_login
      create(:organiser, name: "Herbert White")

      visit "/login"
      click_button "Log in"

      click_link "Organisers", match: :first

      click_link "Edit", match: :first

      accept_confirm do
        click_link "Delete"
      end

      expect(page).to have_content("Listing organisers")
      expect(page).not_to have_content("Delete")
      expect(page).not_to have_content("Herbert White")
    end
  end

  context "when the organiser has associated events" do
    it "cannot be deleted" do
      stub_login
      organiser = create(:organiser)
      create(:event, social_organiser: organiser)

      visit "/login"
      click_button "Log in"

      click_link "Organisers", match: :first

      expect(page).not_to have_content("Delete")

      click_link "Show"

      expect(page).not_to have_content("Delete")

      click_link "Edit"

      expect(page).not_to have_content("Delete")
      expect(page).to have_content("Can't be deleted: has associated events")
    end
  end
end
