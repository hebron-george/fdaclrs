require "net/http"

class CompleteResponseLettersController < ApplicationController
  CBER = "Center for Biologics Evaluation and Research"

  def index
    @centers = CompleteResponseLetter
                 .pluck(Arel.sql("unnest(approver_center)"))
                 .uniq.compact.sort

    # Default center to CBER on first load (no params at all)
    @selected_center = params.key?(:q) || params.key?(:center) ? params[:center] : CBER

    scope = CompleteResponseLetter.all

    if params[:q].present?
      scope = scope.search(params[:q])
    else
      scope = scope.order(letter_date: :desc)
    end

    scope = scope.by_center(@selected_center)             if @selected_center.present?
    scope = scope.by_company(params[:company])            if params[:company].present?
    scope = scope.by_application_number(params[:application_number]) if params[:application_number].present?

    if params[:date_from].present? || params[:date_to].present?
      date_from = params[:date_from].presence || "1900-01-01"
      date_to   = params[:date_to].presence   || Date.current.to_s
      scope = scope.by_date_range(date_from, date_to)
    end

    @pagy, @letters = pagy(:offset, scope)
    @filters_active = %i[q center company application_number date_from date_to].any? { |k| params[k].present? }

    if params[:q].present? && @letters.any?
      quoted_q = ActiveRecord::Base.connection.quote(params[:q])
      letter_ids = @letters.map(&:id)

      fts_headlines = CompleteResponseLetter
        .where(id: letter_ids)
        .where("search_vector @@ plainto_tsquery('english', ?)", params[:q])
        .pluck(:id, Arel.sql("ts_headline('english', coalesce(text, ''), plainto_tsquery('english', #{quoted_q}), 'MaxWords=35, MinWords=15, StartSel=<mark>, StopSel=</mark>')"))
        .to_h

      ilike_ids = letter_ids - fts_headlines.keys
      ilike_headlines = CompleteResponseLetter
        .where(id: ilike_ids)
        .pluck(:id, :text)
        .to_h { |id, text| [id, ilike_snippet(text, params[:q])] }

      @headlines = fts_headlines.merge(ilike_headlines)
    end
  end

  def show
    @letter = CompleteResponseLetter.includes(:letter_corrections).find(params[:id])
  end

  def pdf
    letter = CompleteResponseLetter.find(params[:id])

    unless letter.file_name.present?
      head :not_found and return
    end

    data = fetch_fda_pdf(letter.file_name)

    if data
      send_data data, type: "application/pdf", disposition: "inline",
                      filename: letter.file_name
    else
      head :not_found
    end
  end

  private

  def ilike_snippet(text, q)
    return "" if text.blank?
    pos = text.downcase.index(q.downcase)
    return ERB::Util.html_escape(text.first(200)) unless pos
    start = [pos - 80, 0].max
    raw_snippet = text[start, 200] || ""
    ERB::Util.html_escape(raw_snippet)
              .gsub(/#{Regexp.escape(ERB::Util.html_escape(q))}/i, '<mark>\0</mark>')
  end

  # Fetches a PDF from the FDA CDN, following up to 3 redirects.
  # Returns the raw binary string on success, nil on any failure.
  def fetch_fda_pdf(file_name)
    uri = URI("https://download.open.fda.gov/crl/#{file_name}")

    3.times do
      req = Net::HTTP::Get.new(uri)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                                 open_timeout: 10, read_timeout: 20) do |http|
        http.request(req)
      end

      case response
      when Net::HTTPSuccess
        return response.body
      when Net::HTTPRedirection
        uri = URI(response["Location"])
      else
        return nil
      end
    end

    nil
  rescue SocketError, Net::OpenTimeout, Net::ReadTimeout, URI::InvalidURIError
    nil
  end
end
