# frozen_string_literal: true

class AdminTestMailer < ApplicationMailer
  def preview
    @db_html_body = params[:html_body]
    @db_text_body = params[:text_body]
    mail(
      to: params[:to],
      subject: params[:subject],
      template_path: "application_mailer",
      template_name: "from_db_template"
    )
  end
end
