require "capybara/rspec"

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")           # required in CI sandbox environments
  options.add_argument("--disable-dev-shm-usage") # prevents crashes on low-memory CI runners
  options.add_argument("--window-size=1280,800")

  # Allow local overrides (e.g. Brave) without hardcoding paths in source.
  # Set BROWSER_BINARY in .env.local. Leave unset in CI so Selenium Manager
  # auto-detects the installed Chrome.
  options.binary = ENV["BROWSER_BINARY"] if ENV["BROWSER_BINARY"].present?

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.server = :puma, { Silent: true }
Capybara.default_max_wait_time = 5

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :headless_chrome
  end
end
