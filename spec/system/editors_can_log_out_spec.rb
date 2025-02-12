# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Editor Login" do
  it "Editors can log out" do
    stub_login(name: "Al Minns")

    visit "/events"

    click_button "Log in"

    click_link "Al Minns"

    click_button "Log out"
    expect(page).to have_button("Log in")

    visit "/events"
    expect(page).to have_button("Log in")
  end
end
