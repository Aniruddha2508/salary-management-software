import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import {
  Alert,
  Badge,
  Button,
  Center,
  Container,
  Group,
  Loader,
  Pagination,
  Select,
  SimpleGrid,
  Stack,
  Table,
  Text,
  TextInput,
  Title,
} from '@mantine/core'
import { useDebouncedValue } from '@mantine/hooks'
import { COUNTRIES, DEPARTMENTS, fetchEmployees } from './employeesApi'

const PER_PAGE = 25

const SORT_COLUMNS = [
  { value: 'employee_id', label: 'Employee ID' },
  { value: 'first_name', label: 'First name' },
  { value: 'last_name', label: 'Last name' },
  { value: 'country', label: 'Country' },
  { value: 'department', label: 'Department' },
  { value: 'base_salary', label: 'Base salary' },
  { value: 'hire_date', label: 'Hire date' },
]

export function EmployeesListPage() {
  const navigate = useNavigate()
  const [search, setSearch] = useState('')
  const [debouncedSearch] = useDebouncedValue(search, 300)
  const [country, setCountry] = useState(null)
  const [department, setDepartment] = useState(null)
  const [sortBy, setSortBy] = useState('employee_id')
  const [sortDir, setSortDir] = useState('asc')
  const [page, setPage] = useState(1)

  const queryParams = {
    search: debouncedSearch,
    country,
    department,
    sort_by: sortBy,
    sort_dir: sortDir,
    per_page: PER_PAGE,
    page,
  }

  const { data, isLoading, isError, error } = useQuery({
    queryKey: ['employees', queryParams],
    queryFn: () => fetchEmployees(queryParams),
    placeholderData: (previous) => previous,
  })

  function updateFilter(setter) {
    return (value) => {
      setter(value)
      setPage(1)
    }
  }

  function toggleSort(column) {
    if (sortBy === column) {
      setSortDir((dir) => (dir === 'asc' ? 'desc' : 'asc'))
    } else {
      setSortBy(column)
      setSortDir('asc')
    }
    setPage(1)
  }

  return (
    <Container size="xl" pt="xl">
      <Stack gap="md">
        <Group justify="space-between" wrap="wrap">
          <Title order={2}>Employees</Title>
          <Group>
            <Button component={Link} to="/employees/new">
              Add Employee
            </Button>
            <Button component={Link} to="/" variant="subtle">
              Back to Dashboard
            </Button>
          </Group>
        </Group>

        <SimpleGrid cols={{ base: 1, xs: 2, sm: 4 }}>
          <TextInput
            label="Search"
            placeholder="Name, employee ID, or email"
            value={search}
            onChange={(event) => {
              setSearch(event.currentTarget.value)
              setPage(1)
            }}
          />
          <Select
            label="Country"
            placeholder="All countries"
            data={COUNTRIES}
            value={country}
            onChange={updateFilter(setCountry)}
            clearable
          />
          <Select
            label="Department"
            placeholder="All departments"
            data={DEPARTMENTS}
            value={department}
            onChange={updateFilter(setDepartment)}
            clearable
          />
          <Select
            label="Sort by"
            data={SORT_COLUMNS}
            value={sortBy}
            onChange={(value) => toggleSort(value ?? 'employee_id')}
          />
        </SimpleGrid>

        {isError && (
          <Alert color="red" title="Couldn't load employees">
            {error?.message ?? 'Something went wrong.'}
          </Alert>
        )}

        {isLoading && !data && (
          <Center py="xl">
            <Loader />
          </Center>
        )}

        {data && (
          <>
            <Text c="dimmed" size="sm">
              {data.pagination.count.toLocaleString()} employees found
            </Text>

            <Table.ScrollContainer minWidth={900}>
              <Table striped highlightOnHover>
              <Table.Thead>
                <Table.Tr>
                  <Table.Th>Employee ID</Table.Th>
                  <Table.Th>Name</Table.Th>
                  <Table.Th>Country</Table.Th>
                  <Table.Th>Department</Table.Th>
                  <Table.Th>Job Title</Table.Th>
                  <Table.Th>Type</Table.Th>
                  <Table.Th>Salary</Table.Th>
                  <Table.Th>Manager</Table.Th>
                </Table.Tr>
              </Table.Thead>
              <Table.Tbody>
                {data.employees.map((employee) => (
                  <Table.Tr
                    key={employee.id}
                    onClick={() => navigate(`/employees/${employee.id}`)}
                    style={{ cursor: 'pointer' }}
                  >
                    <Table.Td>{employee.employee_id}</Table.Td>
                    <Table.Td>
                      {employee.first_name} {employee.last_name}
                    </Table.Td>
                    <Table.Td>{employee.country}</Table.Td>
                    <Table.Td>{employee.department}</Table.Td>
                    <Table.Td>{employee.job_title}</Table.Td>
                    <Table.Td>
                      <Badge variant="light">{employee.employment_type.replace('_', ' ')}</Badge>
                    </Table.Td>
                    <Table.Td>
                      {Number(employee.base_salary).toLocaleString()} {employee.currency}
                    </Table.Td>
                    <Table.Td>{employee.manager_name ?? '—'}</Table.Td>
                  </Table.Tr>
                ))}
              </Table.Tbody>
              </Table>
            </Table.ScrollContainer>

            {data.employees.length === 0 && (
              <Text c="dimmed" ta="center" py="xl">
                No employees match these filters.
              </Text>
            )}

            <Center>
              <Pagination value={page} onChange={setPage} total={data.pagination.pages} />
            </Center>
          </>
        )}
      </Stack>
    </Container>
  )
}
