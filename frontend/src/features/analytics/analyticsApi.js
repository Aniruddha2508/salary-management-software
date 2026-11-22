import { apiFetch } from '../../lib/apiClient'

export function fetchSummary() {
  return apiFetch('/analytics/summary')
}

export function fetchByCountry() {
  return apiFetch('/analytics/by_country').then((data) => data.by_country)
}

export function fetchByDepartment() {
  return apiFetch('/analytics/by_department').then((data) => data.by_department)
}
