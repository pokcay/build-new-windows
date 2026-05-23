# frozen_string_literal: true

class Admin::EmailTemplatesController < Admin::BaseController
  before_action :set_template, only: %i[ show update send_test reset_to_default ]

  def index
    templates = EmailTemplate.order(:name).map { |t| template_summary(t) }
    render inertia: "admin/email-templates/Index", props: { templates: }
  end

  def show
    render inertia: "admin/email-templates/Show", props: {
      template: template_detail(@template),
      variables: EmailTemplateConfig.variables_for(@template.key),
      sample_data: EmailTemplateConfig.sample_data_for(@template.key)
    }
  end

  def update
    @template.assign_attributes(template_params)
    @template.updated_by = Current.user
    @template.customized = true

    if @template.save
      redirect_to admin_email_template_path(@template),
                  notice: "Saved at #{Time.current.strftime("%-I:%M %p")}"
    else
      redirect_back(
        fallback_location: admin_email_template_path(@template),
        inertia: { errors: @template.errors.to_hash(true).transform_values(&:first) }
      )
    end
  end

  def send_test
    email = params[:email].to_s.strip
    if email.blank?
      return redirect_back(
        fallback_location: admin_email_template_path(@template),
        alert: "Please enter a recipient email address."
      )
    end

    vars = EmailTemplateConfig.sample_data_for(@template.key)
    subject  = EmailTemplateConfig.substitute(@template.subject, vars)
    html_body = kramdown_html(EmailTemplateConfig.substitute(@template.body_html.to_s, vars))
    text_body = EmailTemplateConfig.substitute(@template.body_text.to_s, vars)

    AdminTestMailer.with(
      to: email,
      subject: "[TEST] #{subject}",
      html_body: html_body,
      text_body: text_body
    ).preview.deliver_now

    redirect_back(
      fallback_location: admin_email_template_path(@template),
      notice: "Test email sent to #{email}."
    )
  rescue => e
    redirect_back(
      fallback_location: admin_email_template_path(@template),
      alert: "Failed to send test email: #{e.message}"
    )
  end

  def reset_to_default
    defaults = EmailTemplateConfig.defaults_for(@template.key)
    if defaults
      @template.update!(
        subject:    defaults[:subject],
        body_html:  defaults[:body_html],
        body_text:  defaults[:body_text],
        customized: false,
        updated_by: Current.user
      )
      redirect_back(
        fallback_location: admin_email_template_path(@template),
        notice: "\"#{@template.name}\" has been reset to its default content."
      )
    else
      redirect_back(
        fallback_location: admin_email_template_path(@template),
        alert: "No default content found for this template."
      )
    end
  end

  private
    def set_template
      @template = EmailTemplate.find(params[:id])
    end

    def template_params
      params.expect(email_template: [ :subject, :body_html, :body_text ])
    end

    def template_summary(template)
      {
        id:           template.id,
        key:          template.key,
        name:         template.name,
        description:  template.description,
        customized:   template.customized,
        updated_at:   template.updated_at.iso8601,
        updater_email: template.updated_by&.email
      }
    end

    def template_detail(template)
      template_summary(template).merge(
        subject:   template.subject,
        body_html: template.body_html,
        body_text: template.body_text
      )
    end

    def kramdown_html(markdown)
      Kramdown::Document.new(markdown).to_html
    end
end
