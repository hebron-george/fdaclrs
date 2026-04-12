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
      @headlines = CompleteResponseLetter
        .where(id: @letters.map(&:id))
        .pluck(:id, Arel.sql("ts_headline('english', coalesce(text, ''), plainto_tsquery('english', #{quoted_q}), 'MaxWords=35, MinWords=15, StartSel=<mark>, StopSel=</mark>')"))
        .to_h
    end
  end

  def show
    @letter = CompleteResponseLetter.includes(:letter_corrections).find(params[:id])
  end
end
