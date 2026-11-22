import { useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Link, useNavigate, useParams } from 'react-router-dom'
import {
  Alert,
  Badge,
  Button,
  Container,
  Group,
  LoadingOverlay,
  Modal,
  Paper,
  SimpleGrid,
  Stack,
  Text,
  Title,
} from '@mantine/core'
import PropTypes from 'prop-types'
import { notifications } from '@mantine/notifications'
import { deleteEmployee, fetchEmployee } from './employeesApi'

function Field({ label, value }) {
  return (
    <div>
      <Text size="xs" c="dimmed">
        {label}
      </Text>
      <Text component="div">{value ?? '—'}</Text>
    </div>
  )
}

Field.propTypes = {
  label: PropTypes.string.isRequired,
  value: PropTypes.node,
}

export function EmployeeDetailPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const [confirmOpen, setConfirmOpen] = useState(false)

  const { data: employee, isLoading, isError, error } = useQuery({
    queryKey: ['employee', id],
    queryFn: () => fetchEmployee(id),
  })

  const deleteMutation = useMutation({
    mutationFn: () => deleteEmployee(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['employees'] })
      notifications.show({ color: 'green', title: 'Employee deleted', message: `${employee.first_name} ${employee.last_name}` })
      navigate('/employees')
    },
    onError: (err) => {
      notifications.show({ color: 'red', title: 'Could not delete employee', message: err.message })
    },
  })

  if (isLoading) {
    return (
      <Container size="sm" pt="xl">
        <LoadingOverlay visible />
      </Container>
    )
  }

  if (isError) {
    return (
      <Container size="sm" pt="xl">
        <Alert color="red" title="Couldn't load employee">
          {error.message}
        </Alert>
      </Container>
    )
  }

  return (
    <Container size="sm" pt="xl">
      <Stack gap="md">
        <Group justify="space-between">
          <Title order={2}>
            {employee.first_name} {employee.last_name}
          </Title>
          <Group>
            <Button component={Link} to={`/employees/${id}/edit`} variant="light">
              Edit
            </Button>
            <Button color="red" variant="light" onClick={() => setConfirmOpen(true)}>
              Delete
            </Button>
            <Button component={Link} to="/employees" variant="subtle">
              Back
            </Button>
          </Group>
        </Group>

        <Paper withBorder p="xl" radius="md">
          <SimpleGrid cols={2} spacing="md">
            <Field label="Employee ID" value={employee.employee_id} />
            <Field label="Email" value={employee.email} />
            <Field label="Country" value={employee.country} />
            <Field label="Department" value={employee.department} />
            <Field label="Job title" value={employee.job_title} />
            <Field
              label="Employment type"
              value={<Badge variant="light">{employee.employment_type.replace('_', ' ')}</Badge>}
            />
            <Field label="Hire date" value={employee.hire_date} />
            <Field label="Effective date" value={employee.effective_date} />
            <Field
              label="Base salary"
              value={`${Number(employee.base_salary).toLocaleString()} ${employee.currency}`}
            />
            <Field label="Manager" value={employee.manager_name} />
          </SimpleGrid>
        </Paper>
      </Stack>

      <Modal opened={confirmOpen} onClose={() => setConfirmOpen(false)} title="Delete employee?">
        <Stack gap="md">
          <Text>
            This permanently deletes {employee.first_name} {employee.last_name} ({employee.employee_id}). This
            can&apos;t be undone.
          </Text>
          <Group justify="flex-end">
            <Button variant="subtle" onClick={() => setConfirmOpen(false)}>
              Cancel
            </Button>
            <Button color="red" loading={deleteMutation.isPending} onClick={() => deleteMutation.mutate()}>
              Delete
            </Button>
          </Group>
        </Stack>
      </Modal>
    </Container>
  )
}
