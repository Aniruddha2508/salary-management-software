import { Center, Loader } from '@mantine/core'
import { Navigate, Outlet, useLocation } from 'react-router-dom'
import { useAuth } from './useAuth'

// Wraps a set of routes so they require an authenticated HR Manager.
// Renders a brief loading state while the initial "am I logged in?"
// check is in flight, then either the nested routes or a redirect to
// /login (preserving the originally requested path for after sign-in).
export function ProtectedRoute() {
  const { isAuthenticated, isLoadingUser } = useAuth()
  const location = useLocation()

  if (isLoadingUser) {
    return (
      <Center h="100vh">
        <Loader />
      </Center>
    )
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" state={{ from: location.pathname }} replace />
  }

  return <Outlet />
}
