require "rails_helper"

RSpec.describe NewCrlNotificationJob, type: :job do
  let(:user) { User.create!(email: "user@example.com", password: "password123") }

  def create_letter(attrs = {})
    defaults = {
      file_name:           "letter_#{SecureRandom.hex(4)}.pdf",
      application_numbers: ["BLA125012"],
      letter_type:         "COMPLETE RESPONSE",
      letter_date:         Date.new(2023, 6, 15),
      company_name:        "Example Therapeutics",
      approver_center:     ["Center for Biologics Evaluation and Research"],
      approver_name:       "Dr. Jane Smith",
      text:                "gene therapy lentiviral"
    }
    CompleteResponseLetter.create!(defaults.merge(attrs))
  end

  def create_subscription(filters: {})
    Subscription.create!(user: user, name: "Test Sub", filters: filters)
  end

  subject(:job) { described_class.new }

  it "does nothing when new_file_names is empty" do
    create_subscription(filters: {})
    expect { job.perform([]) }.not_to change { ActionMailer::Base.deliveries.count }
  end

  it "enqueues a mailer for each matching subscription" do
    letter = create_letter
    matching_sub    = create_subscription(filters: { "company" => "example" })
    non_matching_sub = create_subscription(filters: { "company" => "NoMatch Corp" })  # rubocop:disable Lint/UselessAssignment

    expect {
      job.perform([letter.file_name])
    }.to change { ActionMailer::Base.deliveries.count }.by(1)

    email = ActionMailer::Base.deliveries.last
    expect(email.to).to eq([user.email])
  end

  it "does not notify for inactive subscriptions" do
    letter = create_letter
    sub = create_subscription(filters: {})
    sub.deactivate!

    expect { job.perform([letter.file_name]) }.not_to change { ActionMailer::Base.deliveries.count }
  end

  it "notifies multiple subscribers when they all match" do
    letter = create_letter
    user2 = User.create!(email: "user2@example.com", password: "password123")
    Subscription.create!(user: user,  name: "Sub 1", filters: {})
    Subscription.create!(user: user2, name: "Sub 2", filters: {})

    expect { job.perform([letter.file_name]) }.to change { ActionMailer::Base.deliveries.count }.by(2)
  end
end
