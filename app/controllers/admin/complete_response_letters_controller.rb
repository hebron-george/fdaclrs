module Admin
  class CompleteResponseLettersController < BaseController
    def index
      scope = CompleteResponseLetter
        .select("complete_response_letters.*, COUNT(letter_corrections.id) AS corrections_count")
        .left_outer_joins(:letter_corrections)
        .group("complete_response_letters.id")
        .order(letter_date: :desc, id: :desc)

      @pagy, @letters = pagy(:offset, scope)
    end

    def edit
      @letter = CompleteResponseLetter.includes(:letter_corrections).find(params[:id])
      # Group correction logs by field for easy lookup in the view
      @corrections_by_field = @letter.letter_corrections
        .sort_by(&:created_at)
        .group_by(&:field_name)
    end

    def update
      @letter = CompleteResponseLetter.includes(:letter_corrections).find(params[:id])

      corrections = params[:corrections]&.permit(*LetterCorrection::CORRECTABLE_FIELDS.keys).to_h
      notes       = params[:notes]&.permit(*LetterCorrection::CORRECTABLE_FIELDS.keys).to_h

      changed = apply_corrections(@letter, corrections, notes)

      if changed.any?
        notice = "#{changed.size} field#{"s" if changed.size > 1} corrected: #{changed.join(", ")}."
      else
        notice = "No changes detected."
      end

      redirect_to edit_admin_complete_response_letter_path(@letter), notice: notice
    end

    private

    # Parses submitted values, diffs against current column values, logs
    # any changes, and updates the record. Returns the list of changed field names.
    def apply_corrections(letter, corrections, notes)
      changed = []

      LetterCorrection::CORRECTABLE_FIELDS.each do |field, type|
        next unless corrections.key?(field)

        raw       = corrections[field]
        parsed    = parse_value(raw, type)
        current   = current_value(letter, field, type)

        next if parsed == current  # nothing to do

        # Serialize original + new values for the audit log
        original_serialized  = serialize_value(current, type)
        corrected_serialized = serialize_value(parsed, type)

        LetterCorrection.create!(
          complete_response_letter: letter,
          user:                     current_user,
          field_name:               field,
          original_value:           original_serialized,
          corrected_value:          corrected_serialized,
          note:                     notes[field].presence
        )

        letter.assign_attributes(field => parsed)
        changed << field.humanize
      end

      letter.save!(validate: false) if changed.any?
      changed
    end

    def parse_value(raw, type)
      return nil if raw.blank?
      case type
      when :date
        Date.parse(raw) rescue nil
      when :string_array
        raw.split(/[,\n]/).map(&:strip).reject(&:blank?)
      else
        raw.strip.presence
      end
    end

    def current_value(letter, field, type)
      raw = letter[field]
      case type
      when :string_array then Array(raw).compact
      else raw
      end
    end

    def serialize_value(value, type)
      case type
      when :string_array then value.to_a.to_json
      when :date         then value&.iso8601
      else value.to_s
      end
    end
  end
end
