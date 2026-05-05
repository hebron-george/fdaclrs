class CompleteResponseLetter < ApplicationRecord
  has_many :letter_corrections, dependent: :destroy

  # Returns true if the given field has at least one admin correction on record.
  def corrected?(field)
    if letter_corrections.loaded?
      letter_corrections.any? { |c| c.field_name == field.to_s }
    else
      letter_corrections.exists?(field_name: field.to_s)
    end
  end

  # The original API value for a field — taken from the earliest correction log
  # entry, which recorded what the column held before the first correction.
  def api_original(field)
    correction = if letter_corrections.loaded?
      letter_corrections.select { |c| c.field_name == field.to_s }.min_by(&:created_at)
    else
      letter_corrections.for_field(field).chronological.first
    end
    correction&.original_value
  end
  scope :search, ->(q) {
    quoted_q = connection.quote(q)
    where(
      "search_vector @@ plainto_tsquery('english', ?) OR text ILIKE ?",
      q, "%#{q}%"
    ).order(Arel.sql("ts_rank(search_vector, plainto_tsquery('english', #{quoted_q})) DESC"))
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
