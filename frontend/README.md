# R_Health Frontend - Healthcare Analytics Dashboard

A modern React 18 + Material-UI frontend for the R_Health healthcare analytics platform, built for the Renown Health RFP demo.

## Technology Stack

- **React 18.2** - Modern React with hooks and latest features
- **Material-UI (MUI) 5.15** - Professional UI component library
- **MUI X Data Grid 6.18** - Advanced data tables with sorting, filtering, and pagination
- **Recharts 2.10** - Beautiful, responsive data visualizations
- **React Router 6.21** - Client-side routing
- **Axios 1.6** - HTTP client for API calls
- **Vite 5.0** - Lightning-fast build tool and dev server

## Project Structure

```
frontend/
├── index.html                          # HTML entry point
├── vite.config.js                      # Vite configuration with proxy
├── package.json                        # Dependencies and scripts
├── .gitignore                          # Git ignore rules
├── src/
│   ├── main.jsx                        # React 18 entry point
│   ├── index.css                       # Global styles
│   ├── App.jsx                         # Main app with routing & theme
│   ├── services/
│   │   └── api.js                      # API service layer (14 endpoints)
│   └── pages/
│       ├── Home.jsx                    # Dashboard/landing page
│       ├── CapacityManagement.jsx      # Scenario 1: Bed utilization & LOS
│       ├── DenialsManagement.jsx       # Scenario 2: Appeals & recovery
│       ├── ClinicalTrials.jsx          # Scenario 3: Trial matching
│       ├── TimelyFiling.jsx            # Scenario 4: Filing compliance
│       └── DocumentationManagement.jsx # Scenario 5: Doc tracking
```

## Features

### Core Features
- **Responsive Design** - Works on desktop, tablet, and mobile
- **Professional UI** - Healthcare-themed color scheme (blues/greens)
- **Real-time Data** - Fetches live data from FastAPI backend
- **Interactive Charts** - Bar charts, pie charts, and line charts
- **Advanced Tables** - Sortable, filterable data grids with pagination
- **Error Handling** - Graceful error messages and loading states

### Five Scenario Pages

#### 1. Capacity Management (`/capacity-management`)
- **Summary Cards**: Total DRGs, encounters, cost opportunity, critical priority count
- **Bar Chart**: Top 10 DRGs by cost opportunity
- **Data Grid**: All capacity data with LOS variance highlighting
- **Filters**: Priority level (Critical, High, Low)

#### 2. Denials Management (`/denials-management`)
- **Summary Cards**: Total denials, appealed, recovered amount, avg win rate
- **Pie Chart**: Denials distribution by category
- **Data Grid**: Denials with win rate color coding
- **Filters**: Payer selection

#### 3. Clinical Trial Matching (`/clinical-trials`)
- **Summary Cards**: Total patients, KRAS/COPD/PD-L1 eligible counts
- **Bar Chart**: Eligible patients by trial type
- **Data Grid**: Patient eligibility matrix with checkmarks
- **Filters**: Trial type, show eligible only toggle

#### 4. Timely Filing & Appeals (`/timely-filing`)
- **Summary Cards**: Total claims, at-risk claims, critical urgency, at-risk amount
- **Line Chart**: Claims distribution by urgency level
- **Data Grid**: Claims with urgency color coding and deadline highlighting
- **Filters**: Urgency level (Critical, High, Medium, Low)

#### 5. Documentation Management (`/documentation-management`)
- **Summary Cards**: Total requests, completed, avg turnaround, completion rate
- **Bar Chart**: Requests by documentation type
- **Data Grid**: Documentation with SLA compliance color coding
- **Filters**: Payer and urgency level

## Setup Instructions

### Prerequisites
- Node.js 18+ and npm
- FastAPI backend running on http://localhost:8000

### Installation

1. **Navigate to frontend directory:**
   ```bash
   cd frontend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Verify backend is running:**
   ```bash
   curl http://localhost:8000/health
   ```

### Development

**Start development server:**
```bash
npm run dev
```

The application will be available at **http://localhost:3000**

**Features of dev server:**
- Hot Module Replacement (HMR)
- Automatic proxy to backend at http://localhost:8000
- Source maps for debugging
- Fast refresh on file changes

### Production Build

**Build for production:**
```bash
npm run build
```

**Preview production build:**
```bash
npm run preview
```

Production files will be in the `dist/` directory.

## API Integration

The frontend connects to 14 backend endpoints across 5 scenarios:

### Capacity Management
- `GET /api/capacity-management` - Get capacity data
- `GET /api/capacity-management/summary` - Get summary statistics

### Denials Management
- `GET /api/denials-management` - Get denials data
- `GET /api/denials-management/summary` - Get summary statistics

### Clinical Trial Matching
- `GET /api/clinical-trial-matching` - Get trial matching data
- `GET /api/clinical-trial-matching/summary` - Get summary statistics

### Timely Filing & Appeals
- `GET /api/timely-filing-appeals` - Get filing data
- `GET /api/timely-filing-appeals/summary` - Get summary statistics

### Documentation Management
- `GET /api/documentation-management` - Get documentation data
- `GET /api/documentation-management/summary` - Get summary statistics

### Utility Endpoints
- `GET /api/payers` - Get list of all payers
- `GET /api/drg-codes` - Get list of all DRG codes
- `GET /health` - Health check

All API calls are handled through the centralized `src/services/api.js` module with proper error handling.

## Color Scheme

The application uses a professional healthcare color palette:

- **Primary**: Blue (#1976d2) - Trust, professionalism
- **Secondary**: Green (#2e7d32) - Health, growth
- **Error**: Red (#d32f2f) - Urgent, critical
- **Warning**: Orange (#ed6c02) - High priority
- **Info**: Light Blue (#0288d1) - Information
- **Success**: Green (#2e7d32) - Positive outcomes

## Browser Support

- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

## Troubleshooting

### Backend Connection Issues
If you see "Failed to load data" errors:
1. Ensure backend is running: `curl http://localhost:8000/health`
2. Check Vite proxy configuration in `vite.config.js`
3. Verify CORS settings in FastAPI backend

### Dependencies Issues
If npm install fails:
```bash
rm -rf node_modules package-lock.json
npm install
```

### Port Already in Use
If port 3000 is taken:
```bash
# Edit vite.config.js and change port number
server: {
  port: 3001  // or any other port
}
```

## Performance Optimizations

- **Code Splitting** - React Router lazy loading (can be added)
- **Memoization** - React.memo and useMemo where appropriate
- **Virtual Scrolling** - MUI DataGrid handles large datasets efficiently
- **Debouncing** - Filter inputs debounced to reduce API calls
- **Caching** - Axios response caching (can be configured)

## Future Enhancements

- [ ] User authentication and role-based access
- [ ] Real-time data updates with WebSockets
- [ ] Export data to CSV/Excel
- [ ] Advanced filtering and search
- [ ] Dark mode toggle
- [ ] Custom dashboard builder
- [ ] Email notifications and alerts
- [ ] Mobile app version

## Contributing

This is a demo application for the Renown Health RFP. For questions or issues, contact the development team.

## License

Proprietary - Renown Health RFP Demo © 2024
