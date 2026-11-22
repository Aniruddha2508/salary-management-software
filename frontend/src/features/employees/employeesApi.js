import { apiFetch } from '../../lib/apiClient'

// Matches the countries/departments the backend's EmployeeSeeder uses, so
// the filter dropdowns show real, selectable values without needing a
// separate "distinct values" endpoint for this first version.
export const COUNTRIES = [
  'United States',
  'United Kingdom',
  'India',
  'Germany',
  'Canada',
  'Australia',
  'Singapore',
  'Japan',
]

export const DEPARTMENTS = [
  'Engineering',
  'Sales',
  'Marketing',
  'Finance',
  'Human Resources',
  'Customer Support',
  'Product',
  'Operations',
  'Legal',
]

export const EMPLOYMENT_TYPES = ['full_time', 'part_time', 'contract']

export function fetchEmployees(params) {
  const query = new URLSearchParams(
    Object.fromEntries(Object.entries(params).filter(([, value]) => value !== '' && value != null)),
  )
  return apiFetch(`/employees?${query.toString()}`)
}

export function fetchEmployee(id) {
  return apiFetch(`/employees/${id}`).then((data) => data.employee)
}

export function createEmployee(attributes) {
  return apiFetch('/employees', {
    method: 'POST',
    body: JSON.stringify({ employee: attributes }),
  }).then((data) => data.employee)
}

export function updateEmployee(id, attributes) {
  return apiFetch(`/employees/${id}`, {
    method: 'PATCH',
    body: JSON.stringify({ employee: attributes }),
  }).then((data) => data.employee)
}

export function deleteEmployee(id) {
  return apiFetch(`/employees/${id}`, { method: 'DELETE' })
}
