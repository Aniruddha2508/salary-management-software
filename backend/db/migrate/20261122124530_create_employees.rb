class CreateEmployees < ActiveRecord::Migration[8.1]
  def change
    create_table :employees do |t|
      t.string :employee_id, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.string :country, null: false
      t.string :department, null: false
      t.string :job_title, null: false
      t.string :employment_type, null: false
      t.date :hire_date, null: false
      t.date :effective_date, null: false
      # Money is stored as decimal, never float, to avoid floating-point
      # rounding error on salary figures. Precision 14/scale 2 comfortably
      # covers large salaries in any currency's minor unit.
      t.decimal :base_salary, precision: 14, scale: 2, null: false
      t.string :currency, null: false

      # Self-referential reporting line. Nullable: the most senior
      # employees (and the HR Manager's org-chart analog) have no manager.
      # References "employees" explicitly since `t.references :manager`
      # would otherwise default to a non-existent "managers" table.
      t.references :manager, null: true, foreign_key: { to_table: :employees }

      t.timestamps
    end

    add_index :employees, :employee_id, unique: true
    add_index :employees, :email, unique: true
    add_index :employees, :country
    add_index :employees, :department
  end
end
