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
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import HotelIcon from '@mui/icons-material/Hotel';
import TrendingUpIcon from '@mui/icons-material/TrendingUp';
import PeopleIcon from '@mui/icons-material/People';
import WarningIcon from '@mui/icons-material/Warning';
import { getCapacityManagement, getCapacitySummary } from '../services/api';

function CapacityManagement() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [summary, setSummary] = useState({});
  const [data, setData] = useState([]);
  const [filteredData, setFilteredData] = useState([]);
  const [priorityFilter, setPriorityFilter] = useState('All');

  useEffect(() => {
    fetchData();
  }, []);

  useEffect(() => {
    if (priorityFilter === 'All') {
      setFilteredData(data);
    } else {
      setFilteredData(data.filter(row => row.optimization_priority?.includes(priorityFilter)));
    }
  }, [priorityFilter, data]);

  const fetchData = async () => {
    try {
      setLoading(true);
      const [summaryData, capacityData] = await Promise.all([
        getCapacitySummary(),
        getCapacityManagement({ limit: 100 }),
      ]);
      setSummary(summaryData);
      setData(capacityData);
      setFilteredData(capacityData);
      setError(null);
    } catch (err) {
      setError('Failed to load capacity management data. Please ensure the backend is running.');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const columns = [
    { field: 'drg_code', headerName: 'DRG Code', width: 120 },
    { field: 'primary_diagnosis_code', headerName: 'Diagnosis', width: 130 },
    {
      field: 'total_encounters',
      headerName: 'Encounters',
      width: 120,
      type: 'number',
    },
    {
      field: 'avg_los',
      headerName: 'Avg LOS',
      width: 100,
      type: 'number',
      valueFormatter: (params) => params.value?.toFixed(2),
    },
    {
      field: 'gmlos_benchmark',
      headerName: 'GMLOS',
      width: 100,
      type: 'number',
      valueFormatter: (params) => params.value?.toFixed(2),
    },
    {
      field: 'avg_los_variance',
      headerName: 'Variance',
      width: 110,
      type: 'number',
      valueFormatter: (params) => params.value?.toFixed(2),
      cellClassName: (params) => {
        if (params.value > 2) return 'variance-high';
        if (params.value > 1) return 'variance-medium';
        return '';
      },
    },
    {
      field: 'estimated_cost_opportunity',
      headerName: 'Cost Opportunity',
      width: 160,
      type: 'number',
      valueFormatter: (params) => `$${params.value?.toLocaleString()}`,
    },
    {
      field: 'optimization_priority',
      headerName: 'Priority',
      width: 150,
      renderCell: (params) => {
        const priority = params.value || '';
        let color = 'default';
        if (priority.includes('Critical')) color = 'error';
        else if (priority.includes('High')) color = 'warning';
        else color = 'success';

        return (
          <Typography variant="body2" color={`${color}.main`} sx={{ fontWeight: 500 }}>
            {priority}
          </Typography>
        );
      },
    },
  ];

  // Prepare chart data - top 10 DRGs by cost opportunity
  const chartData = data
    .slice(0, 10)
    .map(item => ({
      name: item.drg_code,
      cost: parseFloat(item.estimated_cost_opportunity) || 0,
    }));

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
        Capacity Management
      </Typography>

      {/* Summary Cards */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="textSecondary" variant="body2">
                    Total DRGs
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {summary.total_drgs || 0}
                  </Typography>
                </Box>
                <HotelIcon sx={{ fontSize: 40, color: 'primary.main', opacity: 0.7 }} />
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
                    Total Encounters
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {summary.total_encounters?.toLocaleString() || 0}
                  </Typography>
                </Box>
                <PeopleIcon sx={{ fontSize: 40, color: 'info.main', opacity: 0.7 }} />
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
                    Cost Opportunity
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    ${(summary.total_cost_opportunity / 1000000).toFixed(1)}M
                  </Typography>
                </Box>
                <TrendingUpIcon sx={{ fontSize: 40, color: 'success.main', opacity: 0.7 }} />
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
                    Critical Priority
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {summary.critical_count || 0}
                  </Typography>
                </Box>
                <WarningIcon sx={{ fontSize: 40, color: 'error.main', opacity: 0.7 }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Chart */}
      <Paper sx={{ p: 3, mb: 3 }}>
        <Typography variant="h6" gutterBottom sx={{ fontWeight: 500 }}>
          Top 10 DRGs by Cost Opportunity
        </Typography>
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={chartData}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="name" />
            <YAxis />
            <Tooltip formatter={(value) => `$${value.toLocaleString()}`} />
            <Legend />
            <Bar dataKey="cost" fill="#1976d2" name="Cost Opportunity ($)" />
          </BarChart>
        </ResponsiveContainer>
      </Paper>

      {/* Filters */}
      <Box sx={{ mb: 2 }}>
        <FormControl sx={{ minWidth: 200 }}>
          <InputLabel>Priority Filter</InputLabel>
          <Select
            value={priorityFilter}
            label="Priority Filter"
            onChange={(e) => setPriorityFilter(e.target.value)}
          >
            <MenuItem value="All">All Priorities</MenuItem>
            <MenuItem value="Critical">Critical</MenuItem>
            <MenuItem value="High">High</MenuItem>
            <MenuItem value="Low">Low</MenuItem>
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
            '& .variance-high': {
              backgroundColor: '#ffebee',
            },
            '& .variance-medium': {
              backgroundColor: '#fff3e0',
            },
          }}
        />
      </Paper>
    </Box>
  );
}

export default CapacityManagement;
