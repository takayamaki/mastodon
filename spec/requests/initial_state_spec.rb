# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Initial state embedded in the web app' do
  context 'when a signed-in user opens the home page' do
    let(:user) { Fabricate(:user) }

    before { sign_in user }

    it 'conforms to the initial_state JSON schema' do
      get root_path

      expect(initial_state).to match_json_schema('initial_state')
    end

    it 'identifies the current account in meta.me and compose.me as the account id string' do
      get root_path

      expect(initial_state)
        .to include(
          'meta' => include('me' => user.account.id.to_s),
          'compose' => include('me' => user.account.id.to_s)
        )
    end

    it 'carries the session token in meta.access_token' do
      get root_path

      expect(initial_state['meta']['access_token'])
        .to be_present
        .and eq(user.session_activations.sole.access_token.token)
    end

    it 'includes the current account in accounts keyed by id' do
      get root_path

      expect(initial_state['accounts'])
        .to match(
          user.account.id.to_s => include('id' => user.account.id.to_s, 'username' => user.account.username, 'acct' => user.account.username)
        )
    end

    it 'exposes the user web UI preferences in meta as booleans' do
      user.settings.update('web.reblog_modal': true, 'web.delete_modal': false)
      user.save!

      get root_path

      expect(initial_state['meta'])
        .to include(
          'boost_modal' => true,
          'delete_modal' => false,
          'quick_boosting' => false,
          'missing_alt_text_modal' => true,
          'auto_play_gif' => false,
          'expand_spoilers' => false,
          'reduce_motion' => false,
          'disable_swiping' => false,
          'disable_hover_cards' => false,
          'advanced_layout' => false,
          'use_blurhash' => true,
          'use_pending_items' => false,
          'show_trends' => true
        )
    end

    it 'exposes the composer defaults in compose' do
      user.settings.update(default_privacy: 'unlisted', default_sensitive: true, default_language: 'ja', default_quote_policy: 'followers', default_spoiler_field: true)
      user.save!

      get root_path

      expect(initial_state['compose'])
        .to include(
          'default_privacy' => 'unlisted',
          'default_sensitive' => true,
          'default_language' => 'ja',
          'default_quote_policy' => 'followers',
          'default_spoiler_field' => true
        )
    end

    it 'describes the user role in role' do
      role = Fabricate(:user_role, name: 'Curator', color: '#ff0000', highlighted: true, permissions: UserRole::FLAGS[:manage_reports], collection_limit: 20)
      user.update!(role:)

      get root_path

      expect(initial_state['role'])
        .to eq(
          'id' => role.id.to_s,
          'name' => 'Curator',
          'permissions' => role.computed_permissions.to_s,
          'color' => '#ff0000',
          'highlighted' => true,
          'collection_limit' => 20
        )
    end

    it 'has no push_subscription when the session has none' do
      get root_path

      expect(initial_state)
        .to include('push_subscription' => nil)
    end

    it 'does not include critical_updates_pending for a user without devops permission' do
      allow(SoftwareUpdate).to receive(:check_enabled?).and_return(true)

      get root_path

      expect(initial_state)
        .to_not have_key('critical_updates_pending')
    end

    it 'points meta.admin at the site contact account and includes that account in accounts' do
      contact = Fabricate(:account, username: 'contact')
      Setting.site_contact_username = '@contact'

      get root_path

      expect(initial_state)
        .to include(
          'meta' => include('admin' => contact.id.to_s),
          'accounts' => include(contact.id.to_s => include('username' => 'contact'))
        )
    end
  end

  context 'when an anonymous visitor opens the home page' do
    it 'conforms to the initial_state JSON schema' do
      get root_path

      expect(initial_state).to match_json_schema('initial_state')
    end

    it 'has a null meta.access_token and no meta.me' do
      get root_path

      expect(initial_state['meta'])
        .to include('access_token' => nil)
        .and not_include('me')
    end

    it 'exposes only the instance-wide display defaults in meta' do
      Setting.auto_play_gif = true
      Setting.display_media = 'show_all'
      Setting.reduce_motion = true
      Setting.use_blurhash = false

      get root_path

      expect(initial_state['meta'])
        .to include('auto_play_gif' => true, 'display_media' => 'show_all', 'reduce_motion' => true, 'use_blurhash' => false)
        .and not_include('boost_modal', 'delete_modal', 'expand_spoilers', 'advanced_layout', 'show_trends', 'emoji_style', 'wrapstodon')
    end

    it 'has an empty accounts map and empty settings' do
      get root_path

      expect(initial_state)
        .to include('accounts' => {}, 'settings' => {})
    end

    it 'has null push_subscription and role' do
      get root_path

      expect(initial_state)
        .to include('push_subscription' => nil, 'role' => nil)
    end

    it 'leaves compose with an empty text only' do
      get root_path

      expect(initial_state['compose'])
        .to eq('text' => '')
    end
  end

  context 'when a signed-in user opens the share intent page' do
    let(:user) { Fabricate(:user) }

    before { sign_in user }

    it 'joins title, text and url into compose.text separated by spaces' do
      get share_path(title: 'Title', text: 'Some text', url: 'https://example.com/')

      expect(initial_state['compose'])
        .to include('text' => 'Title Some text https://example.com/')
    end

    it 'applies a requested visibility narrower than the user default' do
      user.settings.update(default_privacy: 'public')
      user.save!

      get share_path(text: 'Hello', visibility: 'unlisted')

      expect(initial_state['compose'])
        .to include('default_privacy' => 'unlisted')
    end

    it 'ignores a requested visibility wider than the user default' do
      user.settings.update(default_privacy: 'private')
      user.save!

      get share_path(text: 'Hello', visibility: 'public')

      expect(initial_state['compose'])
        .to include('default_privacy' => 'private')
    end
  end

  context 'when a signed-in user has a web push subscription for the session' do
    let(:user) { Fabricate(:user) }
    let(:subscription) { Fabricate(:web_push_subscription, user:, data: { alerts: { mention: true, follow: false }, policy: 'followed' }) }

    before do
      sign_in user
      # The session activation only exists after the first request
      get root_path
      user.session_activations.sole.update!(web_push_subscription: subscription)
    end

    it 'describes the subscription in push_subscription' do
      get root_path

      expect(initial_state['push_subscription'])
        .to eq(
          'id' => subscription.id,
          'endpoint' => subscription.endpoint,
          'standard' => subscription.standard,
          'alerts' => { 'mention' => true, 'follow' => false },
          'server_key' => Rails.configuration.x.vapid.public_key,
          'policy' => 'followed'
        )
    end
  end

  context 'when the signed-in user has devops permission and software update checks are enabled' do
    let(:user) { Fabricate(:user, role: Fabricate(:user_role, permissions: UserRole::FLAGS[:view_devops])) }

    before do
      allow(SoftwareUpdate).to receive_messages(check_enabled?: true, urgent_pending?: true)
      sign_in user
    end

    it 'includes critical_updates_pending as a boolean' do
      get root_path

      expect(initial_state)
        .to include('critical_updates_pending' => true)
    end
  end

  context 'when the signed-in user account is not functional' do
    let(:user) { Fabricate(:user, confirmed_at: nil) }

    # The home page redirects non-functional users (require_functional!), so use a page that skips it
    before { sign_in user }

    it 'conforms to the initial_state JSON schema' do
      get about_path

      expect(initial_state).to match_json_schema('initial_state')
    end

    it 'reports the account in meta.disabled_account_id and includes it in accounts' do
      get about_path

      expect(initial_state)
        .to include(
          'meta' => include('disabled_account_id' => user.account.id.to_s),
          'accounts' => match(user.account.id.to_s => include('username' => user.account.username))
        )
    end

    it 'has a null meta.access_token and no meta.me' do
      get about_path

      expect(initial_state['meta'])
        .to include('access_token' => nil)
        .and not_include('me')
    end

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
