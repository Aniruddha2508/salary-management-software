import PropTypes from 'prop-types'
import { BarChart, DonutChart } from '@mantine/charts'
import { Box, Card, Group, SimpleGrid, Stack, Text, Title } from '@mantine/core'

const DONUT_COLORS = ['blue.6', 'teal.6', 'grape.6', 'orange.6', 'green.6', 'red.6', 'cyan.6', 'yellow.6']

// by_country/by_department rows are per (group, currency) pair - see
// docs/requirements.md. Headcount is currency-agnostic, so for a chart
// it's safe (and correct) to sum headcount across currencies within the
// same country/department, unlike salary figures which must stay
// separated by currency.
function aggregateHeadcount(rows, groupKey) {
  const totals = new Map()
  rows.forEach((row) => {
    const key = row[groupKey]
    totals.set(key, (totals.get(key) ?? 0) + row.headcount)
  })
  return [...totals.entries()].map(([name, value]) => ({ name, value }))
}

// DonutChart (Mantine/Recharts) has no built-in legend - only hover
// tooltips - so a static view of the chart has no way to tell which
// color is which country. This renders a simple color-key list to go
// with it.
function ChartLegend({ items }) {
  return (
    <Group gap="sm" justify="center" wrap="wrap">
      {items.map((item) => (
        <Group key={item.name} gap={6} wrap="nowrap">
          <Box w={10} h={10} bg={item.color} style={{ borderRadius: 2, flexShrink: 0 }} />
          <Text size="xs" c="dimmed">
            {item.name}
          </Text>
        </Group>
      ))}
    </Group>
  )
}

ChartLegend.propTypes = {
  items: PropTypes.arrayOf(PropTypes.shape({ name: PropTypes.string.isRequired, color: PropTypes.string.isRequired }))
    .isRequired,
}

export function HeadcountCharts({ byCountry, byDepartment }) {
  const countryData = aggregateHeadcount(byCountry, 'country').map((row, index) => ({
    ...row,
    color: DONUT_COLORS[index % DONUT_COLORS.length],
  }))
  const departmentData = aggregateHeadcount(byDepartment, 'department').sort((a, b) => b.value - a.value)

  return (
    <SimpleGrid cols={{ base: 1, md: 2 }} spacing="md">
      <Card withBorder radius="md" p="lg">
        <Stack gap="xs">
          <Title order={4}>Headcount by Country</Title>
          <Text size="sm" c="dimmed">
            Share of the 10,000 employees per country
          </Text>
          <DonutChart
            data={countryData}
            size={200}
            thickness={30}
            withLabels
            labelsType="percent"
            mx="auto"
            mt="sm"
            tooltipDataSource="segment"
            valueFormatter={(value) => value.toLocaleString()}
          />
          <ChartLegend items={countryData} />
        </Stack>
      </Card>

      <Card withBorder radius="md" p="lg">
        <Stack gap="xs">
          <Title order={4}>Headcount by Department</Title>
          <Text size="sm" c="dimmed">
            Employee count per department, across all countries
          </Text>
          <BarChart
            h={260}
            mt="sm"
            data={departmentData}
            dataKey="name"
            series={[{ name: 'value', color: 'blue.6', label: 'Employees' }]}
            withLegend={false}
            gridAxis="y"
          />
        </Stack>
      </Card>
    </SimpleGrid>
  )
}

HeadcountCharts.propTypes = {
  byCountry: PropTypes.arrayOf(
    PropTypes.shape({
      country: PropTypes.string.isRequired,
      headcount: PropTypes.number.isRequired,
    }),
  ).isRequired,
  byDepartment: PropTypes.arrayOf(
    PropTypes.shape({
      department: PropTypes.string.isRequired,
      headcount: PropTypes.number.isRequired,
    }),
  ).isRequired,
}
