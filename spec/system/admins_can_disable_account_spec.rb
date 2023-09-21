# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Login Revocation" do
  it "admins can deauthorise Swing Out Londons facebook permissions", :vcr do
    config = Rails.configuration.x.facebook
    allow(config).to receive_messages(
      api_base!: "https://graph.facebook.com/",
      api_auth_token!: "super-secret-token",
      app_secret!: "super-secret-secret",
      admin_user_ids: [12345678901234567]
    )

    stub_auth_hash(id: 12345678901234567)

    visit "/account"

    click_on "Log in with Facebook"

    # TEMP - remove once we have implemented redirect:
    visit "/account"

    VCR.use_cassette("disable_login") do
      click_on "Disable my login"
    end

    expect(page).to have_header("Admin Login")
    expect(page).to have_content("Your login permissions have been revoked in Facebook")
    expect(page).to have_button("Log in with Facebook")

    visit "/events"
    expect(page).to have_button("Log in with Facebook")
  end
end
