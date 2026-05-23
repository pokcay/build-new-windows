# frozen_string_literal: true

class Admin::InboundEmailsController < Admin::BaseController
  PER_PAGE = 20

  before_action :set_email, only: %i[ show update ]

  def index
    scope = tab_scope
    scope = scope.where(to: params[:recipient]) if params[:recipient].present?

    total  = scope.count
    page   = (params[:page] || 1).to_i.clamp(1, Float::INFINITY)
    offset = (page - 1) * PER_PAGE

    emails     = scope.order(received_at: :desc).limit(PER_PAGE).offset(offset)
    recipients = InboundEmail.distinct.pluck(:to).sort

    render inertia: "admin/inbox/Index", props: {
      emails:     emails.map { |e| email_summary(e) },
      total:,
      page:,
      per_page:   PER_PAGE,
      tab:        current_tab,
      recipient:  params[:recipient],
      recipients:
    }
  end

  def show
    @email.update_column(:read, true) unless @email.read?
    render inertia: "admin/inbox/Show", props: { email: email_detail(@email) }
  end

  def update
    apply_action(@email, params[:action_type])
    redirect_back(fallback_location: admin_inbound_emails_path, notice: action_notice(params[:action_type]))
  end

  def bulk_update
    ids    = Array(params[:ids]).map(&:to_i).reject(&:zero?)
    emails = InboundEmail.where(id: ids)
    emails.each { |e| apply_action(e, params[:action_type]) }
    redirect_back(
      fallback_location: admin_inbound_emails_path,
      notice: "#{emails.size} #{"email".pluralize(emails.size)} #{action_past_tense(params[:action_type])}."
    )
  end

  private
    def set_email
      @email = InboundEmail.find(params[:id])
    end

    def current_tab
      %w[unread archived].include?(params[:tab]) ? params[:tab] : "all"
    end

    def tab_scope
      case current_tab
      when "unread"   then InboundEmail.unread
      when "archived" then InboundEmail.archived
      else                 InboundEmail.active
      end
    end

    def apply_action(email, action_type)
      case action_type
      when "mark_read"    then email.update_column(:read, true)
      when "mark_unread"  then email.update_column(:read, false)
      when "archive"      then email.update_column(:archived, true)
      when "restore"      then email.update_columns(archived: false, read: false)
      end
    end

    def action_notice(action_type)
      case action_type
      when "mark_read"   then "Marked as read."
      when "mark_unread" then "Marked as unread."
      when "archive"     then "Archived."
      when "restore"     then "Restored to inbox."
      end
    end

    def action_past_tense(action_type)
      case action_type
      when "mark_read"   then "marked as read"
      when "mark_unread" then "marked as unread"
      when "archive"     then "archived"
      when "restore"     then "restored"
      else "updated"
      end
    end

    def email_summary(e)
      {
        id:          e.id,
        from:        e.from,
        to:          e.to,
        subject:     e.subject,
        received_at: e.received_at.iso8601,
        read:        e.read,
        archived:    e.archived
      }
    end

    def email_detail(e)
      email_summary(e).merge(
        reply_to:  e.reply_to,
        body_html: e.body_html,
        body_text: e.body_text
      )
    end
end
