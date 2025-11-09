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
} from '@mui/material';
import { DataGrid } from '@mui/x-data-grid';
import { PieChart, Pie, Cell, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import AssignmentLateIcon from '@mui/icons-material/AssignmentLate';
import GavelIcon from '@mui/icons-material/Gavel';
import AttachMoneyIcon from '@mui/icons-material/AttachMoney';
import TrendingUpIcon from '@mui/icons-material/TrendingUp';
import { getDenialsManagement, getDenialsSummary, getPayers } from '../services/api';

const COLORS = ['#1976d2', '#2e7d32', '#ed6c02', '#d32f2f', '#9c27b0', '#00897b'];

function DenialsManagement() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [summary, setSummary] = useState({});
  const [data, setData] = useState([]);
  const [filteredData, setFilteredData] = useState([]);
  const [payers, setPayers] = useState([]);
  const [payerFilter, setPayerFilter] = useState('All');

  useEffect(() => {
    fetchData();
  }, []);

  useEffect(() => {
    if (payerFilter === 'All') {
      setFilteredData(data);
    } else {
      setFilteredData(data.filter(row => row.payer_name === payerFilter));
    }
  }, [payerFilter, data]);

  const fetchData = async () => {
    try {
      setLoading(true);
      const [summaryData, denialsData, payersData] = await Promise.all([
        getDenialsSummary(),
        getDenialsManagement({ limit: 100 }),
        getPayers(),
      ]);
      setSummary(summaryData);
      setData(denialsData);
      setFilteredData(denialsData);
      setPayers(payersData);
      setError(null);
    } catch (err) {
      setError('Failed to load denials management data. Please ensure the backend is running.');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const columns = [
    { field: 'payer_name', headerName: 'Payer', width: 150 },
    { field: 'drg_code', headerName: 'DRG Code', width: 120 },
    { field: 'denial_category', headerName: 'Denial Category', width: 180 },
    {
      field: 'total_denials',
      headerName: 'Total Denials',
      width: 130,
      type: 'number',
    },
    {
      field: 'appeal_win_rate',
      headerName: 'Win Rate (%)',
      width: 120,
      type: 'number',
      valueFormatter: (params) => `${params.value?.toFixed(1)}%`,
      cellClassName: (params) => {
        if (params.value >= 70) return 'win-rate-high';
        if (params.value >= 50) return 'win-rate-medium';
        return 'win-rate-low';
      },
    },
    {
      field: 'recovered_amount',
      headerName: 'Recovered Amount',
      width: 160,
      type: 'number',
      valueFormatter: (params) => `$${params.value?.toLocaleString()}`,
    },
    {
      field: 'total_denied_amount',
      headerName: 'Denied Amount',
      width: 150,
      type: 'number',
      valueFormatter: (params) => `$${params.value?.toLocaleString()}`,
    },
    {
      field: 'priority_score',
      headerName: 'Priority Score',
      width: 130,
      type: 'number',
      valueFormatter: (params) => params.value?.toFixed(2),
    },
  ];

  // Prepare pie chart data - denials by category
  const categoryData = data.reduce((acc, item) => {
    const category = item.denial_category || 'Other';
    const existing = acc.find(d => d.name === category);
    if (existing) {
      existing.value += item.total_denials || 0;
    } else {
      acc.push({ name: category, value: item.total_denials || 0 });
    }
    return acc;
  }, []);

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
        Denials Management
      </Typography>

      {/* Summary Cards */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="textSecondary" variant="body2">
                    Total Denials
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {summary.total_denials?.toLocaleString() || 0}
                  </Typography>
                </Box>
                <AssignmentLateIcon sx={{ fontSize: 40, color: 'error.main', opacity: 0.7 }} />
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
                    Total Appealed
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {summary.total_appealed?.toLocaleString() || 0}
                  </Typography>
                </Box>
                <GavelIcon sx={{ fontSize: 40, color: 'primary.main', opacity: 0.7 }} />
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
                    Recovered Amount
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    ${(summary.total_recovered / 1000000).toFixed(1)}M
                  </Typography>
                </Box>
                <AttachMoneyIcon sx={{ fontSize: 40, color: 'success.main', opacity: 0.7 }} />
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
                    Avg Win Rate
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {summary.avg_win_rate?.toFixed(1)}%
                  </Typography>
                </Box>
                <TrendingUpIcon sx={{ fontSize: 40, color: 'info.main', opacity: 0.7 }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Chart */}
      <Paper sx={{ p: 3, mb: 3 }}>
        <Typography variant="h6" gutterBottom sx={{ fontWeight: 500 }}>
          Denials by Category
        </Typography>
        <ResponsiveContainer width="100%" height={300}>
          <PieChart>
            <Pie
              data={categoryData}
              cx="50%"
              cy="50%"
              labelLine={false}
              label={({ name, percent }) => `${name}: ${(percent * 100).toFixed(0)}%`}
              outerRadius={100}
              fill="#8884d8"
              dataKey="value"
            >
              {categoryData.map((entry, index) => (
                <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
              ))}
            </Pie>
            <Tooltip />
            <Legend />
          </PieChart>
        </ResponsiveContainer>
      </Paper>

      {/* Filters */}
      <Box sx={{ mb: 2 }}>
        <FormControl sx={{ minWidth: 200 }}>
          <InputLabel>Payer Filter</InputLabel>
          <Select
            value={payerFilter}
            label="Payer Filter"
            onChange={(e) => setPayerFilter(e.target.value)}
          >
            <MenuItem value="All">All Payers</MenuItem>
            {payers.map((payer) => (
              <MenuItem key={payer.payer_name} value={payer.payer_name}>
                {payer.payer_name}
              </MenuItem>
            ))}
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
            '& .win-rate-high': {
              backgroundColor: '#e8f5e9',
            },
            '& .win-rate-medium': {
              backgroundColor: '#fff3e0',
            },
            '& .win-rate-low': {
              backgroundColor: '#ffebee',
            },
          }}
        />
      </Paper>
    </Box>
  );
}

export default DenialsManagement;
