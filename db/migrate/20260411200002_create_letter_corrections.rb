class CreateLetterCorrections < ActiveRecord::Migration[8.1]
  def change
    create_table :letter_corrections do |t|
      t.references :complete_response_letter, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true

      t.string :field_name,      null: false
      t.text   :original_value             # JSON-serialized value from the API
      t.text   :corrected_value, null: false
      t.text   :note                       # optional admin explanation

      t.timestamps
    end

    add_index :letter_corrections, [:complete_response_letter_id, :field_name],
              name: "index_letter_corrections_on_letter_and_field"
  end
end
