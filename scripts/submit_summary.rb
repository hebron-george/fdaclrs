#!/usr/bin/env ruby
# Submits a generated summary for a CRL back to the production server.
#
# Required env vars:
#   FDACLRS_API_URL  — e.g. https://yourapp.com
#   FDACLRS_API_KEY  — value of SUMMARY_API_KEY on the server
#
# Usage:
#   ruby scripts/submit_summary.rb <file_name> <summary>
#
# Example:
#   ruby scripts/submit_summary.rb "example_crl.pdf" "The FDA identified three deficiencies..."

require "net/http"
require "json"
require "uri"

api_url   = ENV.fetch("FDACLRS_API_URL") { abort "Set FDACLRS_API_URL (e.g. https://yourapp.com)" }
api_key   = ENV.fetch("FDACLRS_API_KEY") { abort "Set FDACLRS_API_KEY" }
file_name = ARGV[0] or abort "Usage: ruby scripts/submit_summary.rb <file_name> <summary>"
summary   = ARGV[1] or abort "Usage: ruby scripts/submit_summary.rb <file_name> <summary>"

uri = URI("#{api_url}/api/pending_summaries/submit")
request = Net::HTTP::Post.new(uri)
request["X-Api-Key"]    = api_key
request["Content-Type"] = "application/json"
request["Accept"]       = "application/json"
request.body = JSON.generate(file_name: file_name, summary: summary)

response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
  http.request(request)
end

abort "Request failed: #{response.code} #{response.body}" unless response.is_a?(Net::HTTPSuccess)

puts response.body
