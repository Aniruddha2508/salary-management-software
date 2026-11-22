class Employee < ApplicationRecord
  # ISO 4217-style 3-letter currency code, e.g. USD, INR, GBP. We don't
  # convert between currencies (see docs/requirements.md), so this is
  # stored as-is and used to group analytics figures.
  CURRENCY_FORMAT = /\A[A-Z]{3}\z/

  belongs_to :manager, class_name: "Employee", optional: true
  has_many :direct_reports, class_name: "Employee", foreign_key: :manager_id, inverse_of: :manager

  enum :employment_type, { full_time: "full_time", part_time: "part_time", contract: "contract" },
       validate: true

  before_validation { self.email = email.to_s.downcase.strip if email.present? }
  before_validation { self.employee_id = employee_id.to_s.strip if employee_id.present? }
  before_validation { self.currency = currency.to_s.upcase.strip if currency.present? }

  validates :employee_id, presence: true, uniqueness: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true,
                     uniqueness: { case_sensitive: false },
                     format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :country, presence: true
  validates :department, presence: true
  validates :job_title, presence: true
  validates :hire_date, presence: true
  validates :effective_date, presence: true
  validates :base_salary, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true, format: { with: CURRENCY_FORMAT, message: "must be a 3-letter ISO currency code (e.g. USD)" }

  validate :manager_is_not_self
  validate :manager_exists

  private

  def manager_is_not_self
    return if manager_id.blank?

    errors.add(:manager_id, "can't be the employee's own id") if manager_id == id
  end

  # belongs_to with optional: true only skips the *presence* check; it
  # doesn't validate that a non-blank manager_id actually refers to a real
  # employee. Without this, an invalid manager_id slips past #valid? and
  # fails later at the database level as an unhandled
  # ActiveRecord::InvalidForeignKey (a raw 500 instead of a clean 422).
  def manager_exists
    return if manager_id.blank?
    return if manager_id == id # covered by manager_is_not_self already

    errors.add(:manager_id, "must refer to an existing employee") unless Employee.exists?(manager_id)
  end
end
