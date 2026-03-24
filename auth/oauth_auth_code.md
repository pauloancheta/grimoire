# Auth: OAuth: Authorization Code Flow

In the past few years, I've been assigned to authorization related work. Knowing how to authenticate
via OAuth without using different libraries is a great skill to have because we are just relying on
the IETF standards

```ruby
# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'pry'

# OAuth 2.0 + GraphQL API client for local Zipline development.
#
# Each step of the Authorization Code flow is a separate method so you can
# drop into pry and call them one at a time, inspecting the result at each stage.
#
# Quick start:
#   client = GraphqlOauth.new(client_id: "...", client_secret: "...")
#   client.authorization_url                                             # Step 1
#   tokens = client.exchange_code_for_token(code: "...")                 # Step 2
#   result  = client.graphql_query(access_token: tokens["access_token"],
#                                  query: "query { viewer { id name } }")
#
# Prerequisite — create an OauthApplication in the public tenant (run once):
#
#   rails runner - <<'RUBY'
#   Apartment::Tenant.switch('public') do
#     app = OauthApplication.find_or_create_by!(name: 'GraphQL API Testing') do |a|
#       a.redirect_uri = 'urn:ietf:wg:oauth:2.0:oob'
#       a.organizations = ['zipline']
#       a.scopes = 'read write'
#     end
#     puts "client_id:     #{app.uid}"
#     puts "client_secret: #{app.secret}"
#   end
#   RUBY
class GraphqlOauth
  BASE_URL = "https://admin.example.test"
  OOB_URI  = "urn:ietf:wg:oauth:2.0:oob"

  def initialize(client_id:, client_secret:)
    @client_id     = client_id
    @client_secret = client_secret
  end

  # Step 1: Build the authorization URL and print it.
  #
  # Open the returned URL in a browser. Log in and approve the app.
  # With the OOB redirect, Doorkeeper shows the authorization code on-screen
  # instead of redirecting — copy it and pass it to `#exchange_code_for_token`.
  #
  # Returns the authorization URL string.
  def authorization_url(scope: "read write", state: SecureRandom.hex(16))
    params = URI.encode_www_form(
      response_type: "code",
      client_id: @client_id,
      redirect_uri: OOB_URI,
      scope: scope,
      state: state
    )
    url = "#{BASE_URL}/oauth/authorize?#{params}"
    puts "Open this URL in your browser and approve the app:\n\n  #{url}\n\n"
    puts "Copy the code shown and call #exchange_code_for_token(code: ...)."
    url
  end

  # Step 2: Exchange an authorization code for tokens.
  #
  # Returns a hash with:
  #   "access_token"  - Bearer token for API calls
  #   "refresh_token" - Use with `#refresh_access_token` when the token expires
  #   "expires_in"    - Seconds until the access token expires (typically 7200)
  #   "scope"         - Granted scopes
  def exchange_code_for_token(code:)
    params = {
      grant_type: "authorization_code",
      code: code,
      client_id: @client_id,
      client_secret: @client_secret,
      redirect_uri: OOB_URI
    }
    body = post_form("/oauth/token", params)
    raise_on_error(body)
    print_token_info(body)
    body
  end

  # Step 2 (alternative): Password credentials flow — no browser required.
  #
  # Only works when:
  #   - OrganizationSetting.enable_resource_owner_from_credentials is true
  #   - The requesting IP is safelisted
  #   - The user has the `oauth.access-control` feature flag enabled
  #
  # Returns the same token hash as `#exchange_code_for_token`.
  def password_token(username:, password:, scope: "read write")
    params = {
      grant_type: "password",
      username: username,
      password: password,
      client_id: @client_id,
      client_secret: @client_secret,
      scope: scope
    }
    body = post_form("/oauth/token", params)
    raise_on_error(body)
    print_token_info(body)
    body
  end

  # Step 3 (optional): Refresh an expired access token.
  #
  # The old refresh token is invalidated — use the new one returned in the response.
  #
  # Returns the same token hash shape as `#exchange_code_for_token`.
  def refresh_access_token(refresh_token:)
    params = {
      grant_type: "refresh_token",
      refresh_token: refresh_token,
      client_id: @client_id,
      client_secret: @client_secret
    }
    body = post_form("/oauth/token", params)
    raise_on_error(body)
    print_token_info(body)
    body
  end

  # Step 4: Execute a GraphQL query.
  #
  # `access_token` - the "access_token" string from any token method above
  # `query`        - GraphQL query string
  # `variables`    - optional hash of query variables
  #
  # Returns the parsed JSON response body.
  def graphql_query(access_token:, query:, variables: {})
    body = JSON.parse(execute_graphql(access_token, query, variables).body)
    print_graphql_errors(body["errors"]) if body["errors"]
    body
  end

  private

  def build_http(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http
  end

  def post_form(path, params)
    uri = URI("#{BASE_URL}#{path}")
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/x-www-form-urlencoded"
    request["Accept"] = "application/json"
    request.body = URI.encode_www_form(params)
    JSON.parse(build_http(uri).request(request).body)
  end

  def execute_graphql(access_token, query, variables)
    uri = URI("#{BASE_URL}/api/graphql")
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"
    request["Authorization"] = "Bearer #{access_token}"
    request.body = { query: query, variables: variables }.to_json
    build_http(uri).request(request)
  end

  def raise_on_error(body)
    raise "OAuth error: #{body['error']} — #{body['error_description']}" if body["error"]
  end

  def print_token_info(body)
    puts "Access token:  #{body['access_token']}"
    puts "Refresh token: #{body['refresh_token']}"
    puts "Expires in:    #{body['expires_in']}s"
  end

  def print_graphql_errors(errors)
    puts "GraphQL errors:"
    errors.each { |error| puts "  - #{error['message']}" }
  end
end

CLIENT_ID     = "thvR_l-7KAbi8oUwmQ-hgDEsPbE-srlUyhaIgDzahoQ" # ENV.fetch("OAUTH_CLIENT_ID", "PASTE_CLIENT_ID_HERE")
CLIENT_SECRET = "1bj3fX457NK9IguPjEE2KtY3xsXOwoHZ6Ta1Ht9X-2s" # ENV.fetch("OAUTH_CLIENT_SECRET", "PASTE_CLIENT_SECRET_HERE")

client = GraphqlOauth.new(client_id: CLIENT_ID, client_secret: CLIENT_SECRET)

puts "GraphqlOauth client ready. Use `client` to step through the OAuth flow."
puts "  client.authorization_url                                           # Step 1"
puts "  client.exchange_code_for_token(code: '...')                        # Step 2"
puts "  client.password_token(username: '...', password: '...')            # Alt step 2"
puts "  client.refresh_access_token(refresh_token: tokens['refresh_token'])# Step 3"
puts "  client.graphql_query(access_token: '...', query: '...')            # Step 4"
puts

```
