// Minimal fetch wrapper for talking to the Rails API.
//
// Requests go to the relative path "/api/v1/...". In dev, Vite's proxy
// (see vite.config.js) forwards these to the Rails server on :3000. In
// production, Rails serves the built SPA itself, so "/api/v1/..." is
// already same-origin. `credentials: "include"` ensures the session
// cookie is sent either way.
const API_BASE_URL = '/api/v1'
const MUTATING_METHODS = new Set(['POST', 'PATCH', 'PUT', 'DELETE'])

export class ApiError extends Error {
  constructor(message, { status, body } = {}) {
    super(message)
    this.name = 'ApiError'
    this.status = status
    this.body = body
  }
}

// The Rails CSRF token is only needed on mutating requests, and the same
// token is valid for the whole session, so we fetch it once and cache it
// here rather than re-fetching before every write.
let csrfTokenPromise = null

function fetchCsrfToken() {
  csrfTokenPromise ??= rawFetch('/csrf_token').then((data) => data.csrf_token)
  return csrfTokenPromise
}

function invalidateCsrfToken() {
  csrfTokenPromise = null
}

async function rawFetch(path, options = {}) {
  const { headers: extraHeaders, ...rest } = options

  const response = await fetch(`${API_BASE_URL}${path}`, {
    credentials: 'include',
    ...rest,
    headers: {
      Accept: 'application/json',
      ...(options.body ? { 'Content-Type': 'application/json' } : {}),
      ...extraHeaders,
    },
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

export async function apiFetch(path, options = {}) {
  const method = (options.method ?? 'GET').toUpperCase()

  if (!MUTATING_METHODS.has(method)) {
    return rawFetch(path, options)
  }

  const csrfToken = await fetchCsrfToken()

  try {
    return await rawFetch(path, {
      ...options,
      headers: { 'X-CSRF-Token': csrfToken, ...options.headers },
    })
  } catch (error) {
    // A 422 here most likely means the cached CSRF token went stale (e.g.
    // the server restarted). Refresh it once and retry a single time
    // before surfacing the error to the caller.
    if (error instanceof ApiError && error.status === 422) {
      invalidateCsrfToken()
      const freshToken = await fetchCsrfToken()
      return rawFetch(path, {
        ...options,
        headers: { 'X-CSRF-Token': freshToken, ...options.headers },
      })
    }
    throw error
  }
}
