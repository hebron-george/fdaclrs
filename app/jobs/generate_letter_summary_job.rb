class GenerateLetterSummaryJob
  include Sidekiq::Job

  sidekiq_options retry: 3

  # Summarise a single letter using Claude Haiku. Skips if the letter has no
  # OCR text or if a summary already exists (pass force: true to regenerate).
  def perform(letter_id, force = false)
    letter = CompleteResponseLetter.find_by(id: letter_id)
    return unless letter
    return if letter.text.blank?
    return if letter.summary.present? && !force

    client = Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))

    response = client.messages(
      model:      "claude-haiku-4-5-20251001",
      max_tokens: 450,
      system:     "You summarize FDA Complete Response Letters concisely for regulatory professionals. " \
                  "Write in plain language. Do not include preamble such as 'Here is a summary'.",
      messages:   [{
        role:    "user",
        content: <<~PROMPT
          Summarize this FDA Complete Response Letter in 2–3 paragraphs (~150–200 words).

          Cover:
          1. The primary deficiencies or issues the FDA identified
          2. What the applicant must address before the application can be approved
          3. Any notable clinical, safety, efficacy, or manufacturing concerns

          Letter text:
          #{letter.text.truncate(50_000)}
        PROMPT
      }]
    )

    summary = response.content.first.text.strip
    letter.update_columns(summary: summary, summary_generated_at: Time.current)

    Rails.logger.info "[GenerateLetterSummaryJob] Summarised letter #{letter_id} (#{letter.file_name})"
  end
end
