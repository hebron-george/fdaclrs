class HomeController < ApplicationController
  def index
    @total_letters     = CompleteResponseLetter.count
    @most_recent_date  = CompleteResponseLetter.maximum(:letter_date)
    @letters_by_center = CompleteResponseLetter
                           .group(Arel.sql("unnest(approver_center)"))
                           .order(Arel.sql("count(*) DESC"))
                           .count
    @last_sync = SystemSetting.get("last_crl_sync_at")
  end
end
