import axios from 'axios';

// Create axios instance with base URL
const api = axios.create({
  baseURL: 'http://localhost:8000',
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor for error handling
api.interceptors.response.use(
  (response) => response,
  (error) => {
    console.error('API Error:', error);
    return Promise.reject(error);
  }
);

// ==============================================================================
// CAPACITY MANAGEMENT
// ==============================================================================

export const getCapacityManagement = async (params = {}) => {
  try {
    const response = await api.get('/api/capacity-management', { params });
    return response.data;
  } catch (error) {
    throw error;
  }
};

export const getCapacitySummary = async () => {
  try {
    const response = await api.get('/api/capacity-management/summary');
    return response.data;
  } catch (error) {
    throw error;
  }
};

// ==============================================================================
// DENIALS MANAGEMENT
// ==============================================================================

export const getDenialsManagement = async (params = {}) => {
  try {
    const response = await api.get('/api/denials-management', { params });
    return response.data;
  } catch (error) {
    throw error;
  }
};

export const getDenialsSummary = async () => {
  try {
    const response = await api.get('/api/denials-management/summary');
    return response.data;
  } catch (error) {
    throw error;
  }
};

// ==============================================================================
// CLINICAL TRIAL MATCHING
// ==============================================================================

export const getClinicalTrialMatching = async (params = {}) => {
  try {
    const response = await api.get('/api/clinical-trial-matching', { params });
    return response.data;
  } catch (error) {
    throw error;
  }
};

export const getClinicalTrialSummary = async () => {
  try {
    const response = await api.get('/api/clinical-trial-matching/summary');
    return response.data;
  } catch (error) {
    throw error;
  }
};

// ==============================================================================
// TIMELY FILING & APPEALS
// ==============================================================================

export const getTimelyFilingAppeals = async (params = {}) => {
  try {
    const response = await api.get('/api/timely-filing-appeals', { params });
    return response.data;
  } catch (error) {
    throw error;
  }
};

export const getTimelyFilingSummary = async () => {
  try {
    const response = await api.get('/api/timely-filing-appeals/summary');
    return response.data;
  } catch (error) {
    throw error;
  }
};

// ==============================================================================
// DOCUMENTATION MANAGEMENT
// ==============================================================================

export const getDocumentationManagement = async (params = {}) => {
  try {
    const response = await api.get('/api/documentation-management', { params });
    return response.data;
  } catch (error) {
    throw error;
  }
};

export const getDocumentationSummary = async () => {
  try {
    const response = await api.get('/api/documentation-management/summary');
    return response.data;
  } catch (error) {
    throw error;
  }
};

// ==============================================================================
// UTILITY ENDPOINTS
// ==============================================================================

export const getPayers = async () => {
  try {
    const response = await api.get('/api/payers');
    return response.data;
  } catch (error) {
    throw error;
  }
};

export const getDrgCodes = async () => {
  try {
    const response = await api.get('/api/drg-codes');
    return response.data;
  } catch (error) {
    throw error;
  }
};

export const getHealthCheck = async () => {
  try {
    const response = await api.get('/health');
    return response.data;
  } catch (error) {
    throw error;
  }
};

export default api;
