class User < ApplicationRecord
  has_secure_password

  before_validation { self.email = email.to_s.downcase.strip if email.present? }

  validates :name, presence: true
  validates :email, presence: true,
                     uniqueness: { case_sensitive: false },
                     format: { with: URI::MailTo::EMAIL_REGEXP }
end
