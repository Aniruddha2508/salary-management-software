// Minimal fetch wrapper for talking to the Rails API.
//
// Requests go to the relative path "/api/v1/...". In dev, Vite's proxy
// (see vite.config.js) forwards these to the Rails server on :3000. In
// production, Rails serves the built SPA itself, so "/api/v1/..." is
// already same-origin. `credentials: "include"` ensures the session
// cookie is sent either way.
const API_BASE_URL = '/api/v1'

export class ApiError extends Error {
  constructor(message, { status, body } = {}) {
    super(message)
    this.name = 'ApiError'
    this.status = status
    this.body = body
  }
}

export async function apiFetch(path, options = {}) {
  const response = await fetch(`${API_BASE_URL}${path}`, {
    credentials: 'include',
    headers: {
      Accept: 'application/json',
      ...(options.body ? { 'Content-Type': 'application/json' } : {}),
      ...options.headers,
    },
    ...options,
  })

  const contentType = response.headers.get('content-type') ?? ''
  const data = contentType.includes('application/json')
    ? await response.json()
    : null

  if (!response.ok) {
    throw new ApiError(data?.error?.message ?? 'Request failed', {
      status: response.status,
      body: data,
    })
  }

  return data
}
