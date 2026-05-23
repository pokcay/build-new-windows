require "test_helper"

class Webhooks::InboundEmailsControllerTest < ActionDispatch::IntegrationTest
  VALID_SECRET = "test-webhook-secret-abc123"

  setup do
    @original_secret = ENV["INBOUND_EMAIL_WEBHOOK_SECRET"]
    ENV["INBOUND_EMAIL_WEBHOOK_SECRET"] = VALID_SECRET
  end

  teardown do
    ENV["INBOUND_EMAIL_WEBHOOK_SECRET"] = @original_secret
  end

  test "valid secret and valid JSON creates an InboundEmail" do
    assert_difference -> { InboundEmail.count }, 1 do
      post webhooks_inbound_email_path,
           params: valid_payload.to_json,
           headers: {
             "Content-Type" => "application/json",
             "X-Webhook-Secret" => VALID_SECRET
           }
    end
    assert_response :ok

    email = InboundEmail.last
    assert_equal "sender@external.com", email.from
    assert_equal "hello@example.com", email.to
    assert_equal "Test subject", email.subject
    assert_not email.read
    assert_not email.archived
  end

  test "missing or wrong secret returns 401 and creates no record" do
    assert_no_difference -> { InboundEmail.count } do
      post webhooks_inbound_email_path,
           params: valid_payload.to_json,
           headers: {
             "Content-Type" => "application/json",
             "X-Webhook-Secret" => "wrong-secret"
           }
    end
    assert_response :unauthorized
  end

  test "missing secret header returns 401" do
    assert_no_difference -> { InboundEmail.count } do
      post webhooks_inbound_email_path,
           params: valid_payload.to_json,
           headers: { "Content-Type" => "application/json" }
    end
    assert_response :unauthorized
  end

  test "malformed JSON returns 400" do
    assert_no_difference -> { InboundEmail.count } do
      post webhooks_inbound_email_path,
           params: "not json {{{",
           headers: {
             "Content-Type" => "application/json",
             "X-Webhook-Secret" => VALID_SECRET
           }
    end
    assert_response :bad_request
  end

  test "missing secret env var treats all requests as unauthorized" do
    ENV.delete("INBOUND_EMAIL_WEBHOOK_SECRET")
    assert_no_difference -> { InboundEmail.count } do
      post webhooks_inbound_email_path,
           params: valid_payload.to_json,
           headers: {
             "Content-Type" => "application/json",
             "X-Webhook-Secret" => VALID_SECRET
           }
    end
    assert_response :unauthorized
  end

  private
    def valid_payload
      {
        from: "sender@external.com",
        to: "hello@example.com",
        subject: "Test subject",
        reply_to: nil,
        body_html: "<p>Hello</p>",
        body_text: "Hello",
        received_at: Time.current.iso8601
      }
    end
end
