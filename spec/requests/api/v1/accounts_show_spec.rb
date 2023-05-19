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
end
