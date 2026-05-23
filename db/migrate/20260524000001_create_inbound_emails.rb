# frozen_string_literal: true

class CreateInboundEmails < ActiveRecord::Migration[8.0]
  def change
    create_table :inbound_emails do |t|
      t.string   :from,        null: false
      t.string   :to,          null: false
      t.string   :reply_to
      t.string   :subject
      t.text     :body_html
      t.text     :body_text
      t.datetime :received_at, null: false
      t.boolean  :read,        null: false, default: false
      t.boolean  :archived,    null: false, default: false
      t.text     :raw_payload

      t.timestamps
    end

    add_index :inbound_emails, [ :archived, :read, :received_at ]
    add_index :inbound_emails, [ :to, :archived ]
  end
end
