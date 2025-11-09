"""
R_Health Dash Application - Healthcare Analytics Platform
Multi-page Dash app with 5 healthcare analytics scenarios
"""
import dash
from dash import dcc, html, Input, Output, callback
import plotly.express as px
import plotly.graph_objects as go
import pandas as pd
from dash import dash_table
import os

# Initialize Dash app
app = dash.Dash(
    __name__,
    suppress_callback_exceptions=True,
    title="R_Health Healthcare Analytics"
)
server = app.server

# Sample data for demonstration
SAMPLE_CAPACITY_DATA = pd.DataFrame([
    {"drg_code": "470", "drg_description": "Major Joint Replacement", "total_encounters": 1250,
     "total_bed_days": 3750, "avg_los": 3.0, "estimated_cost_opportunity": 125000,
     "optimization_priority": "Critical - High Volume"},
    {"drg_code": "871", "drg_description": "Septicemia", "total_encounters": 980,
     "total_bed_days": 5880, "avg_los": 6.0, "estimated_cost_opportunity": 245000,
     "optimization_priority": "High - Extended LOS"},
    {"drg_code": "291", "drg_description": "Heart Failure", "total_encounters": 850,
     "total_bed_days": 3400, "avg_los": 4.0, "estimated_cost_opportunity": 85000,
     "optimization_priority": "Medium - Standard"},
    {"drg_code": "690", "drg_description": "Kidney/UTI", "total_encounters": 720,
     "total_bed_days": 2160, "avg_los": 3.0, "estimated_cost_opportunity": 54000,
     "optimization_priority": "Medium - Standard"}
])

SAMPLE_DENIALS_DATA = pd.DataFrame([
    {"payer_name": "Medicare", "denial_category": "Medical Necessity",
     "total_denials": 145, "total_appealed": 98, "total_denied_amount": 582000,
     "recovered_amount": 349200, "appeal_win_rate": 60.0},
    {"payer_name": "Aetna", "denial_category": "Authorization",
     "total_denials": 89, "total_appealed": 67, "total_denied_amount": 312000,
     "recovered_amount": 187200, "appeal_win_rate": 55.0},
    {"payer_name": "Blue Cross", "denial_category": "Coding Error",
     "total_denials": 76, "total_appealed": 58, "total_denied_amount": 245000,
     "recovered_amount": 171500, "appeal_win_rate": 70.0}
])

# Layout
app.layout = html.Div([
    dcc.Location(id='url', refresh=False),

    # Header
    html.Div([
        html.H1("R_Health Healthcare Analytics Platform",
                style={'color': 'white', 'margin': '0'}),
        html.P("Renown Health RFP Demo - 5 Healthcare Analytics Scenarios",
               style={'color': '#e0e0e0', 'margin': '5px 0 0 0'})
    ], style={
        'backgroundColor': '#1976d2',
        'padding': '20px',
        'marginBottom': '0'
    }),

    # Navigation
    html.Div([
        dcc.Link('Home', href='/', className='nav-link',
                style={'padding': '10px 20px', 'color': 'white', 'textDecoration': 'none',
                       'display': 'inline-block', 'backgroundColor': '#1565c0'}),
        dcc.Link('Capacity Management', href='/capacity', className='nav-link',
                style={'padding': '10px 20px', 'color': 'white', 'textDecoration': 'none',
                       'display': 'inline-block', 'marginLeft': '10px', 'backgroundColor': '#1565c0'}),
        dcc.Link('Denials Management', href='/denials', className='nav-link',
                style={'padding': '10px 20px', 'color': 'white', 'textDecoration': 'none',
                       'display': 'inline-block', 'marginLeft': '10px', 'backgroundColor': '#1565c0'}),
        dcc.Link('Clinical Trials', href='/trials', className='nav-link',
                style={'padding': '10px 20px', 'color': 'white', 'textDecoration': 'none',
                       'display': 'inline-block', 'marginLeft': '10px', 'backgroundColor': '#1565c0'}),
        dcc.Link('Timely Filing', href='/filing', className='nav-link',
                style={'padding': '10px 20px', 'color': 'white', 'textDecoration': 'none',
                       'display': 'inline-block', 'marginLeft': '10px', 'backgroundColor': '#1565c0'}),
        dcc.Link('Documentation', href='/documentation', className='nav-link',
                style={'padding': '10px 20px', 'color': 'white', 'textDecoration': 'none',
                       'display': 'inline-block', 'marginLeft': '10px', 'backgroundColor': '#1565c0'}),
    ], style={'backgroundColor': '#0d47a1', 'padding': '0', 'marginBottom': '20px'}),

    # Page content
    html.Div(id='page-content', style={'padding': '20px'})
])

