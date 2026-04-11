class ChangeApproverCenterToArray < ActiveRecord::Migration[8.1]
  def up
    # 1. Rename the old string column so we can read it during data migration
    rename_column :complete_response_letters, :approver_center, :approver_center_legacy

    # 2. Add the new array column
    add_column :complete_response_letters, :approver_center, :string, array: true, default: []
    add_index  :complete_response_letters, :approver_center, using: :gin

    # 3. Update the tsvector trigger BEFORE migrating data so it handles the new array column type
    execute <<~SQL
      CREATE OR REPLACE FUNCTION complete_response_letters_search_vector_update()
      RETURNS trigger AS $$
      BEGIN
        NEW.search_vector :=
          setweight(to_tsvector('english', coalesce(array_to_string(NEW.application_numbers, ' '), '')), 'A') ||
          setweight(to_tsvector('english', coalesce(NEW.company_name, '')), 'A') ||
          setweight(to_tsvector('english', coalesce(NEW.approver_name, '')), 'B') ||
          setweight(to_tsvector('english', coalesce(array_to_string(NEW.approver_center, ' '), '')), 'B') ||
          setweight(to_tsvector('english', coalesce(NEW.text, '')), 'C');
        RETURN NEW;
      END
      $$ LANGUAGE plpgsql;
    SQL

    # 4. Migrate existing data — legacy values are Ruby/JSON array literals, e.g. `["CBER", "CDER"]`
    CompleteResponseLetter.reset_column_information
    CompleteResponseLetter.find_each do |letter|
      legacy = letter.approver_center_legacy
      parsed = if legacy.present? && legacy.start_with?("[")
                 begin
                   JSON.parse(legacy).compact
                 rescue JSON::ParserError
                   [legacy]
                 end
               elsif legacy.present?
                 [legacy]
               else
                 []
               end
      letter.update_columns(approver_center: parsed)
    end

    # 5. Drop the legacy column
    remove_column :complete_response_letters, :approver_center_legacy
  end

  def down
    rename_column :complete_response_letters, :approver_center, :approver_center_array
    add_column :complete_response_letters, :approver_center, :string

    CompleteResponseLetter.reset_column_information
    CompleteResponseLetter.find_each do |letter|
      letter.update_columns(approver_center: letter.approver_center_array&.first)
    end

    remove_column :complete_response_letters, :approver_center_array

    execute <<~SQL
      CREATE OR REPLACE FUNCTION complete_response_letters_search_vector_update()
      RETURNS trigger AS $$
      BEGIN
        NEW.search_vector :=
          setweight(to_tsvector('english', coalesce(array_to_string(NEW.application_numbers, ' '), '')), 'A') ||
          setweight(to_tsvector('english', coalesce(NEW.company_name, '')), 'A') ||
          setweight(to_tsvector('english', coalesce(NEW.approver_name, '')), 'B') ||
          setweight(to_tsvector('english', coalesce(NEW.approver_center, '')), 'B') ||
          setweight(to_tsvector('english', coalesce(NEW.text, '')), 'C');
        RETURN NEW;
      END
      $$ LANGUAGE plpgsql;
    SQL
  end
end
