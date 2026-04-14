module Api
  class PendingSummariesController < BaseController
    # GET /api/pending_summaries/next
    # Returns the next letter that needs a summary, or {done: true} if none remain.
    def next_pending
      letter = CompleteResponseLetter
        .where(summary: nil)
        .where.not(text: [nil, ""])
        .order(letter_date: :asc, id: :asc)
        .first

      if letter
        render json: {
          file_name:    letter.file_name,
          company_name: letter.company_name,
          text:         letter.text
        }
      else
        render json: { done: true }
      end
    end

    # POST /api/pending_summaries/submit
    # Body: { file_name: "...", summary: "..." }
    def submit
      file_name = params[:file_name].presence
      summary   = params[:summary].presence

      unless file_name && summary
        render json: { error: "file_name and summary are required" }, status: :unprocessable_entity
        return
      end

      letter = CompleteResponseLetter.find_by(file_name: file_name)

      unless letter
        render json: { error: "Letter not found: #{file_name}" }, status: :not_found
        return
      end

      letter.update_columns(summary: summary, summary_generated_at: Time.current)

      render json: { ok: true, file_name: file_name }
    end
  end
end