# Home page
def home_layout():
    return html.Div([
        html.H2("Welcome to R_Health Analytics Platform"),
        html.P("This platform provides comprehensive healthcare analytics across 5 key scenarios:"),

        html.Div([
            html.Div([
                html.H3("1. Capacity Management"),
                html.P("Hospital capacity optimization and length of stay analysis"),
                html.P("💰 Value: $370K+ cost opportunity identified")
            ], style={'backgroundColor': '#e3f2fd', 'padding': '20px', 'margin': '10px',
                     'borderRadius': '5px', 'flex': '1'}),

            html.Div([
                html.H3("2. Denials Management"),
                html.P("Claims denial tracking and appeal optimization"),
                html.P("💰 Value: $700K+ in potential recoveries")
            ], style={'backgroundColor': '#f3e5f5', 'padding': '20px', 'margin': '10px',
                     'borderRadius': '5px', 'flex': '1'}),
        ], style={'display': 'flex'}),

        html.Div([
            html.Div([
                html.H3("3. Clinical Trial Matching"),
                html.P("Patient-to-clinical trial matching and enrollment"),
                html.P("💰 Value: $2.1M+ in research revenue")
            ], style={'backgroundColor': '#e8f5e9', 'padding': '20px', 'margin': '10px',
                     'borderRadius': '5px', 'flex': '1'}),

            html.Div([
                html.H3("4. Timely Filing & Appeals"),
                html.P("Filing deadline tracking and compliance monitoring"),
                html.P("💰 Value: $1.8M+ at-risk revenue protected")
            ], style={'backgroundColor': '#fff3e0', 'padding': '20px', 'margin': '10px',
                     'borderRadius': '5px', 'flex': '1'}),
        ], style={'display': 'flex'}),

        html.Div([
            html.Div([
                html.H3("5. Documentation Management"),
                html.P("Chart completion and documentation request tracking"),
                html.P("💰 Value: $400K+ in documentation completions")
            ], style={'backgroundColor': '#fce4ec', 'padding': '20px', 'margin': '10px',
                     'borderRadius': '5px', 'flex': '1'}),
        ]),

        html.Hr(),
        html.H3("📊 Total Business Value: $5.3M+", style={'color': '#1976d2'}),
        html.P("Data Source: Unity Catalog (hls_amer_catalog) - 15,000 synthetic patients, 50,000+ encounters"),
    ])

# Capacity Management page
def capacity_layout():
    fig_encounters = px.bar(SAMPLE_CAPACITY_DATA, x='drg_description', y='total_encounters',
                            title='Total Encounters by DRG',
                            color='optimization_priority',
                            color_discrete_map={
                                'Critical - High Volume': '#d32f2f',
                                'High - Extended LOS': '#f57c00',
                                'Medium - Standard': '#fbc02d'
                            })
    fig_encounters.update_layout(height=400)

    fig_cost = px.bar(SAMPLE_CAPACITY_DATA, x='drg_description', y='estimated_cost_opportunity',
                      title='Cost Optimization Opportunity by DRG',
                      color='optimization_priority',
                      color_discrete_map={
                          'Critical - High Volume': '#d32f2f',
                          'High - Extended LOS': '#f57c00',
                          'Medium - Standard': '#fbc02d'
                      })
    fig_cost.update_layout(height=400)

    return html.Div([
        html.H2("Capacity Management Dashboard"),

        # KPIs
        html.Div([
            html.Div([
                html.H3(f"{len(SAMPLE_CAPACITY_DATA)}", style={'color': '#1976d2', 'margin': '0'}),
                html.P("Total DRGs", style={'margin': '5px 0'})
            ], style={'backgroundColor': '#e3f2fd', 'padding': '20px', 'margin': '10px',
                     'borderRadius': '5px', 'flex': '1', 'textAlign': 'center'}),

            html.Div([
                html.H3(f"{SAMPLE_CAPACITY_DATA['total_encounters'].sum():,}",
                       style={'color': '#1976d2', 'margin': '0'}),
                html.P("Total Encounters", style={'margin': '5px 0'})
            ], style={'backgroundColor': '#e3f2fd', 'padding': '20px', 'margin': '10px',
                     'borderRadius': '5px', 'flex': '1', 'textAlign': 'center'}),

            html.Div([
                html.H3(f"${SAMPLE_CAPACITY_DATA['estimated_cost_opportunity'].sum():,.0f}",
                       style={'color': '#d32f2f', 'margin': '0'}),
                html.P("Cost Opportunity", style={'margin': '5px 0'})
            ], style={'backgroundColor': '#ffebee', 'padding': '20px', 'margin': '10px',
                     'borderRadius': '5px', 'flex': '1', 'textAlign': 'center'}),

            html.Div([
                html.H3(f"{SAMPLE_CAPACITY_DATA['avg_los'].mean():.1f} days",
                       style={'color': '#1976d2', 'margin': '0'}),
                html.P("Avg Length of Stay", style={'margin': '5px 0'})
            ], style={'backgroundColor': '#e3f2fd', 'padding': '20px', 'margin': '10px',
                     'borderRadius': '5px', 'flex': '1', 'textAlign': 'center'}),
        ], style={'display': 'flex'}),

        # Charts
        dcc.Graph(figure=fig_encounters),
        dcc.Graph(figure=fig_cost),

        # Data Table
        html.H3("Detailed Data"),
        dash_table.DataTable(
            data=SAMPLE_CAPACITY_DATA.to_dict('records'),
            columns=[{"name": i, "id": i} for i in SAMPLE_CAPACITY_DATA.columns],
            style_table={'overflowX': 'auto'},
            style_cell={'textAlign': 'left', 'padding': '10px'},
            style_header={'backgroundColor': '#1976d2', 'color': 'white', 'fontWeight': 'bold'},
            style_data_conditional=[
                {
                    'if': {'row_index': 'odd'},
                    'backgroundColor': '#f5f5f5'
                }
            ]
        )
    ])

