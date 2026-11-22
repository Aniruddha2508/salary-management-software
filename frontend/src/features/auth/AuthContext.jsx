import { useMemo } from 'react'
import PropTypes from 'prop-types'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiFetch } from '../../lib/apiClient'
import { AuthContext } from './auth-context'

const SESSION_QUERY_KEY = ['session']

function fetchCurrentUser() {
  // apiFetch throws ApiError on 401; React Query treats that as the query
  // "erroring", which is exactly the signal we want for "not logged in".
  return apiFetch('/session').then((data) => data.user)
}

export function AuthProvider({ children }) {
  const queryClient = useQueryClient()

  const sessionQuery = useQuery({
    queryKey: SESSION_QUERY_KEY,
    queryFn: fetchCurrentUser,
    retry: false,
  })

  const loginMutation = useMutation({
    mutationFn: ({ email, password }) =>
      apiFetch('/session', {
        method: 'POST',
        body: JSON.stringify({ email, password }),
      }).then((data) => data.user),
    onSuccess: (user) => {
      queryClient.setQueryData(SESSION_QUERY_KEY, user)
    },
  })

  const logoutMutation = useMutation({
    mutationFn: () => apiFetch('/session', { method: 'DELETE' }),
    onSuccess: () => {
      queryClient.setQueryData(SESSION_QUERY_KEY, null)
    },
  })

  const value = useMemo(
    () => ({
      user: sessionQuery.data ?? null,
      isLoadingUser: sessionQuery.isLoading,
      isAuthenticated: Boolean(sessionQuery.data),
      login: loginMutation.mutateAsync,
      isLoggingIn: loginMutation.isPending,
      loginError: loginMutation.error,
      logout: logoutMutation.mutateAsync,
    }),
    [
      sessionQuery.data,
      sessionQuery.isLoading,
      loginMutation.mutateAsync,
      loginMutation.isPending,
      loginMutation.error,
      logoutMutation.mutateAsync,
    ],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

AuthProvider.propTypes = {
  children: PropTypes.node.isRequired,
}
