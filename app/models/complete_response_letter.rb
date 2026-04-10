class CompleteResponseLetter < ApplicationRecord
  scope :search, ->(q) {
    where("search_vector @@ plainto_tsquery('english', ?)", q)
      .order(Arel.sql("ts_rank(search_vector, plainto_tsquery('english', #{connection.quote(q)})) DESC"))
  }

  scope :by_center, ->(center) { where(approver_center: center) }
  scope :by_company, ->(company) { where("company_name ILIKE ?", "%#{company}%") }
  scope :by_date_range, ->(from, to) { where(letter_date: from..to) }
end
