class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV["MAILER_FROM"].presence || "FDA CRL Explorer <noreply@fdaclrs.example.com>" }
  layout "mailer"
end
