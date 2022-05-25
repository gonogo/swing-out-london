# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Organisers can edit events' do
  context 'when an organiser token exists' do
    it 'allows an organiser to edit an event' do
      create(:social, organiser_token: 'abc123', title: 'Midtown stomp')
      create(:venue, name: 'The 100 Club', area: 'central')

      visit('/external_events/abc123/edit')

      expect(page).to have_content('Midtown stomp')

      select 'The 100 Club', from: 'Venue'
      click_on 'Update'

      aggregate_failures do
        expect(page).to have_select('Venue', selected: 'The 100 Club - central')
        expect(page).to have_content('Event was successfully updated')
      end

      expect(Audit.last.username).to eq('name' => 'Organiser (abc123)', 'auth_id' => 'abc123')
    end

    it 'does not allow organisers to access other pages' do
      event = create(:social, organiser_token: 'abc123', title: 'Midtown stomp')

      visit('/external_events/abc123/edit')

      expect(page).to have_content('Midtown stomp')

      visit("/events/#{event.id}/edit")

      expect(page).to have_content('Log in with Facebook')
    end
  end

  context 'when the changes are invalid' do
    it 'shows validation errors' do
      create(:social, organiser_token: 'abc123')

      visit('/external_events/abc123/edit')

      select '', from: 'Venue'
      click_on 'Update'

      expect(page).to have_content('1 error prohibited this record from being saved:')
        .and have_content('Venue must exist')
    end
  end

  context 'when the organiser token is incorrect' do
    it 'redirects to the homepage' do
      visit('/external_events/abc123/edit')

      expect(page).to have_content('Listings')
    end
  end
end
