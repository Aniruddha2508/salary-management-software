import { Link } from 'react-router-dom'
import { Button, Container, Group, Stack, Text, Title } from '@mantine/core'
import { useAuth } from '../auth/useAuth'

// Placeholder landing page for a signed-in HR Manager. Analytics content
// (Task 10) replaces the body of this page; the employees link is real.
export function DashboardPage() {
  const { user, logout } = useAuth()

  return (
    <Container size="sm" pt="xl">
      <Stack gap="md">
        <Group justify="space-between">
          <Title order={2}>Dashboard</Title>
          <Button variant="light" onClick={() => logout()}>
            Sign out
          </Button>
        </Group>
        <Text>Signed in as {user?.name} ({user?.email})</Text>
        <Button component={Link} to="/employees">
          View Employees
        </Button>
      </Stack>
    </Container>
  )
}
