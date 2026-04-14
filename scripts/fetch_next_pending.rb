#!/usr/bin/env ruby
# Fetches the next CRL that needs a summary from the production server.
#
# Required env vars:
#   FDACLRS_API_URL  — e.g. https://yourapp.com
#   FDACLRS_API_KEY  — value of SUMMARY_API_KEY on the server
#
# Usage:
#   ruby scripts/fetch_next_pending.rb

require "net/http"
require "json"
require "uri"

api_url = ENV.fetch("FDACLRS_API_URL") { abort "Set FDACLRS_API_URL (e.g. https://yourapp.com)" }
api_key = ENV.fetch("FDACLRS_API_KEY") { abort "Set FDACLRS_API_KEY" }

uri = URI("#{api_url}/api/pending_summaries/next")
request = Net::HTTP::Get.new(uri)
request["X-Api-Key"] = api_key
request["Accept"]    = "application/json"

response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
  http.request(request)
end

abort "Request failed: #{response.code} #{response.body}" unless response.is_a?(Net::HTTPSuccess)

puts response.body
