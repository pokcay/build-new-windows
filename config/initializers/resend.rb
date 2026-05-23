# frozen_string_literal: true

# Resend transactional email. The key is read from Rails encrypted credentials
# first, falling back to ENV. Set it via `rails credentials:edit` (resend_api_key)
# or in .env (RESEND_API_KEY).
Resend.api_key = Rails.application.credentials.resend_api_key || ENV["RESEND_API_KEY"]
