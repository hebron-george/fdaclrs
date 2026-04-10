class CreateCompleteResponseLetters < ActiveRecord::Migration[8.1]
  def up
    create_table :complete_response_letters do |t|
      t.string  :application_number, null: false
      t.string  :letter_type
      t.date    :letter_date
      t.string  :company_name
      t.string  :company_rep
      t.text    :company_address
      t.string  :approver_name
      t.string  :approver_title
      t.string  :approver_center
      t.string  :file_name
      t.text    :text
      t.column  :search_vector, :tsvector
      t.timestamps
    end

    add_index :complete_response_letters, :application_number, unique: true
    add_index :complete_response_letters, :letter_date
    add_index :complete_response_letters, :approver_center
    add_index :complete_response_letters, :company_name
    add_index :complete_response_letters, :search_vector, using: :gin

    execute <<~SQL
      CREATE FUNCTION complete_response_letters_search_vector_update() RETURNS trigger AS $$
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

      CREATE TRIGGER complete_response_letters_search_vector_trigger
        BEFORE INSERT OR UPDATE ON complete_response_letters
        FOR EACH ROW EXECUTE PROCEDURE complete_response_letters_search_vector_update();
    SQL
  end

  def down
    execute <<~SQL
      DROP TRIGGER IF EXISTS complete_response_letters_search_vector_trigger ON complete_response_letters;
      DROP FUNCTION IF EXISTS complete_response_letters_search_vector_update();
    SQL
    drop_table :complete_response_letters
  end
end
