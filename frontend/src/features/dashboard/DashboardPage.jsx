import { Link } from 'react-router-dom'
import PropTypes from 'prop-types'
import { useQuery } from '@tanstack/react-query'
import {
  Alert,
  Button,
  Card,
  Center,
  Container,
  Group,
  Loader,
  SimpleGrid,
  Stack,
  Tabs,
  Text,
  Title,
} from '@mantine/core'
import { useAuth } from '../auth/useAuth'
import { fetchByCountry, fetchByDepartment, fetchSummary } from '../analytics/analyticsApi'
import { BreakdownTable } from '../analytics/BreakdownTable'

function SummaryCard({ title, value, subtitle }) {
  return (
    <Card withBorder radius="md" padding="lg">
      <Text size="sm" c="dimmed">
        {title}
      </Text>
      <Text size="xl" fw={700}>
        {value}
      </Text>
      {subtitle && (
        <Text size="xs" c="dimmed">
          {subtitle}
        </Text>
      )}
    </Card>
  )
}

SummaryCard.propTypes = {
  title: PropTypes.string.isRequired,
  value: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  subtitle: PropTypes.string,
}

export function DashboardPage() {
  const { user, logout } = useAuth()

  const summaryQuery = useQuery({ queryKey: ['analytics', 'summary'], queryFn: fetchSummary })
  const byCountryQuery = useQuery({ queryKey: ['analytics', 'by_country'], queryFn: fetchByCountry })
  const byDepartmentQuery = useQuery({ queryKey: ['analytics', 'by_department'], queryFn: fetchByDepartment })

  const isLoading = summaryQuery.isLoading || byCountryQuery.isLoading || byDepartmentQuery.isLoading
  const isError = summaryQuery.isError || byCountryQuery.isError || byDepartmentQuery.isError

  return (
    <Container size="lg" pt="xl" pb="xl">
      <Stack gap="lg">
        <Group justify="space-between">
          <Title order={2}>Dashboard</Title>
          <Group>
            <Button component={Link} to="/employees">
              View Employees
            </Button>
            <Button variant="light" onClick={() => logout()}>
              Sign out
            </Button>
          </Group>
        </Group>
        <Text c="dimmed">
          Signed in as {user?.name} ({user?.email})
        </Text>

        {isError && (
          <Alert color="red" title="Couldn't load dashboard data">
            Something went wrong loading analytics. Try refreshing the page.
          </Alert>
        )}

        {isLoading && !isError && (
          <Center py="xl">
            <Loader />
          </Center>
        )}

        {summaryQuery.data && (
          <Stack gap="md">
            <SimpleGrid cols={{ base: 1, sm: 3 }}>
              <SummaryCard
                title="Total Employees"
                value={summaryQuery.data.overall_headcount.toLocaleString()}
                subtitle="Across all countries"
              />
              <SummaryCard
                title="Currencies in Use"
                value={summaryQuery.data.by_currency.length}
                subtitle="Payroll is never blended across currencies"
              />
              <SummaryCard
                title="Largest Payroll Currency"
                value={
                  [...summaryQuery.data.by_currency].sort((a, b) => b.headcount - a.headcount)[0]?.currency ?? '—'
                }
                subtitle="By headcount"
              />
            </SimpleGrid>

            <Title order={4} mt="md">
              Pay by Currency
            </Title>
            <BreakdownTable rows={summaryQuery.data.by_currency} groupLabel="Currency" groupKey="currency" />
          </Stack>
        )}

        {(byCountryQuery.data || byDepartmentQuery.data) && (
          <Tabs defaultValue="country" mt="lg">
            <Tabs.List>
              <Tabs.Tab value="country">By Country</Tabs.Tab>
              <Tabs.Tab value="department">By Department</Tabs.Tab>
            </Tabs.List>

            <Tabs.Panel value="country" pt="md">
              {byCountryQuery.data && (
                <BreakdownTable rows={byCountryQuery.data} groupLabel="Country" groupKey="country" />
              )}
            </Tabs.Panel>

            <Tabs.Panel value="department" pt="md">
              {byDepartmentQuery.data && (
                <BreakdownTable rows={byDepartmentQuery.data} groupLabel="Department" groupKey="department" />
              )}
            </Tabs.Panel>
          </Tabs>
        )}
      </Stack>
    </Container>
  )
}
