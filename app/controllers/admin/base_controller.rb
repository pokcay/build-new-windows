class Admin::BaseController < ApplicationController
  before_action :require_admin

  inertia_share do
    { admin_inbox_unread_count: InboundEmail.unread.count }
  end

  private
    def require_admin
      unless Current.user&.admin?
        redirect_to root_path, alert: "You don't have access to that page."
      end
    end
end
