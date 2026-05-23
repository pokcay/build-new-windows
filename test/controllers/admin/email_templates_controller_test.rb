require "test_helper"

class Admin::EmailTemplatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin    = users(:admin)
    @user     = users(:one)
    @template = email_templates(:password_reset)
    @password = "password"
  end

  test "unauthenticated users are redirected to login on index" do
    get admin_email_templates_path
    assert_redirected_to login_path
  end

  test "unauthenticated users are redirected to login on show" do
    get admin_email_template_path(@template)
    assert_redirected_to login_path
  end

  test "non-admin users cannot list templates" do
    log_in_as(@user)
    get admin_email_templates_path
    assert_redirected_to root_path
  end

  test "non-admin users cannot view a template" do
    log_in_as(@user)
    get admin_email_template_path(@template)
    assert_redirected_to root_path
  end

  test "admin can list templates" do
    log_in_as(@admin)
    get admin_email_templates_path
    assert_response :success
  end

  test "admin can view a template" do
    log_in_as(@admin)
    get admin_email_template_path(@template)
    assert_response :success
  end

  test "admin can update a template" do
    log_in_as(@admin)
    patch admin_email_template_path(@template), params: {
      email_template: {
        subject:   "New subject line",
        body_html: "Updated **markdown** body",
        body_text: "Updated plain body"
      }
    }
    assert_response :redirect
    @template.reload
    assert_equal "New subject line", @template.subject
    assert_equal "Updated **markdown** body", @template.body_html
    assert @template.customized
    assert_equal @admin, @template.updated_by
  end

  test "update sets customized to true" do
    log_in_as(@admin)
    assert_not @template.customized
    patch admin_email_template_path(@template), params: {
      email_template: { subject: "Changed", body_html: "", body_text: "" }
    }
    assert @template.reload.customized
  end

  test "admin can reset a template to default" do
    log_in_as(@admin)
    @template.update!(subject: "Custom subject", customized: true)

    post reset_to_default_admin_email_template_path(@template)

    assert_response :redirect
    @template.reload
    assert_not @template.customized
    defaults = EmailTemplateConfig.defaults_for(@template.key)
    assert_equal defaults[:subject], @template.subject
  end

  test "send_test with valid email redirects with notice" do
    log_in_as(@admin)
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true

    assert_emails 1 do
      post send_test_admin_email_template_path(@template), params: { email: "test@example.com" }
    end

    assert_response :redirect
    follow_redirect!
    assert_match(/sent/i, flash[:notice])
  end

  test "send_test with blank email redirects with alert and sends no email" do
    log_in_as(@admin)
    assert_emails 0 do
      post send_test_admin_email_template_path(@template), params: { email: "   " }
    end
    assert_response :redirect
    follow_redirect!
    assert flash[:alert].present?
  end

  private
    def log_in_as(user)
      post login_path, params: { email: user.email, password: @password }
    end
end
