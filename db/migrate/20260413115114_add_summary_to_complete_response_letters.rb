class AddSummaryToCompleteResponseLetters < ActiveRecord::Migration[8.1]
  def change
    add_column :complete_response_letters, :summary, :text
    add_column :complete_response_letters, :summary_generated_at, :datetime
  end
end
