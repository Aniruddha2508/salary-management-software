module Api
  module V1
    class EmployeesController < BaseController
      include Pagy::Backend

      before_action :require_authentication!
      before_action :set_employee, only: %i[show update destroy]

      SORTABLE_COLUMNS = %w[employee_id first_name last_name country department job_title base_salary hire_date].freeze

      # GET /api/v1/employees
      def index
        scope = Employee.all
        scope = apply_search(scope)
        scope = apply_filters(scope)
        scope = apply_sort(scope)

        begin
          pagy, employees = pagy(scope, limit: per_page)
          render json: {
            employees: employees.map { |employee| employee_json(employee) },
            pagination: pagination_json(pagy),
          }, status: :ok
        rescue Pagy::OverflowError
          # A page number past the last page (e.g. the list shrank from
          # someone else deleting records while paginated forward) isn't
          # a server error - just an empty result for that page.
          render json: {
            employees: [],
            pagination: empty_pagination_json(scope),
          }, status: :ok
        end
      end

      # GET /api/v1/employees/:id
      def show
        render json: { employee: employee_json(@employee) }, status: :ok
      end

      # POST /api/v1/employees
      def create
        employee = Employee.new(employee_params)

        if employee.save
          render json: { employee: employee_json(employee) }, status: :created
        else
          render_validation_errors(employee)
        end
      end

      # PATCH /api/v1/employees/:id
      def update
        if @employee.update(employee_params)
          render json: { employee: employee_json(@employee) }, status: :ok
        else
          render_validation_errors(@employee)
        end
      end

      # DELETE /api/v1/employees/:id
      def destroy
        @employee.destroy
        head :no_content
      end

      private

      def set_employee
        @employee = Employee.find_by(id: params[:id])
        render json: { error: { message: "Employee not found." } }, status: :not_found if @employee.nil?
      end

      def employee_params
        params.require(:employee).permit(
          :employee_id, :first_name, :last_name, :email, :country, :department,
          :job_title, :employment_type, :hire_date, :effective_date,
          :base_salary, :currency, :manager_id
        )
      end

      # Case-insensitive match (SQLite's LIKE is ASCII case-insensitive by
      # default) against name, employee_id, and email.
      def apply_search(scope)
        term = params[:search].to_s.strip
        return scope if term.blank?

        pattern = "%#{term}%"
        scope.where(
          "first_name LIKE :p OR last_name LIKE :p OR employee_id LIKE :p OR email LIKE :p",
          p: pattern
        )
      end

      def apply_filters(scope)
        scope = scope.where(country: params[:country]) if params[:country].present?
        scope = scope.where(department: params[:department]) if params[:department].present?
        scope = scope.where(employment_type: params[:employment_type]) if params[:employment_type].present?
        scope
      end

      def apply_sort(scope)
        column = SORTABLE_COLUMNS.include?(params[:sort_by]) ? params[:sort_by] : "employee_id"
        direction = params[:sort_dir].to_s.downcase == "desc" ? :desc : :asc
        scope.order(column => direction)
      end

      def per_page
        requested = params[:per_page].to_i
        requested.between?(1, 100) ? requested : 25
      end

      def employee_json(employee)
        {
          id: employee.id,
          employee_id: employee.employee_id,
          first_name: employee.first_name,
          last_name: employee.last_name,
          email: employee.email,
          country: employee.country,
          department: employee.department,
          job_title: employee.job_title,
          employment_type: employee.employment_type,
          hire_date: employee.hire_date,
          effective_date: employee.effective_date,
          base_salary: employee.base_salary.to_s,
          currency: employee.currency,
          manager_id: employee.manager_id,
          manager_name: employee.manager && "#{employee.manager.first_name} #{employee.manager.last_name}",
        }
      end

      def pagination_json(pagy)
        { page: pagy.page, pages: pagy.pages, count: pagy.count, limit: pagy.limit }
      end

      def empty_pagination_json(scope)
        count = scope.count
        limit = per_page
        { page: params[:page].to_i, pages: [(count.to_f / limit).ceil, 1].max, count: count, limit: limit }
      end

      def render_validation_errors(employee)
        render json: {
          error: { message: "Validation failed.", details: employee.errors.full_messages },
        }, status: :unprocessable_content
      end
    end
  end
end
