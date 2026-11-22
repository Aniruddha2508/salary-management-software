import { useQuery } from '@tanstack/react-query'
import { Badge, Container, Stack, Text, Title } from '@mantine/core'
import { apiFetch } from './lib/apiClient'

// Task 1 placeholder: proves the React app can reach the Rails API through
// the dev proxy. Routing, auth, and the real app pages land in later tasks.
function App() {
  const { data, isLoading, isError } = useQuery({
    queryKey: ['health'],
    queryFn: () => apiFetch('/health'),
  })

  return (
    <Container size="sm" pt="xl">
      <Stack gap="sm">
        <Title order={2}>ACME Salary Management</Title>
        <Text c="dimmed">Scaffolding check: frontend → Rails API</Text>
        {isLoading && <Badge color="gray">Checking API…</Badge>}
        {isError && <Badge color="red">API unreachable</Badge>}
        {data && <Badge color="green">API status: {data.status}</Badge>}
      </Stack>
    </Container>
  )
}

export default App
