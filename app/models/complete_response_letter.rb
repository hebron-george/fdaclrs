class CompleteResponseLetter < ApplicationRecord
  scope :search, ->(q) {
    where("search_vector @@ plainto_tsquery('english', ?)", q)
      .order(Arel.sql("ts_rank(search_vector, plainto_tsquery('english', #{connection.quote(q)})) DESC"))
  }

  scope :by_application_number, ->(num) {
    where("application_numbers @> ARRAY[?]::varchar[]", num)
  }
  scope :by_center,       ->(center)  { where("approver_center @> ARRAY[?]::varchar[]", center) }
  scope :by_company,      ->(company) { where("company_name ILIKE ?", "%#{company}%") }
  scope :by_date_range,   ->(from, to){ where(letter_date: from..to) }

  # Guarantees an Array. Uses self[] instead of super to ensure the PG array
  # type cast runs even when the attribute module order is unexpected.
  def approver_center
    coerce_pg_array(self[:approver_center])
  end

  def application_numbers
    coerce_pg_array(self[:application_numbers])
  end

  private

  # Handles Ruby Array, raw PG array literal (e.g. `{"a","b"}`), and nil.
  def coerce_pg_array(val)
    case val
    when Array  then val.compact
    when String
      return [] if val.blank? || val == '{}'
      val.delete_prefix('{').delete_suffix('}')
         .scan(/"[^"]*"|[^,]+/)
         .map { |s| s.delete_prefix('"').delete_suffix('"') }
         .reject(&:blank?)
    else []
    end
  end
end