# Denials Management page
def denials_layout():
    fig_denials = px.bar(SAMPLE_DENIALS_DATA, x='payer_name', y='total_denied_amount',
                         title='Total Denied Amount by Payer',
                         color='payer_name')
    fig_denials.update_layout(height=400)

    fig_win_rate = px.bar(SAMPLE_DENIALS_DATA, x='payer_name', y='appeal_win_rate',
                          title='Appeal Win Rate by Payer (%)',
                          color='payer_name')
    fig_win_rate.update_layout(height=400, yaxis_title="Win Rate (%)")

    return html.Div([
        html.H2("Denials Management Dashboard"),

        # KPIs
        html.Div([
            html.Div([
                html.H3(f"{SAMPLE_DENIALS_DATA['total_denials'].sum()}",
                       style={'color': '#d32f2f', 'margin': '0'}),
                html.P("Total Denials", style={'margin': '5px 0'})
            ], style={'backgroundColor': '#ffebee', 'padding': '20px', 'margin': '10px',
                     'borderRadius': '5px', 'flex': '1', 'textAlign': 'center'}),

            html.Div([
                html.H3(f"${SAMPLE_DENIALS_DATA['total_denied_amount'].sum():,.0f}",
                       style={'color': '#d32f2f', 'margin': '0'}),
                html.P("Denied Amount", style={'margin': '5px 0'})
            ], style={'backgroundColor': '#ffebee', 'padding': '20px', 'margin': '10px',
                     'borderRadius': '5px', 'flex': '1', 'textAlign': 'center'}),

            html.Div([
                html.H3(f"${SAMPLE_DENIALS_DATA['recovered_amount'].sum():,.0f}",
                       style={'color': '#2e7d32', 'margin': '0'}),
                html.P("Recovered Amount", style={'margin': '5px 0'})
            ], style={'backgroundColor': '#e8f5e9', 'padding': '20px', 'margin': '10px',
                     'borderRadius': '5px', 'flex': '1', 'textAlign': 'center'}),

            html.Div([
                html.H3(f"{SAMPLE_DENIALS_DATA['appeal_win_rate'].mean():.1f}%",
                       style={'color': '#1976d2', 'margin': '0'}),
                html.P("Avg Win Rate", style={'margin': '5px 0'})
            ], style={'backgroundColor': '#e3f2fd', 'padding': '20px', 'margin': '10px',
                     'borderRadius': '5px', 'flex': '1', 'textAlign': 'center'}),
        ], style={'display': 'flex'}),

        # Charts
        dcc.Graph(figure=fig_denials),
        dcc.Graph(figure=fig_win_rate),

        # Data Table
        html.H3("Detailed Data"),
        dash_table.DataTable(
            data=SAMPLE_DENIALS_DATA.to_dict('records'),
            columns=[{"name": i, "id": i} for i in SAMPLE_DENIALS_DATA.columns],
            style_table={'overflowX': 'auto'},
            style_cell={'textAlign': 'left', 'padding': '10px'},
            style_header={'backgroundColor': '#1976d2', 'color': 'white', 'fontWeight': 'bold'},
            style_data_conditional=[
                {
                    'if': {'row_index': 'odd'},
                    'backgroundColor': '#f5f5f5'
                }
            ]
        )
    ])

# Simple placeholders for other pages
def trials_layout():
    return html.Div([
        html.H2("Clinical Trial Matching"),
        html.P("Patient-to-clinical trial matching dashboard"),
        html.P("💰 Total Value: $2.1M+ in research revenue potential"),
        html.P("Sample data will be replaced with Unity Catalog queries")
    ])

def filing_layout():
    return html.Div([
        html.H2("Timely Filing & Appeals"),
        html.P("Filing deadline tracking and compliance dashboard"),
        html.P("💰 Total Value: $1.8M+ at-risk revenue protected"),
        html.P("Sample data will be replaced with Unity Catalog queries")
    ])

def documentation_layout():
    return html.Div([
        html.H2("Documentation Management"),
        html.P("Chart completion and documentation request tracking"),
        html.P("💰 Total Value: $400K+ in documentation completions"),
        html.P("Sample data will be replaced with Unity Catalog queries")
    ])

# Callback to update page content
@callback(Output('page-content', 'children'),
          Input('url', 'pathname'))
def display_page(pathname):
    if pathname == '/capacity':
        return capacity_layout()
    elif pathname == '/denials':
        return denials_layout()
    elif pathname == '/trials':
        return trials_layout()
    elif pathname == '/filing':
        return filing_layout()
    elif pathname == '/documentation':
        return documentation_layout()
    else:
        return home_layout()

if __name__ == '__main__':
    port = int(os.getenv('PORT', 8000))
    app.run_server(debug=False, host='0.0.0.0', port=port)
