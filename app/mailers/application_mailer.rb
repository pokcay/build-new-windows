class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "App <onboarding@resend.dev>")
  default reply_to: ENV["MAIL_REPLY_TO"] if ENV["MAIL_REPLY_TO"].present?
  layout "mailer"

  private
    def substitute_variables(text, vars)
      EmailTemplateConfig.substitute(text, vars)
    end

    def markdown_to_html(markdown)
      Kramdown::Document.new(markdown.to_s).to_html
    end
end
