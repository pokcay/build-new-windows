# frozen_string_literal: true

class Webhooks::InboundEmailsController < ActionController::Base
  skip_before_action :verify_authenticity_token

  def create
    unless valid_secret?
      return head :unauthorized
    end

    body = request.body.read
    data = JSON.parse(body)

    InboundEmail.create!(
      from:        data["from"].to_s,
      to:          data["to"].to_s,
      reply_to:    data["reply_to"],
      subject:     data["subject"],
      body_html:   data["body_html"],
      body_text:   data["body_text"],
      received_at: data["received_at"].presence || Time.current,
      raw_payload: body
    )

    head :ok
  rescue JSON::ParserError
    head :bad_request
  rescue => e
    Rails.logger.error "Inbound email webhook error: #{e.message}"
    head :internal_server_error
  end

  private
    def valid_secret?
      expected = Rails.application.credentials.inbound_email_webhook_secret ||
                 ENV["INBOUND_EMAIL_WEBHOOK_SECRET"]
      return false if expected.blank?

      ActiveSupport::SecurityUtils.secure_compare(
        request.headers["X-Webhook-Secret"].to_s,
        expected.to_s
      )
    end
end
