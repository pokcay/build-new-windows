require "test_helper"

class Admin::InboundEmailsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin    = users(:admin)
    @user     = users(:one)
    @password = "password"
    @unread   = inbound_emails(:unread_one)
    @read     = inbound_emails(:read_one)
    @archived = inbound_emails(:archived_one)
  end

  test "unauthenticated users are redirected to login on index" do
    get admin_inbound_emails_path
    assert_redirected_to login_path
  end

  test "non-admin users cannot access inbox index" do
    log_in_as(@user)
    get admin_inbound_emails_path
    assert_redirected_to root_path
  end

  test "non-admin users cannot access inbox show" do
    log_in_as(@user)
    get admin_inbound_email_path(@unread)
    assert_redirected_to root_path
  end

  test "admin can list inbox emails" do
    log_in_as(@admin)
    get admin_inbound_emails_path
    assert_response :success
  end

  test "admin can filter by unread tab" do
    log_in_as(@admin)
    get admin_inbound_emails_path, params: { tab: "unread" }
    assert_response :success
  end

  test "admin can filter by archived tab" do
    log_in_as(@admin)
    get admin_inbound_emails_path, params: { tab: "archived" }
    assert_response :success
  end

  test "admin can view an email" do
    log_in_as(@admin)
    get admin_inbound_email_path(@unread)
    assert_response :success
  end

  test "show marks an unread email as read" do
    log_in_as(@admin)
    assert_not @unread.read
    get admin_inbound_email_path(@unread)
    assert @unread.reload.read
  end

  test "show does not update already-read email" do
    log_in_as(@admin)
    original_updated = @read.updated_at
    get admin_inbound_email_path(@read)
    assert_equal original_updated, @read.reload.updated_at
  end

  test "admin can mark an email as unread" do
    log_in_as(@admin)
    patch admin_inbound_email_path(@read), params: { action_type: "mark_unread" }
    assert_response :redirect
    assert_not @read.reload.read
  end

  test "admin can archive an email" do
    log_in_as(@admin)
    patch admin_inbound_email_path(@unread), params: { action_type: "archive" }
    assert_response :redirect
    assert @unread.reload.archived
  end

  test "admin can restore an archived email" do
    log_in_as(@admin)
    patch admin_inbound_email_path(@archived), params: { action_type: "restore" }
    assert_response :redirect
    assert_not @archived.reload.archived
  end

  test "admin can bulk archive emails" do
    log_in_as(@admin)
    patch bulk_update_admin_inbound_emails_path,
          params: { ids: [ @unread.id, @read.id ], action_type: "archive" }
    assert_response :redirect
    assert @unread.reload.archived
    assert @read.reload.archived
  end

  test "admin can bulk mark emails as read" do
    log_in_as(@admin)
    patch bulk_update_admin_inbound_emails_path,
          params: { ids: [ @unread.id ], action_type: "mark_read" }
    assert_response :redirect
    assert @unread.reload.read
  end

  private
    def log_in_as(user)
      post login_path, params: { email: user.email, password: @password }
    end
end
