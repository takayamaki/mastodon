# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Initial state embedded in the web app' do
  context 'when a signed-in user opens the home page' do
    let(:user) { Fabricate(:user) }

    before { sign_in user }

    it 'conforms to the initial_state JSON schema' do
      pending 'the schema still encodes the hand-written TS type, which has drifted from the serializer'

      get root_path

      expect(initial_state).to match_json_schema('initial_state')
    end

    it 'identifies the current account in meta.me and compose.me as the account id string'
    it 'carries the session token in meta.access_token'
    it 'includes the current account in accounts keyed by id'
    it 'exposes the user web UI preferences in meta as booleans'
    it 'exposes the composer defaults in compose'
    it 'describes the user role in role'
    it 'has no push_subscription when the session has none'
    it 'does not include critical_updates_pending for a user without devops permission'
    it 'points meta.admin at the site contact account and includes that account in accounts'
  end

  context 'when an anonymous visitor opens the home page' do
    it 'conforms to the initial_state JSON schema'
    it 'has a null meta.access_token and no meta.me'
    it 'exposes only the instance-wide display defaults in meta'
    it 'has an empty accounts map and empty settings'
    it 'has null push_subscription and role'
    it 'leaves compose with an empty text only'
  end

  context 'when a signed-in user opens the share intent page' do
    it 'joins title, text and url into compose.text separated by spaces'
    it 'applies a requested visibility that is not wider than the user default'
    it 'ignores a requested visibility wider than the user default'
  end

  context 'when a signed-in user has a web push subscription for the session' do
    it 'describes the subscription in push_subscription'
  end

  context 'when the signed-in user has devops permission and software update checks are enabled' do
    it 'includes critical_updates_pending as a boolean'
  end

  context 'when the signed-in user account is not functional' do
    it 'conforms to the initial_state JSON schema'
    it 'reports the account in meta.disabled_account_id and includes it in accounts'
    it 'has a null meta.access_token and no meta.me'
    it 'reports the destination in meta.moved_to_account_id when the account has moved'
  end

  context 'when the server runs in single user mode' do
    it 'reports the owner account in meta.owner and includes it in accounts'
    it 'reports registrations as closed'
  end

  context 'when the web app is rendered from another page' do
    it 'embeds the same initial state structure'
  end

  private

  def initial_state
    JSON.parse(response.parsed_body.at_css('script#initial-state').text)
  end
end
