import { useEffect } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useNavigate, useParams } from 'react-router-dom'
import {
  Alert,
  Button,
  Container,
  Group,
  LoadingOverlay,
  NumberInput,
  Paper,
  Select,
  Stack,
  Text,
  TextInput,
  Title,
} from '@mantine/core'
import { useForm } from '@mantine/form'
import { notifications } from '@mantine/notifications'
import {
  COUNTRIES,
  DEPARTMENTS,
  EMPLOYMENT_TYPES,
  createEmployee,
  fetchEmployee,
  updateEmployee,
} from './employeesApi'

const BLANK_VALUES = {
  employee_id: '',
  first_name: '',
  last_name: '',
  email: '',
  country: '',
  department: '',
  job_title: '',
  employment_type: 'full_time',
  hire_date: '',
  effective_date: '',
  base_salary: '',
  currency: '',
  manager_id: '',
}

function validateRequired(value) {
  return String(value ?? '').trim().length === 0 ? 'Required' : null
}

export function EmployeeFormPage() {
  const { id } = useParams()
  const isEditing = Boolean(id)
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  const form = useForm({
    initialValues: BLANK_VALUES,
    validate: {
      employee_id: validateRequired,
      first_name: validateRequired,
      last_name: validateRequired,
      email: validateRequired,
      country: validateRequired,
      department: validateRequired,
      job_title: validateRequired,
      employment_type: validateRequired,
      hire_date: validateRequired,
      effective_date: validateRequired,
      currency: (value) => (/^[A-Za-z]{3}$/.test(value ?? '') ? null : 'Must be a 3-letter code, e.g. USD'),
      base_salary: (value) => (Number(value) > 0 ? null : 'Must be greater than 0'),
    },
  })

  const employeeQuery = useQuery({
    queryKey: ['employee', id],
    queryFn: () => fetchEmployee(id),
    enabled: isEditing,
  })

  useEffect(() => {
    if (employeeQuery.data) {
      form.setValues({
        ...employeeQuery.data,
        manager_id: employeeQuery.data.manager_id ?? '',
      })
    }
    // form is stable from @mantine/form and intentionally excluded to avoid
    // re-running this effect on every keystroke.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [employeeQuery.data])

  const saveMutation = useMutation({
    mutationFn: (values) => {
      const attributes = { ...values, manager_id: values.manager_id === '' ? null : values.manager_id }
      return isEditing ? updateEmployee(id, attributes) : createEmployee(attributes)
    },
    onSuccess: (employee) => {
      queryClient.invalidateQueries({ queryKey: ['employees'] })
      queryClient.invalidateQueries({ queryKey: ['employee', String(employee.id)] })
      notifications.show({
        color: 'green',
        title: isEditing ? 'Employee updated' : 'Employee created',
        message: `${employee.first_name} ${employee.last_name}`,
      })
      navigate(`/employees/${employee.id}`)
    },
    onError: (error) => {
      const details = error?.body?.error?.details
      if (Array.isArray(details)) {
        notifications.show({ color: 'red', title: 'Could not save employee', message: details.join(', ') })
      } else {
        notifications.show({ color: 'red', title: 'Could not save employee', message: error.message })
      }
    },
  })

  if (isEditing && employeeQuery.isLoading) {
    return (
      <Container size="sm" pt="xl">
        <LoadingOverlay visible />
      </Container>
    )
  }

  if (isEditing && employeeQuery.isError) {
    return (
      <Container size="sm" pt="xl">
        <Alert color="red" title="Couldn't load employee">
          {employeeQuery.error.message}
        </Alert>
      </Container>
    )
  }

  return (
    <Container size="sm" pt="xl">
      <Paper withBorder shadow="sm" p="xl" radius="md">
        <Stack gap="md">
          <Title order={2}>{isEditing ? 'Edit Employee' : 'Add Employee'}</Title>

          <form onSubmit={form.onSubmit((values) => saveMutation.mutate(values))}>
            <Stack gap="sm">
              <Group grow>
                <TextInput label="Employee ID" placeholder="EMP00001" {...form.getInputProps('employee_id')} />
                <TextInput label="Email" {...form.getInputProps('email')} />
              </Group>
              <Group grow>
                <TextInput label="First name" {...form.getInputProps('first_name')} />
                <TextInput label="Last name" {...form.getInputProps('last_name')} />
              </Group>
              <Group grow>
                <Select label="Country" data={COUNTRIES} {...form.getInputProps('country')} />
                <Select label="Department" data={DEPARTMENTS} {...form.getInputProps('department')} />
              </Group>
              <Group grow>
                <TextInput label="Job title" {...form.getInputProps('job_title')} />
                <Select
                  label="Employment type"
                  data={EMPLOYMENT_TYPES.map((value) => ({ value, label: value.replace('_', ' ') }))}
                  {...form.getInputProps('employment_type')}
                />
              </Group>
              <Group grow>
                <TextInput type="date" label="Hire date" {...form.getInputProps('hire_date')} />
                <TextInput type="date" label="Effective date" {...form.getInputProps('effective_date')} />
              </Group>
              <Group grow>
                <NumberInput label="Base salary" min={0} {...form.getInputProps('base_salary')} />
                <TextInput label="Currency" placeholder="USD" {...form.getInputProps('currency')} />
              </Group>
              <NumberInput
                label="Manager (internal ID, optional)"
                description="The internal ID shown on the manager's employee detail page."
                min={1}
                {...form.getInputProps('manager_id')}
              />

              <Group justify="flex-end" mt="md">
                <Button variant="subtle" onClick={() => navigate(-1)} type="button">
                  Cancel
                </Button>
                <Button type="submit" loading={saveMutation.isPending}>
                  {isEditing ? 'Save Changes' : 'Create Employee'}
                </Button>
              </Group>
            </Stack>
          </form>
        </Stack>
      </Paper>
      {isEditing && (
        <Text size="xs" c="dimmed" mt="xs">
          Internal ID: {id}
        </Text>
      )}
    </Container>
  )
}
