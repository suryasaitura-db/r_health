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
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import DescriptionIcon from '@mui/icons-material/Description';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import TimerIcon from '@mui/icons-material/Timer';
import VerifiedIcon from '@mui/icons-material/Verified';
import { getDocumentationManagement, getDocumentationSummary, getPayers } from '../services/api';

function DocumentationManagement() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [summary, setSummary] = useState({});
  const [data, setData] = useState([]);
  const [filteredData, setFilteredData] = useState([]);
  const [payers, setPayers] = useState([]);
  const [payerFilter, setPayerFilter] = useState('All');
  const [urgencyFilter, setUrgencyFilter] = useState('All');

  useEffect(() => {
    fetchData();
  }, []);

  useEffect(() => {
    let filtered = data;

    if (payerFilter !== 'All') {
      filtered = filtered.filter(row => row.payer_name === payerFilter);
    }

    if (urgencyFilter !== 'All') {
      filtered = filtered.filter(row => row.request_urgency === urgencyFilter);
    }

    setFilteredData(filtered);
  }, [payerFilter, urgencyFilter, data]);

  const fetchData = async () => {
    try {
      setLoading(true);
      const [summaryData, docData, payersData] = await Promise.all([
        getDocumentationSummary(),
        getDocumentationManagement({ limit: 100 }),
        getPayers(),
      ]);
      setSummary(summaryData);
      setData(docData);
      setFilteredData(docData);
      setPayers(payersData);
      setError(null);
    } catch (err) {
      setError('Failed to load documentation management data. Please ensure the backend is running.');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const columns = [
    { field: 'documentation_type', headerName: 'Documentation Type', width: 200 },
    { field: 'payer_name', headerName: 'Payer', width: 150 },
    { field: 'drg_code', headerName: 'DRG Code', width: 100 },
    {
      field: 'request_urgency',
      headerName: 'Urgency',
      width: 120,
      renderCell: (params) => {
        const urgency = params.value || 'Normal';
        let color = 'default';
        if (urgency === 'Urgent') color = 'error';
        else if (urgency === 'High') color = 'warning';
        else color = 'info';

        return <Chip label={urgency} color={color} size="small" />;
      },
    },
    {
      field: 'total_requests',
      headerName: 'Total Requests',
      width: 130,
      type: 'number',
    },
    {
      field: 'completion_rate',
      headerName: 'Completion Rate',
      width: 150,
      type: 'number',
      valueFormatter: (params) => `${params.value?.toFixed(1)}%`,
      cellClassName: (params) => {
        if (params.value >= 90) return 'completion-high';
        if (params.value >= 70) return 'completion-medium';
        return 'completion-low';
      },
    },
    {
      field: 'avg_turnaround_days',
      headerName: 'Avg Turnaround',
      width: 150,
      type: 'number',
      valueFormatter: (params) => `${params.value?.toFixed(1)} days`,
    },
    {
      field: 'sla_compliance_score',
      headerName: 'SLA Compliance',
      width: 150,
      type: 'number',
      valueFormatter: (params) => `${params.value?.toFixed(1)}%`,
      cellClassName: (params) => {
        if (params.value >= 95) return 'sla-excellent';
        if (params.value >= 85) return 'sla-good';
        return 'sla-needs-improvement';
      },
    },
    {
      field: 'associated_claim_value',
      headerName: 'Claim Value',
      width: 150,
      type: 'number',
      valueFormatter: (params) => `$${params.value?.toLocaleString()}`,
    },
  ];

  // Prepare chart data - requests by documentation type
  const docTypeData = data.reduce((acc, item) => {
    const type = item.documentation_type || 'Other';
    const existing = acc.find(d => d.name === type);
    if (existing) {
      existing.requests += item.total_requests || 0;
    } else {
      acc.push({ name: type, requests: item.total_requests || 0 });
    }
    return acc;
  }, [])
  .sort((a, b) => b.requests - a.requests)
  .slice(0, 8);

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
        Documentation Management
      </Typography>

      {/* Summary Cards */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="textSecondary" variant="body2">
                    Total Requests
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {summary.total_requests?.toLocaleString() || 0}
                  </Typography>
                </Box>
                <DescriptionIcon sx={{ fontSize: 40, color: 'primary.main', opacity: 0.7 }} />
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
                    Completed
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {summary.total_completed?.toLocaleString() || 0}
                  </Typography>
                </Box>
                <CheckCircleIcon sx={{ fontSize: 40, color: 'success.main', opacity: 0.7 }} />
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
                    Avg Turnaround
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {summary.overall_avg_turnaround?.toFixed(1) || 0} days
                  </Typography>
                </Box>
                <TimerIcon sx={{ fontSize: 40, color: 'info.main', opacity: 0.7 }} />
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
                    Completion Rate
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {summary.overall_completion_rate?.toFixed(1) || 0}%
                  </Typography>
                </Box>
                <VerifiedIcon sx={{ fontSize: 40, color: 'warning.main', opacity: 0.7 }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Chart */}
      <Paper sx={{ p: 3, mb: 3 }}>
        <Typography variant="h6" gutterBottom sx={{ fontWeight: 500 }}>
          Requests by Documentation Type
        </Typography>
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={docTypeData}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="name" angle={-45} textAnchor="end" height={100} />
            <YAxis />
            <Tooltip />
            <Legend />
            <Bar dataKey="requests" fill="#1976d2" name="Number of Requests" />
          </BarChart>
        </ResponsiveContainer>
      </Paper>

      {/* Filters */}
      <Box sx={{ mb: 2, display: 'flex', gap: 2 }}>
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

        <FormControl sx={{ minWidth: 200 }}>
          <InputLabel>Urgency Filter</InputLabel>
          <Select
            value={urgencyFilter}
            label="Urgency Filter"
            onChange={(e) => setUrgencyFilter(e.target.value)}
          >
            <MenuItem value="All">All Urgency Levels</MenuItem>
            <MenuItem value="Urgent">Urgent</MenuItem>
            <MenuItem value="High">High</MenuItem>
            <MenuItem value="Normal">Normal</MenuItem>
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
            '& .completion-high': {
              backgroundColor: '#e8f5e9',
            },
            '& .completion-medium': {
              backgroundColor: '#fff3e0',
            },
            '& .completion-low': {
              backgroundColor: '#ffebee',
            },
            '& .sla-excellent': {
              backgroundColor: '#e8f5e9',
              fontWeight: 600,
            },
            '& .sla-good': {
              backgroundColor: '#e3f2fd',
            },
            '& .sla-needs-improvement': {
              backgroundColor: '#fff3e0',
            },
          }}
        />
      </Paper>
    </Box>
  );
}

export default DocumentationManagement;
