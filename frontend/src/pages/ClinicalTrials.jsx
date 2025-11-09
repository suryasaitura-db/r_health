import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Grid,
  Typography,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  CircularProgress,
  Alert,
  Paper,
  FormControlLabel,
  Switch,
} from '@mui/material';
import { DataGrid } from '@mui/x-data-grid';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import ScienceIcon from '@mui/icons-material/Science';
import PersonIcon from '@mui/icons-material/Person';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import { getClinicalTrialMatching, getClinicalTrialSummary } from '../services/api';

function ClinicalTrials() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [summary, setSummary] = useState({});
  const [data, setData] = useState([]);
  const [filteredData, setFilteredData] = useState([]);
  const [trialTypeFilter, setTrialTypeFilter] = useState('All');
  const [eligibleOnly, setEligibleOnly] = useState(false);

  useEffect(() => {
    fetchData();
  }, []);

  useEffect(() => {
    let filtered = data;

    if (eligibleOnly) {
      filtered = filtered.filter(row => row.eligible_trial_count > 0);
    }

    if (trialTypeFilter !== 'All') {
      const trialField = `${trialTypeFilter.toLowerCase()}_trial_eligible`;
      filtered = filtered.filter(row => row[trialField] === true);
    }

    setFilteredData(filtered);
  }, [trialTypeFilter, eligibleOnly, data]);

  const fetchData = async () => {
    try {
      setLoading(true);
      const [summaryData, trialsData] = await Promise.all([
        getClinicalTrialSummary(),
        getClinicalTrialMatching({ limit: 100 }),
      ]);
      setSummary(summaryData);
      setData(trialsData);
      setFilteredData(trialsData);
      setError(null);
    } catch (err) {
      setError('Failed to load clinical trial data. Please ensure the backend is running.');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const columns = [
    { field: 'patient_id', headerName: 'Patient ID', width: 120 },
    {
      field: 'age',
      headerName: 'Age',
      width: 80,
      type: 'number',
    },
    { field: 'gender', headerName: 'Gender', width: 90 },
    { field: 'primary_diagnosis', headerName: 'Diagnosis', width: 180 },
    { field: 'biomarker_status', headerName: 'Biomarker Status', width: 150 },
    {
      field: 'kras_trial_eligible',
      headerName: 'KRAS Eligible',
      width: 130,
      renderCell: (params) => (
        <Box display="flex" alignItems="center">
          {params.value ? (
            <CheckCircleIcon sx={{ color: 'success.main', fontSize: 20 }} />
          ) : (
            <Typography variant="body2" color="text.secondary">
              -
            </Typography>
          )}
        </Box>
      ),
    },
    {
      field: 'copd_trial_eligible',
      headerName: 'COPD Eligible',
      width: 130,
      renderCell: (params) => (
        <Box display="flex" alignItems="center">
          {params.value ? (
            <CheckCircleIcon sx={{ color: 'success.main', fontSize: 20 }} />
          ) : (
            <Typography variant="body2" color="text.secondary">
              -
            </Typography>
          )}
        </Box>
      ),
    },
    {
      field: 'pdl1_trial_eligible',
      headerName: 'PD-L1 Eligible',
      width: 130,
      renderCell: (params) => (
        <Box display="flex" alignItems="center">
          {params.value ? (
            <CheckCircleIcon sx={{ color: 'success.main', fontSize: 20 }} />
          ) : (
            <Typography variant="body2" color="text.secondary">
              -
            </Typography>
          )}
        </Box>
      ),
    },
    {
      field: 'eligible_trial_count',
      headerName: 'Trial Count',
      width: 110,
      type: 'number',
      cellClassName: (params) => {
        if (params.value > 1) return 'multi-trial-eligible';
        return '';
      },
    },
  ];

  // Prepare chart data
  const chartData = [
    {
      name: 'KRAS',
      eligible: summary.kras_eligible || 0,
    },
    {
      name: 'COPD',
      eligible: summary.copd_eligible || 0,
    },
    {
      name: 'PD-L1',
      eligible: summary.pdl1_eligible || 0,
    },
  ];

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Alert severity="error" sx={{ mb: 2 }}>
        {error}
      </Alert>
    );
  }

  return (
    <Box>
      <Typography variant="h4" gutterBottom sx={{ fontWeight: 600, mb: 3 }}>
        Clinical Trial Matching
      </Typography>

      {/* Summary Cards */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="textSecondary" variant="body2">
                    Total Patients
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {summary.total_patients || 0}
                  </Typography>
                </Box>
                <PersonIcon sx={{ fontSize: 40, color: 'primary.main', opacity: 0.7 }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ backgroundColor: '#e3f2fd' }}>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="textSecondary" variant="body2">
                    KRAS Eligible
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {summary.kras_eligible || 0}
                  </Typography>
                </Box>
                <ScienceIcon sx={{ fontSize: 40, color: 'primary.main', opacity: 0.7 }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ backgroundColor: '#e8f5e9' }}>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="textSecondary" variant="body2">
                    COPD Eligible
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {summary.copd_eligible || 0}
                  </Typography>
                </Box>
                <ScienceIcon sx={{ fontSize: 40, color: 'success.main', opacity: 0.7 }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ backgroundColor: '#fff3e0' }}>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="textSecondary" variant="body2">
                    PD-L1 Eligible
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {summary.pdl1_eligible || 0}
                  </Typography>
                </Box>
                <ScienceIcon sx={{ fontSize: 40, color: 'warning.main', opacity: 0.7 }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Chart */}
      <Paper sx={{ p: 3, mb: 3 }}>
        <Typography variant="h6" gutterBottom sx={{ fontWeight: 500 }}>
          Eligible Patients by Trial Type
        </Typography>
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={chartData}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="name" />
            <YAxis />
            <Tooltip />
            <Legend />
            <Bar dataKey="eligible" fill="#1976d2" name="Eligible Patients" />
          </BarChart>
        </ResponsiveContainer>
      </Paper>

      {/* Filters */}
      <Box sx={{ mb: 2, display: 'flex', gap: 2, alignItems: 'center' }}>
        <FormControl sx={{ minWidth: 200 }}>
          <InputLabel>Trial Type Filter</InputLabel>
          <Select
            value={trialTypeFilter}
            label="Trial Type Filter"
            onChange={(e) => setTrialTypeFilter(e.target.value)}
          >
            <MenuItem value="All">All Trials</MenuItem>
            <MenuItem value="KRAS">KRAS</MenuItem>
            <MenuItem value="COPD">COPD</MenuItem>
            <MenuItem value="PDL1">PD-L1</MenuItem>
          </Select>
        </FormControl>

        <FormControlLabel
          control={
            <Switch
              checked={eligibleOnly}
              onChange={(e) => setEligibleOnly(e.target.checked)}
              color="primary"
            />
          }
          label="Show Eligible Only"
        />
      </Box>

      {/* Data Grid */}
      <Paper sx={{ height: 600, width: '100%' }}>
        <DataGrid
          rows={filteredData.map((row, index) => ({ id: index, ...row }))}
          columns={columns}
          pageSize={10}
          rowsPerPageOptions={[10, 25, 50]}
          disableSelectionOnClick
          sx={{
            '& .multi-trial-eligible': {
              backgroundColor: '#e3f2fd',
              fontWeight: 600,
            },
          }}
        />
      </Paper>
    </Box>
  );
}

export default ClinicalTrials;
