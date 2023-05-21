# frozen_string_literal: true

require 'rails_helper'

describe 'GET /api/v1/accounts/{account_id}/followers' do
  it 'returns followers of given account order by desc as 200 OK without token' do
    account = Fabricate(:account)
    followers = Array.new(2) do
      follower = Fabricate(:account)
      Fabricate(:follow, account: follower, target_account: account)
      follower
    end

    get "/api/v1/accounts/#{account.id}/followers"

    assert_schema_conform(200)
    expect(response).to have_http_status(200)

    response_body = body_as_json
    expect(response_body.pluck(:id)).to match(followers.reverse.map { _1.id.to_s })
  end

  it 'limits maximum number of results via limit query parameter' do
    account = Fabricate(:account)
    followers = Array.new(2) do
      follower = Fabricate(:account)
      Fabricate(:follow, account: follower, target_account: account)
      follower
    end

    get "/api/v1/accounts/#{account.id}/followers?limit=1"

    assert_schema_conform(200)
    expect(response).to have_http_status(200)

    response_body = body_as_json
    expect(response_body.length).to eq(1)
    expect(response_body.pluck(:id)).to contain_exactly(followers.last.id.to_s)
  end

  it 'presents pagination by Link header' do
    account = Fabricate(:account)
    followers = Array.new(2) do
      follower = Fabricate(:account)
      Fabricate(:follow, account: follower, target_account: account)
      follower
    end

    get "/api/v1/accounts/#{account.id}/followers?limit=1"

    assert_schema_conform(200)
    expect(response).to have_http_status(200)

    get next_path(response.headers['Link'])

    assert_schema_conform(200)
    expect(response).to have_http_status(200)

    response_body = body_as_json
    expect(response_body.length).to eq(1)
    expect(response_body.pluck(:id)).to contain_exactly(followers.first.id.to_s)

    get prev_path(response.headers['Link'])

    assert_schema_conform(200)
    expect(response).to have_http_status(200)

    response_body = body_as_json
    expect(response_body.length).to eq(1)
    expect(response_body.pluck(:id)).to contain_exactly(followers.last.id.to_s)
  end
end
