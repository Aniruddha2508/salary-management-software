import PropTypes from 'prop-types'
import { Table } from '@mantine/core'

function formatMoney(value) {
  return Number(value).toLocaleString(undefined, { maximumFractionDigits: 0 })
}

// Renders one row per (groupColumn, currency) pair, since figures are
// never blended across currencies - see docs/requirements.md. When the
// group itself *is* currency (the "Pay by Currency" table), there's no
// separate currency column to show - it would just duplicate the group
// column.
export function BreakdownTable({ rows, groupLabel, groupKey }) {
  const showCurrencyColumn = groupKey !== 'currency'

  return (
    <Table.ScrollContainer minWidth={500}>
      <Table striped highlightOnHover>
        <Table.Thead>
          <Table.Tr>
            <Table.Th>{groupLabel}</Table.Th>
            {showCurrencyColumn && <Table.Th>Currency</Table.Th>}
            <Table.Th>Headcount</Table.Th>
            <Table.Th>Total Salary</Table.Th>
            <Table.Th>Average Salary</Table.Th>
            <Table.Th>Median Salary</Table.Th>
          </Table.Tr>
        </Table.Thead>
        <Table.Tbody>
          {rows.map((row) => (
            <Table.Tr key={`${row[groupKey]}-${row.currency}`}>
              <Table.Td>{row[groupKey]}</Table.Td>
              {showCurrencyColumn && <Table.Td>{row.currency}</Table.Td>}
              <Table.Td>{row.headcount.toLocaleString()}</Table.Td>
              <Table.Td>{formatMoney(row.total_salary)}</Table.Td>
              <Table.Td>{formatMoney(row.average_salary)}</Table.Td>
              <Table.Td>{formatMoney(row.median_salary)}</Table.Td>
            </Table.Tr>
          ))}
        </Table.Tbody>
      </Table>
    </Table.ScrollContainer>
  )
}

BreakdownTable.propTypes = {
  rows: PropTypes.arrayOf(
    PropTypes.shape({
      currency: PropTypes.string.isRequired,
      headcount: PropTypes.number.isRequired,
      total_salary: PropTypes.string.isRequired,
      average_salary: PropTypes.string.isRequired,
      median_salary: PropTypes.string.isRequired,
    }),
  ).isRequired,
  groupLabel: PropTypes.string.isRequired,
  groupKey: PropTypes.string.isRequired,
}
