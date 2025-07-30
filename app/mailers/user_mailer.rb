class UserMailer < ApplicationMailer
  def account_activation user
    @user = user
    mail to: user.email, subject: t("user_mailer.account_activation.subject")
  end

  def password_reset user
    @user = user
    mail to: user.email, subject: t("user_mailer.password_reset.subject")
  end
end
