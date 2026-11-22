import { useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import {
  Alert,
  Badge,
  Box,
  Button,
  Card,
  Grid,
  Group,
  Paper,
  PasswordInput,
  Stack,
  Text,
  TextInput,
  Title,
} from '@mantine/core'
import { useForm } from '@mantine/form'
import { IconBuildingSkyscraper, IconUsersGroup } from '@tabler/icons-react'
import { useAuth } from './useAuth'

const PILL = 100

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
    <Box bg="gray.1" mih="100vh" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }} p={{ base: 'md', sm: 'xl' }}>
      <Paper
        radius={28}
        shadow="xl"
        w="100%"
        maw={1000}
        style={{ overflow: 'hidden' }}
      >
        <Grid gutter={0} align="stretch">
          {/* Left: the sign-in form, pill inputs/buttons */}
          <Grid.Col span={{ base: 12, md: 6 }}>
            <Stack justify="center" h="100%" px={{ base: 'lg', sm: 'xl' }} py="xl" gap="xl" mih={{ base: 'auto', md: 560 }}>
              <Badge
                variant="outline"
                color="gray.6"
                radius={PILL}
                size="lg"
                px="md"
                py="md"
                style={{ alignSelf: 'flex-start' }}
                leftSection={<IconBuildingSkyscraper size={14} />}
              >
                ACME
              </Badge>

              <Stack gap={4} maw={360}>
                <Title order={2}>HR Manager Sign In</Title>
                <Text c="dimmed" size="sm">
                  Sign in to manage salary data for your team.
                </Text>
              </Stack>

              {submitError && (
                <Alert color="red" radius="md" title="Sign in failed" maw={360}>
                  {submitError}
                </Alert>
              )}

              <form onSubmit={form.onSubmit(handleSubmit)} style={{ maxWidth: 360, width: '100%' }}>
                <Stack gap="md">
                  <TextInput
                    label="Email"
                    placeholder="hr-manager@acme.test"
                    autoComplete="username"
                    size="md"
                    radius={PILL}
                    {...form.getInputProps('email')}
                  />
                  <PasswordInput
                    label="Password"
                    autoComplete="current-password"
                    size="md"
                    radius={PILL}
                    {...form.getInputProps('password')}
                  />
                  <Button
                    type="submit"
                    loading={isLoggingIn}
                    fullWidth
                    size="md"
                    radius={PILL}
                    color="yellow.5"
                    c="dark"
                    mt="xs"
                  >
                    Sign in
                  </Button>
                </Stack>
              </form>

              <Text size="xs" c="dimmed" maw={360}>
                Internal HR tool &middot; access is limited to the HR Manager account.
              </Text>
            </Stack>
          </Grid.Col>

          {/* Right: a warm gradient panel with floating widgets built from
              real app data, instead of a generic stock photo. */}
          <Grid.Col span={6} display={{ base: 'none', md: 'block' }}>
            <Box
              pos="relative"
              h="100%"
              mih={560}
              style={{
                background: 'linear-gradient(160deg, #fbd784 0%, #f3a93c 55%, #d9811f 100%)',
                overflow: 'hidden',
              }}
            >
              <Card
                shadow="md"
                radius="md"
                pos="absolute"
                top={32}
                left={32}
                p="sm"
                w={220}
              >
                <Group gap="xs" wrap="nowrap">
                  <Box w={8} h={8} bg="green.6" style={{ borderRadius: '50%', flexShrink: 0 }} />
                  <Text size="sm" fw={600}>
                    10,000 employees managed
                  </Text>
                </Group>
                <Text size="xs" c="dimmed" mt={2}>
                  Across 8 countries
                </Text>
              </Card>

              <Card
                shadow="md"
                radius="md"
                pos="absolute"
                top="38%"
                right={32}
                p="md"
                w={200}
              >
                <Group gap="xs" wrap="nowrap">
                  <IconUsersGroup size={18} />
                  <Text size="sm" fw={600}>
                    Pay by Country
                  </Text>
                </Group>
                <Stack gap={6} mt="xs">
                  {[
                    { country: 'United States', width: '85%' },
                    { country: 'India', width: '70%' },
                    { country: 'Germany', width: '55%' },
                  ].map(({ country, width }) => (
                    <Stack key={country} gap={2}>
                      <Text size="xs" c="dimmed">
                        {country}
                      </Text>
                      <Box h={6} bg="orange.1" style={{ borderRadius: 4 }}>
                        <Box h={6} bg="orange.5" style={{ borderRadius: 4, width }} />
                      </Box>
                    </Stack>
                  ))}
                </Stack>
              </Card>

              <Card
                shadow="md"
                radius="md"
                pos="absolute"
                bottom={40}
                left={48}
                p="lg"
                w={240}
              >
                <Text size="xs" c="dimmed">
                  Analytics
                </Text>
                <Title order={2} mt={4}>
                  10,000
                </Title>
                <Text size="sm" c="dimmed">
                  Total employees
                </Text>
              </Card>
            </Box>
          </Grid.Col>
        </Grid>
      </Paper>
    </Box>
  )
}
