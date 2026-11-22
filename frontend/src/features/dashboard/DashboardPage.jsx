import { Button, Container, Group, Stack, Text, Title } from '@mantine/core'
import { useAuth } from '../auth/useAuth'

// Placeholder landing page for a signed-in HR Manager. Replaced with real
// analytics content in a later task; for now it exists to prove the
// login -> protected route -> logout loop works end to end.
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
      </Stack>
    </Container>
  )
}
