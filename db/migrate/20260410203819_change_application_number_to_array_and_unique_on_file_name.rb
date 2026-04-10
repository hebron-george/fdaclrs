class ChangeApplicationNumberToArrayAndUniqueOnFileName < ActiveRecord::Migration[8.1]
  def up
    remove_index  :complete_response_letters, :application_number
    remove_column :complete_response_letters, :application_number

    add_column :complete_response_letters, :application_numbers, :string, array: true, default: []
    add_index  :complete_response_letters, :application_numbers, using: :gin
    add_index  :complete_response_letters, :file_name, unique: true

    # Update the trigger to fold the array into the search vector
    execute <<~SQL
      CREATE OR REPLACE FUNCTION complete_response_letters_search_vector_update() RETURNS trigger AS $$
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

  def down
    remove_index  :complete_response_letters, :file_name
    remove_index  :complete_response_letters, :application_numbers
    remove_column :complete_response_letters, :application_numbers

    add_column :complete_response_letters, :application_number, :string, null: false, default: ""
    add_index  :complete_response_letters, :application_number, unique: true

    execute <<~SQL
      CREATE OR REPLACE FUNCTION complete_response_letters_search_vector_update() RETURNS trigger AS $$
      BEGIN
        NEW.search_vector :=
          setweight(to_tsvector('english', coalesce(NEW.application_number, '')), 'A') ||
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
