require "rails_helper"

RSpec.describe "Sign up, browse, and subscribe to search alerts", type: :system do
  let(:email)    { "e2e_tester@example.com" }
  let(:password) { "password123" }

  it "walks a new user through registration, sign-in, search, and subscription" do
    # ------------------------------------------------------------------ #
    # 1. Land on the home page                                            #
    # ------------------------------------------------------------------ #
    visit root_path
    expect(page).to have_content("FDA Complete Response Letter Explorer")

    # ------------------------------------------------------------------ #
    # 2. Navigate to the sign-up form                                     #
    # ------------------------------------------------------------------ #
    click_link "Sign in"
    expect(page).to have_content("Welcome back")

    click_link "Sign up"
    expect(page).to have_content("Create your account")

    # ------------------------------------------------------------------ #
    # 3. Register a new account                                           #
    # ------------------------------------------------------------------ #
    fill_in "Email", with: email
    fill_in "Password", with: password
    fill_in "Password confirmation", with: password
    click_button "Create account"

    # ------------------------------------------------------------------ #
    # 4. After registration the app redirects back to the sign-in page    #
    # ------------------------------------------------------------------ #
    expect(page).to have_current_path(new_user_session_path)
    expect(page).to have_content("Welcome back")

    # ------------------------------------------------------------------ #
    # 5. Sign in with the newly created credentials                       #
    # ------------------------------------------------------------------ #
    fill_in "Email", with: email
    fill_in "Password", with: password
    click_button "Sign in"

    expect(page).to have_content("Sign out")  # nav confirms sign-in

    # ------------------------------------------------------------------ #
    # 6. Go to the Browse page                                            #
    # ------------------------------------------------------------------ #
    click_link "Browse"
    expect(page).to have_current_path(complete_response_letters_path)

    # ------------------------------------------------------------------ #
    # 7. Search for "BLA"                                                 #
    # ------------------------------------------------------------------ #
    fill_in "Search", with: "BLA"
    click_button "Apply Filters"

    expect(page).to have_current_path(%r{q=BLA})

    # ------------------------------------------------------------------ #
    # 8. Subscribe to this search                                         #
    # ------------------------------------------------------------------ #
    fill_in "subscription[name]", with: "BLA Alerts"
    click_button "Save this search"

    # ------------------------------------------------------------------ #
    # 9. Verify the subscription was saved                                #
    # ------------------------------------------------------------------ #
    expect(page).to have_current_path(subscriptions_path)
    expect(page).to have_content("BLA Alerts")

    expect(Subscription.count).to eq(1)
    subscription = Subscription.first
    expect(subscription.name).to eq("BLA Alerts")
    expect(subscription.filters["q"]).to eq("BLA")
    expect(subscription.active).to be(true)
  end
end
