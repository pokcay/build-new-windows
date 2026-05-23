require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:one)
  end

  test "reset falls back to ERB when no DB template exists" do
    EmailTemplate.where(key: "password_reset").delete_all

    email = PasswordsMailer.reset(@user)

    assert_equal [ @user.email ], email.to
    assert_equal "Reset your password", email.subject
  end

  test "reset renders from DB template when one exists" do
    template = email_templates(:password_reset)
    template.update!(subject: "DB subject for {{user.email}}", body_html: "Link: {{reset_url}}", body_text: "Text link: {{reset_url}}")

    email = PasswordsMailer.reset(@user)

    assert_equal [ @user.email ], email.to
    assert_equal "DB subject for #{@user.email}", email.subject
    assert_includes email.html_part.body.to_s, "Link:"
    assert_includes email.text_part.body.to_s, "Text link:"
  end

  test "reset substitutes reset_url variable in DB template" do
    email_templates(:password_reset).update!(
      subject: "Reset",
      body_html: "Go to {{reset_url}}",
      body_text: "Go to {{reset_url}}"
    )

    email = PasswordsMailer.reset(@user)

    assert_includes email.html_part.body.to_s, "passwords"
    assert_includes email.text_part.body.to_s, "passwords"
  end
end
