# frozen_string_literal: true

class CreateEmailTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :email_templates do |t|
      t.string  :key,        null: false
      t.string  :name,       null: false
      t.text    :description
      t.string  :subject,    null: false, default: ""
      t.text    :body_html
      t.text    :body_text
      t.boolean :customized, null: false, default: false
      t.references :updated_by, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end

    add_index :email_templates, :key, unique: true
  end
end
