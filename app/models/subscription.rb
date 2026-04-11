class Subscription < ApplicationRecord
  belongs_to :user

  validates :name,              presence: true
  validates :unsubscribe_token, presence: true, uniqueness: true

  before_validation :generate_unsubscribe_token, on: :create

  scope :active, -> { where(active: true) }

  # Returns true if this subscription's saved filters match the given letter.
  # All present filter keys must match (AND logic).
  def matches?(letter)
    match_query?(letter)      &&
      match_center?(letter)   &&
      match_company?(letter)  &&
      match_application_number?(letter) &&
      match_date_range?(letter)
  end

  def deactivate!
    update!(active: false)
  end

  private

  def generate_unsubscribe_token
    self.unsubscribe_token ||= SecureRandom.urlsafe_base64(32)
  end

  def match_query?(letter)
    q = filters["q"].presence
    return true unless q

    searchable = [
      letter.company_name,
      letter.approver_name,
      *letter.approver_center,
      *letter.application_numbers,
      letter.text
    ].compact.join(" ").downcase

    q.downcase.split.all? { |term| searchable.include?(term) }
  end

  def match_center?(letter)
    center = filters["center"].presence
    return true unless center

    letter.approver_center.any? { |c| c.casecmp?(center) }
  end

  def match_company?(letter)
    company = filters["company"].presence
    return true unless company

    letter.company_name.to_s.downcase.include?(company.downcase)
  end

  def match_application_number?(letter)
    app_num = filters["application_number"].presence
    return true unless app_num

    letter.application_numbers.any? { |n| n.downcase.include?(app_num.downcase) }
  end

  def match_date_range?(letter)
    date_from = filters["date_from"].presence
    date_to   = filters["date_to"].presence
    return true unless date_from || date_to

    return false unless letter.letter_date

    date = letter.letter_date
    (date_from.nil? || date >= Date.parse(date_from)) &&
      (date_to.nil?   || date <= Date.parse(date_to))
  end
end
