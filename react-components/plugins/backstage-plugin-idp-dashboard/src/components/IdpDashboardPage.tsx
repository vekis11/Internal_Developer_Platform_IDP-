import React from 'react';
import { makeStyles } from '@material-ui/core/styles';
import {
  Page,
  Header,
  Content,
  HeaderLabel,
  ContentHeader,
  SupportButton,
  Grid,
  Card,
  CardContent,
  Typography,
  Box,
  Chip,
  IconButton,
  Tooltip,
} from '@material-ui/core';
import {
  CloudQueue,
  Storage,
  Build,
  Security,
  Assessment,
  Book,
  Add,
  Refresh,
  Settings,
} from '@material-ui/icons';

const useStyles = makeStyles(theme => ({
  root: {
    display: 'flex',
    flexDirection: 'column',
    height: '100%',
  },
  header: {
    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
    color: 'white',
  },
  content: {
    flex: 1,
    padding: theme.spacing(3),
  },
  card: {
    height: '100%',
    display: 'flex',
    flexDirection: 'column',
    transition: 'transform 0.2s ease-in-out',
    '&:hover': {
      transform: 'translateY(-2px)',
      boxShadow: theme.shadows[8],
    },
  },
  cardHeader: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: theme.spacing(2),
  },
  cardTitle: {
    display: 'flex',
    alignItems: 'center',
    gap: theme.spacing(1),
  },
  metric: {
    textAlign: 'center',
    padding: theme.spacing(2),
  },
  metricValue: {
    fontSize: '2rem',
    fontWeight: 'bold',
    color: theme.palette.primary.main,
  },
  metricLabel: {
    color: theme.palette.text.secondary,
    marginTop: theme.spacing(1),
  },
  statusChip: {
    marginLeft: theme.spacing(1),
  },
  actionButton: {
    marginLeft: 'auto',
  },
}));

export const IdpDashboardPage = () => {
  const classes = useStyles();

  const quickActions = [
    { title: 'Create Service', icon: <Add />, color: '#4caf50' },
    { title: 'Deploy to Dev', icon: <CloudQueue />, color: '#2196f3' },
    { title: 'View Logs', icon: <Assessment />, color: '#ff9800' },
    { title: 'Security Scan', icon: <Security />, color: '#f44336' },
  ];

  const metrics = [
    { label: 'Active Services', value: '24', trend: '+12%' },
    { label: 'Deployments Today', value: '8', trend: '+3' },
    { label: 'Build Success Rate', value: '98.5%', trend: '+2.1%' },
    { label: 'Security Issues', value: '2', trend: '-5' },
  ];

  return (
    <Page themeId="tool">
      <Header
        title="Internal Developer Platform"
        subtitle="Self-service developer portal"
        className={classes.header}
      >
        <HeaderLabel label="Owner" value="Platform Team" />
        <HeaderLabel label="Lifecycle" value="Production" />
        <HeaderLabel label="Status" value="Healthy" />
      </Header>
      <Content className={classes.content}>
        <ContentHeader title="Dashboard">
          <SupportButton>
            This is the main dashboard for the Internal Developer Platform.
          </SupportButton>
        </ContentHeader>

        {/* Quick Actions */}
        <Box mb={3}>
          <Typography variant="h6" gutterBottom>
            Quick Actions
          </Typography>
          <Grid container spacing={2}>
            {quickActions.map((action, index) => (
              <Grid item xs={6} sm={3} key={index}>
                <Card className={classes.card}>
                  <CardContent>
                    <Box
                      display="flex"
                      alignItems="center"
                      justifyContent="center"
                      flexDirection="column"
                      p={2}
                    >
                      <Box
                        p={1}
                        borderRadius="50%"
                        bgcolor={action.color}
                        color="white"
                        mb={1}
                      >
                        {action.icon}
                      </Box>
                      <Typography variant="body2" align="center">
                        {action.title}
                      </Typography>
                    </Box>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        </Box>

        {/* Metrics Overview */}
        <Box mb={3}>
          <Typography variant="h6" gutterBottom>
            Platform Metrics
          </Typography>
          <Grid container spacing={3}>
            {metrics.map((metric, index) => (
              <Grid item xs={6} sm={3} key={index}>
                <Card className={classes.card}>
                  <CardContent className={classes.metric}>
                    <Typography className={classes.metricValue}>
                      {metric.value}
                    </Typography>
                    <Typography className={classes.metricLabel}>
                      {metric.label}
                    </Typography>
                    <Chip
                      label={metric.trend}
                      size="small"
                      color={metric.trend.startsWith('+') ? 'primary' : 'secondary'}
                      className={classes.statusChip}
                    />
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        </Box>

        {/* Service Catalog */}
        <Box mb={3}>
          <Card className={classes.card}>
            <CardContent>
              <div className={classes.cardHeader}>
                <div className={classes.cardTitle}>
                  <Storage />
                  <Typography variant="h6">Service Catalog</Typography>
                  <Chip label="24 Services" color="primary" size="small" />
                </div>
                <Tooltip title="Refresh">
                  <IconButton size="small">
                    <Refresh />
                  </IconButton>
                </Tooltip>
              </div>
              <Typography variant="body2" color="textSecondary">
                Browse and manage your services, APIs, and resources
              </Typography>
            </CardContent>
          </Card>
        </Box>

        {/* Kubernetes Overview */}
        <Box mb={3}>
          <Card className={classes.card}>
            <CardContent>
              <div className={classes.cardHeader}>
                <div className={classes.cardTitle}>
                  <CloudQueue />
                  <Typography variant="h6">Kubernetes Clusters</Typography>
                  <Chip label="3 Clusters" color="primary" size="small" />
                </div>
                <Tooltip title="Settings">
                  <IconButton size="small">
                    <Settings />
                  </IconButton>
                </Tooltip>
              </div>
              <Typography variant="body2" color="textSecondary">
                Monitor your development, staging, and production environments
              </Typography>
            </CardContent>
          </Card>
        </Box>

        {/* CI/CD Pipeline */}
        <Box mb={3}>
          <Card className={classes.card}>
            <CardContent>
              <div className={classes.cardHeader}>
                <div className={classes.cardTitle}>
                  <Build />
                  <Typography variant="h6">CI/CD Pipeline</Typography>
                  <Chip label="Running" color="primary" size="small" />
                </div>
                <Tooltip title="View Details">
                  <IconButton size="small">
                    <Assessment />
                  </IconButton>
                </Tooltip>
              </div>
              <Typography variant="body2" color="textSecondary">
                Track your GitHub Actions, Jenkins, and ArgoCD deployments
              </Typography>
            </CardContent>
          </Card>
        </Box>

        {/* Documentation */}
        <Box mb={3}>
          <Card className={classes.card}>
            <CardContent>
              <div className={classes.cardHeader}>
                <div className={classes.cardTitle}>
                  <Book />
                  <Typography variant="h6">Documentation</Typography>
                  <Chip label="Updated" color="primary" size="small" />
                </div>
                <Tooltip title="View Docs">
                  <IconButton size="small">
                    <Book />
                  </IconButton>
                </Tooltip>
              </div>
              <Typography variant="body2" color="textSecondary">
                Access runbooks, guides, and technical documentation
              </Typography>
            </CardContent>
          </Card>
        </Box>
      </Content>
    </Page>
  );
}; 