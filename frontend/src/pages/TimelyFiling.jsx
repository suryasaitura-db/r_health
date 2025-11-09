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
  Chip,
} from '@mui/material';
import { DataGrid } from '@mui/x-data-grid';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import AccessTimeIcon from '@mui/icons-material/AccessTime';
import WarningIcon from '@mui/icons-material/Warning';
import AttachMoneyIcon from '@mui/icons-material/AttachMoney';
import AssignmentIcon from '@mui/icons-material/Assignment';
import { getTimelyFilingAppeals, getTimelyFilingSummary } from '../services/api';

function TimelyFiling() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [summary, setSummary] = useState({});
  const [data, setData] = useState([]);
  const [filteredData, setFilteredData] = useState([]);
  const [urgencyFilter, setUrgencyFilter] = useState('All');

  useEffect(() => {
    fetchData();
  }, []);

  useEffect(() => {
    if (urgencyFilter === 'All') {
      setFilteredData(data);
    } else {
      const filters = {
        'Critical': (row) => row.urgency_score >= 90,
        'High': (row) => row.urgency_score >= 70 && row.urgency_score < 90,
        'Medium': (row) => row.urgency_score >= 40 && row.urgency_score < 70,
        'Low': (row) => row.urgency_score < 40,
      };
      setFilteredData(data.filter(filters[urgencyFilter]));
    }
  }, [urgencyFilter, data]);

  const fetchData = async () => {
    try {
      setLoading(true);
      const [summaryData, filingData] = await Promise.all([
        getTimelyFilingSummary(),
        getTimelyFilingAppeals({ limit: 100 }),
      ]);
      setSummary(summaryData);
      setData(filingData);
      setFilteredData(filingData);
      setError(null);
    } catch (err) {
      setError('Failed to load timely filing data. Please ensure the backend is running.');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const getUrgencyColor = (score) => {
    if (score >= 90) return 'error';
    if (score >= 70) return 'warning';
    if (score >= 40) return 'info';
    return 'success';
  };

  const getUrgencyLabel = (score) => {
    if (score >= 90) return 'Critical';
    if (score >= 70) return 'High';
    if (score >= 40) return 'Medium';
    return 'Low';
  };

  const columns = [
    { field: 'claim_id', headerName: 'Claim ID', width: 120 },
    { field: 'payer_name', headerName: 'Payer', width: 150 },
    { field: 'drg_code', headerName: 'DRG Code', width: 100 },
    {
      field: 'billed_amount',
      headerName: 'Billed Amount',
      width: 140,
      type: 'number',
      valueFormatter: (params) => `$${params.value?.toLocaleString()}`,
    },
    {
      field: 'days_to_deadline',
      headerName: 'Days to Deadline',
      width: 150,
      type: 'number',
      cellClassName: (params) => {
        if (params.value <= 7) return 'deadline-critical';
        if (params.value <= 14) return 'deadline-warning';
        return '';
      },
    },
    {
      field: 'urgency_score',
      headerName: 'Urgency',
      width: 130,
      renderCell: (params) => (
        <Chip
          label={`${getUrgencyLabel(params.value)} (${params.value})`}
          color={getUrgencyColor(params.value)}
          size="small"
        />
      ),
    },
    {
      field: 'compliance_status',
      headerName: 'Status',
      width: 130,
      renderCell: (params) => {
        const status = params.value || 'Unknown';
        let color = 'default';
        if (status.includes('Compliant')) color = 'success';
        else if (status.includes('At Risk')) color = 'warning';
        else if (status.includes('Critical')) color = 'error';

        return (
          <Chip label={status} color={color} size="small" variant="outlined" />
        );
      },
    },
    {
      field: 'action_required',
      headerName: 'Action Required',
      width: 200,
    },
  ];

  // Prepare chart data - claims by urgency level
  const urgencyCategories = [
    { name: 'Critical (90+)', count: data.filter(d => d.urgency_score >= 90).length },
    { name: 'High (70-89)', count: data.filter(d => d.urgency_score >= 70 && d.urgency_score < 90).length },
    { name: 'Medium (40-69)', count: data.filter(d => d.urgency_score >= 40 && d.urgency_score < 70).length },
    { name: 'Low (<40)', count: data.filter(d => d.urgency_score < 40).length },
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
        Timely Filing & Appeals
      </Typography>

      {/* Summary Cards */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="textSecondary" variant="body2">
                    Total Claims
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {summary.total_claims || 0}
                  </Typography>
                </Box>
                <AssignmentIcon sx={{ fontSize: 40, color: 'primary.main', opacity: 0.7 }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="textSecondary" variant="body2">
                    At-Risk Claims
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {summary.at_risk_claims || 0}
                  </Typography>
                </Box>
                <AccessTimeIcon sx={{ fontSize: 40, color: 'warning.main', opacity: 0.7 }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="textSecondary" variant="body2">
                    Critical Urgency
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {summary.critical_urgency || 0}
                  </Typography>
                </Box>
                <WarningIcon sx={{ fontSize: 40, color: 'error.main', opacity: 0.7 }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="textSecondary" variant="body2">
                    At-Risk Amount
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    ${(summary.total_at_risk_amount / 1000000).toFixed(1)}M
                  </Typography>
                </Box>
                <AttachMoneyIcon sx={{ fontSize: 40, color: 'success.main', opacity: 0.7 }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Chart */}
      <Paper sx={{ p: 3, mb: 3 }}>
        <Typography variant="h6" gutterBottom sx={{ fontWeight: 500 }}>
          Claims by Urgency Level
        </Typography>
        <ResponsiveContainer width="100%" height={300}>
          <LineChart data={urgencyCategories}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="name" />
            <YAxis />
            <Tooltip />
            <Legend />
            <Line type="monotone" dataKey="count" stroke="#1976d2" strokeWidth={2} name="Number of Claims" />
          </LineChart>
        </ResponsiveContainer>
      </Paper>

      {/* Filters */}
      <Box sx={{ mb: 2 }}>
        <FormControl sx={{ minWidth: 200 }}>
          <InputLabel>Urgency Filter</InputLabel>
          <Select
            value={urgencyFilter}
            label="Urgency Filter"
            onChange={(e) => setUrgencyFilter(e.target.value)}
          >
            <MenuItem value="All">All Urgency Levels</MenuItem>
            <MenuItem value="Critical">Critical (90+)</MenuItem>
            <MenuItem value="High">High (70-89)</MenuItem>
            <MenuItem value="Medium">Medium (40-69)</MenuItem>
            <MenuItem value="Low">Low (&lt;40)</MenuItem>
          </Select>
        </FormControl>
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
            '& .deadline-critical': {
              backgroundColor: '#ffebee',
              fontWeight: 600,
            },
            '& .deadline-warning': {
              backgroundColor: '#fff3e0',
            },
          }}
        />
      </Paper>
    </Box>
  );
}

export default TimelyFiling;
