import React from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Card,
  CardContent,
  CardActionArea,
  Grid,
  Typography,
  Container,
  Paper,
} from '@mui/material';
import HotelIcon from '@mui/icons-material/Hotel';
import AssignmentLateIcon from '@mui/icons-material/AssignmentLate';
import ScienceIcon from '@mui/icons-material/Science';
import AccessTimeIcon from '@mui/icons-material/AccessTime';
import DescriptionIcon from '@mui/icons-material/Description';

const scenarios = [
  {
    title: 'Capacity Management',
    description: 'Optimize bed utilization and reduce length of stay. Analyze DRG patterns, identify cost opportunities, and improve patient flow efficiency.',
    icon: <HotelIcon sx={{ fontSize: 48 }} />,
    path: '/capacity-management',
    color: '#1976d2',
  },
  {
    title: 'Denials Management',
    description: 'Track denials and optimize appeals strategy. Monitor win rates, identify high-value recovery opportunities, and improve revenue cycle performance.',
    icon: <AssignmentLateIcon sx={{ fontSize: 48 }} />,
    path: '/denials-management',
    color: '#d32f2f',
  },
  {
    title: 'Clinical Trial Matching',
    description: 'Match eligible patients to clinical trials. Identify candidates for KRAS, COPD, and PD-L1 trials based on biomarkers and clinical criteria.',
    icon: <ScienceIcon sx={{ fontSize: 48 }} />,
    path: '/clinical-trials',
    color: '#2e7d32',
  },
  {
    title: 'Timely Filing & Appeals',
    description: 'Monitor compliance deadlines and urgency. Track filing requirements, prevent revenue loss, and manage appeal timelines effectively.',
    icon: <AccessTimeIcon sx={{ fontSize: 48 }} />,
    path: '/timely-filing',
    color: '#ed6c02',
  },
  {
    title: 'Documentation Management',
    description: 'Track documentation requests and SLA compliance. Monitor turnaround times, completion rates, and associated claim values.',
    icon: <DescriptionIcon sx={{ fontSize: 48 }} />,
    path: '/documentation-management',
    color: '#0288d1',
  },
];

function Home() {
  const navigate = useNavigate();

  return (
    <Container maxWidth="lg">
      <Box sx={{ mb: 4 }}>
        <Paper
          elevation={0}
          sx={{
            p: 4,
            background: 'linear-gradient(135deg, #1976d2 0%, #2e7d32 100%)',
            color: 'white',
            borderRadius: 2,
          }}
        >
          <Typography variant="h3" gutterBottom sx={{ fontWeight: 600 }}>
            Welcome to R_Health Analytics
          </Typography>
          <Typography variant="h6" sx={{ opacity: 0.9 }}>
            Healthcare Analytics Platform for Renown Health
          </Typography>
          <Typography variant="body1" sx={{ mt: 2, opacity: 0.85 }}>
            Explore comprehensive analytics across five critical healthcare scenarios. Select a scenario below to get started.
          </Typography>
        </Paper>
      </Box>

      <Grid container spacing={3}>
        {scenarios.map((scenario) => (
          <Grid item xs={12} md={6} key={scenario.title}>
            <Card
              sx={{
                height: '100%',
                transition: 'transform 0.2s, box-shadow 0.2s',
                '&:hover': {
                  transform: 'translateY(-4px)',
                  boxShadow: 6,
                },
              }}
            >
              <CardActionArea
                onClick={() => navigate(scenario.path)}
                sx={{ height: '100%', p: 2 }}
              >
                <CardContent>
                  <Box
                    sx={{
                      display: 'flex',
                      alignItems: 'center',
                      mb: 2,
                      color: scenario.color,
                    }}
                  >
                    {scenario.icon}
                    <Typography
                      variant="h5"
                      component="div"
                      sx={{ ml: 2, fontWeight: 600 }}
                    >
                      {scenario.title}
                    </Typography>
                  </Box>
                  <Typography variant="body2" color="text.secondary" sx={{ lineHeight: 1.7 }}>
                    {scenario.description}
                  </Typography>
                </CardContent>
              </CardActionArea>
            </Card>
          </Grid>
        ))}
      </Grid>

      <Box sx={{ mt: 4 }}>
        <Paper sx={{ p: 3, backgroundColor: '#f5f5f5' }}>
          <Typography variant="h6" gutterBottom sx={{ fontWeight: 500 }}>
            About R_Health
          </Typography>
          <Typography variant="body2" color="text.secondary" paragraph>
            R_Health is a comprehensive healthcare analytics platform designed to provide actionable insights
            across critical operational areas. Our solution leverages Databricks Lakehouse architecture to deliver
            real-time analytics and data-driven decision making.
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Built with React 18, Material-UI, and FastAPI, this platform demonstrates modern healthcare analytics
            capabilities including capacity optimization, revenue cycle management, clinical trial matching, and
            compliance monitoring.
          </Typography>
        </Paper>
      </Box>
    </Container>
  );
}

export default Home;
