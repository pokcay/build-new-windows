# frozen_string_literal: true

module EmailTemplateConfig
  DEFAULTS = [
    {
      key: "password_reset",
      name: "Password reset",
      description: "Sent when a user requests a password reset link.",
      subject: "Reset your password",
      body_html: <<~MARKDOWN.strip,
        Hi {{user.email}},

        You can reset your password within the next **15 minutes** by clicking the link below.

        [Reset your password]({{reset_url}})

        If you didn't request a password reset, you can safely ignore this email.
      MARKDOWN
      body_text: <<~TEXT.strip
        Hi {{user.email}},

        You can reset your password within the next 15 minutes by visiting:

        {{reset_url}}

        If you didn't request a password reset, you can safely ignore this email.
      TEXT
    }
  ].freeze

  VARIABLES = {
    "password_reset" => [
      { key: "{{user.email}}", label: "User's email address" },
      { key: "{{reset_url}}", label: "Password reset link" }
    ]
  }.freeze

  SAMPLE_DATA = {
    "password_reset" => {
      "user.email" => "alex@example.com",
      "reset_url" => "https://example.com/passwords/abc123def456/edit"
    }
  }.freeze

  def self.substitute(text, vars)
    return "" if text.nil?
    text.gsub(/\{\{([^}]+)\}\}/) { vars[$1] || "{{#{$1}}}" }
  end

  def self.defaults_for(key)
    DEFAULTS.find { |d| d[:key] == key }
  end

  def self.variables_for(key)
    VARIABLES.fetch(key, [])
  end

  def self.sample_data_for(key)
    SAMPLE_DATA.fetch(key, {})
  end
end
