# frozen_string_literal: true

require 'rails_helper'

describe 'GET /api/v1/accounts/{account_id}' do
  it 'returns account entity as 200 OK without token' do
    account = Fabricate(:account)

    get "/api/v1/accounts/#{account.id}"

    assert_schema_conform(200)
    expect(response).to have_http_status(200)
  end

  it 'returns account entity as 200 OK with token' do
    account = Fabricate(:account)
    user = Fabricate(:user, account: account)
    token = Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read:accounts')

    get "/api/v1/accounts/#{account.id}", headers: { Authorization: "Bearer #{token.token}" }

    assert_schema_conform(200)
    expect(response).to have_http_status(200)
  end

  it 'returns 404 if account not found' do
    get '/api/v1/accounts/1'

    assert_schema_conform(404)
    expect(response).to have_http_status(404)
  end

  it 'returns 403 if scope of token is invalid' do
    account = Fabricate(:account)
    user = Fabricate(:user, account: account)
    token = Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'write:statuses')

    get "/api/v1/accounts/#{account.id}", headers: { Authorization: "Bearer #{token.token}" }

    assert_schema_conform(403)
    expect(response).to have_http_status(403)
  end

  it 'includes emojis when account uses custom emoji' do
    custom_emoji = Fabricate(:custom_emoji, shortcode: 'foo_emoji')
    account = Fabricate(:account, display_name: ':foo_emoji:')

    get "/api/v1/accounts/#{account.id}"

    assert_schema_conform(200)
    expect(response).to have_http_status(200)

    response_body = body_as_json
    expect(response_body[:emojis]).to contain_exactly({
      shortcode: custom_emoji.shortcode,
      url: (be_a String),
      static_url: (be_a String),
      visible_in_picker: custom_emoji.visible_in_picker,
    })
  end

  it 'includes fields when account has fields' do
    account = Fabricate(:account, fields: [{
      name: 'field1_name',
      value: 'field1_value',
      verified_at: nil,
    }, {
      name: 'field2_name',
      value: 'field2_value',
      verified_at: '2023-05-20T20:00:00Z',
    }])

    get "/api/v1/accounts/#{account.id}"

    assert_schema_conform(200)
    expect(response).to have_http_status(200)

    response_body = body_as_json
    expect(response_body[:fields]).to contain_exactly({
      name: 'field1_name',
      value: 'field1_value',
      verified_at: nil,
    }, {
      name: 'field2_name',
      value: 'field2_value',
      verified_at: '2023-05-20T20:00:00.000+00:00',
    })
  end
end
