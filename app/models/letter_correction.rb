class LetterCorrection < ApplicationRecord
  belongs_to :complete_response_letter
  belongs_to :user

  # Fields the admin is allowed to correct. Value is the field type,
  # used by the controller to parse submitted form values correctly.
  CORRECTABLE_FIELDS = {
    "letter_date"         => :date,
    "company_name"        => :string,
    "letter_type"         => :string,
    "approver_name"       => :string,
    "approver_title"      => :string,
    "company_rep"         => :string,
    "application_numbers" => :string_array,
    "approver_center"     => :string_array,
  }.freeze

  validates :field_name, inclusion: { in: CORRECTABLE_FIELDS.keys }
  validates :corrected_value, presence: true

  scope :for_field, ->(field) { where(field_name: field.to_s) }
  scope :chronological, -> { order(created_at: :asc) }
end
