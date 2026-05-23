# frozen_string_literal: true

class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    template = EmailTemplate.find_by(key: "password_reset")
    if template
      vars = {
        "user.email" => user.email,
        "reset_url"  => edit_password_url(user.password_reset_token)
      }
      @db_html_body = markdown_to_html(substitute_variables(template.body_html.to_s, vars))
      @db_text_body = substitute_variables(template.body_text.to_s, vars)
      return mail(
        to: user.email,
        subject: substitute_variables(template.subject, vars),
        template_path: "application_mailer",
        template_name: "from_db_template"
      )
    end
    mail subject: "Reset your password", to: user.email
  end
end
