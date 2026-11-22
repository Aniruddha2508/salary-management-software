import { useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import {
  Alert,
  Button,
  Container,
  Paper,
  PasswordInput,
  Stack,
  TextInput,
  Title,
} from '@mantine/core'
import { useForm } from '@mantine/form'
import { useAuth } from './useAuth'

export function LoginPage() {
  const { login, isLoggingIn } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const [submitError, setSubmitError] = useState(null)

  const redirectTo = location.state?.from ?? '/'

  const form = useForm({
    initialValues: { email: '', password: '' },
    validate: {
      email: (value) => (value.trim().length === 0 ? 'Email is required' : null),
      password: (value) => (value.length === 0 ? 'Password is required' : null),
    },
  })

  async function handleSubmit(values) {
    setSubmitError(null)
    try {
      await login(values)
      navigate(redirectTo, { replace: true })
    } catch (error) {
      setSubmitError(error.message ?? 'Unable to sign in.')
    }
  }

  return (
    <Container size="xs" pt="xl">
      <Paper withBorder shadow="sm" p="xl" radius="md">
        <Stack gap="md">
          <Title order={2}>HR Manager Sign In</Title>

          {submitError && (
            <Alert color="red" title="Sign in failed">
              {submitError}
            </Alert>
          )}

          <form onSubmit={form.onSubmit(handleSubmit)}>
            <Stack gap="md">
              <TextInput
                label="Email"
                placeholder="hr-manager@acme.test"
                autoComplete="username"
                {...form.getInputProps('email')}
              />
              <PasswordInput
                label="Password"
                autoComplete="current-password"
                {...form.getInputProps('password')}
              />
              <Button type="submit" loading={isLoggingIn} fullWidth>
                Sign in
              </Button>
            </Stack>
          </form>
        </Stack>
      </Paper>
    </Container>
  )
}
