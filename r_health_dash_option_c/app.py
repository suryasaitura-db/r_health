"""
R_Health Option-C Dash Application
Healthcare Analytics Platform with 5 Scenarios
Theme: Purple/Teal with Smooth Animations
"""

import dash
from dash import dcc, html, callback, Input, Output
import plotly.graph_objects as go
import plotly.express as px
import pandas as pd

# Initialize Dash app
app = dash.Dash(
    __name__,
    suppress_callback_exceptions=True,
    title="R_Health Option-C Analytics"
)
server = app.server

# Purple/Teal Color Theme
COLORS = {
    'primary': '#6B46C1',      # Purple
    'secondary': '#14B8A6',    # Teal
    'accent': '#A78BFA',       # Light Purple
    'background': '#F9FAFB',   # Light Gray
    'card': '#FFFFFF',
    'text': '#1F2937',
    'text_light': '#6B7280',
    'success': '#10B981',
    'warning': '#F59E0B',
    'danger': '#EF4444',
    'gradient_start': '#6B46C1',
    'gradient_end': '#14B8A6'
}

# CSS Animations and Styles
app.index_string = '''
<!DOCTYPE html>
<html>
    <head>
        {%metas%}
        <title>{%title%}</title>
        {%favicon%}
        {%css%}
        <style>
            @keyframes fadeIn {
                from { opacity: 0; transform: translateY(20px); }
                to { opacity: 1; transform: translateY(0); }
            }

            @keyframes slideIn {
                from { transform: translateX(-50px); opacity: 0; }
                to { transform: translateX(0); opacity: 1; }
            }

            @keyframes pulse {
                0%, 100% { transform: scale(1); }
                50% { transform: scale(1.05); }
            }

            .fade-in {
                animation: fadeIn 0.6s ease-out;
            }

            .slide-in {
                animation: slideIn 0.5s ease-out;
            }

            .card-hover {
                transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            }

            .card-hover:hover {
                transform: translateY(-4px);
                box-shadow: 0 20px 25px -5px rgba(107, 70, 193, 0.2), 0 10px 10px -5px rgba(107, 70, 193, 0.1);
            }

            .stat-card {
                transition: all 0.3s ease;
            }

            .stat-card:hover {
                transform: scale(1.02);
            }

            .nav-link {
                transition: all 0.2s ease;
                position: relative;
                overflow: hidden;
            }

            .nav-link::before {
                content: '';
                position: absolute;
                bottom: 0;
                left: 0;
                width: 0;
                height: 3px;
                background: linear-gradient(90deg, #6B46C1, #14B8A6);
                transition: width 0.3s ease;
            }

            .nav-link:hover::before {
                width: 100%;
            }

            .gradient-bg {
                background: linear-gradient(135deg, #6B46C1 0%, #14B8A6 100%);
            }

            .chart-container {
                animation: fadeIn 0.8s ease-out;
            }
        </style>
    </head>
    <body>
        {%app_entry%}
        <footer>
            {%config%}
            {%scripts%}
            {%renderer%}
        </footer>
    </body>
</html>
'''

# Sample Data for 5 Scenarios
SAMPLE_CAPACITY_DATA = pd.DataFrame([
    {'department': 'Emergency', 'beds_total': 50, 'beds_occupied': 42, 'utilization': 84},
    {'department': 'ICU', 'beds_total': 30, 'beds_occupied': 28, 'utilization': 93},
    {'department': 'Surgery', 'beds_total': 40, 'beds_occupied': 35, 'utilization': 88},
    {'department': 'Pediatrics', 'beds_total': 35, 'beds_occupied': 25, 'utilization': 71},
    {'department': 'Cardiology', 'beds_total': 25, 'beds_occupied': 20, 'utilization': 80},
])

SAMPLE_DENIALS_DATA = pd.DataFrame([
    {'reason': 'Missing Documentation', 'count': 145, 'amount': 287500},
    {'reason': 'Coding Error', 'count': 98, 'amount': 196000},
    {'reason': 'Authorization Issue', 'count': 76, 'amount': 152000},
    {'reason': 'Medical Necessity', 'count': 54, 'amount': 108000},
    {'reason': 'Duplicate Claim', 'count': 32, 'amount': 64000},
])

SAMPLE_CLINICAL_TRIALS = pd.DataFrame([
    {'trial': 'CARDIO-2024', 'matched_patients': 23, 'enrolled': 18, 'success_rate': 78},
    {'trial': 'ONCO-TRIAL-03', 'matched_patients': 45, 'enrolled': 32, 'success_rate': 71},
    {'trial': 'DIABETES-STUDY', 'matched_patients': 67, 'enrolled': 58, 'success_rate': 87},
    {'trial': 'NEURO-RESEARCH', 'matched_patients': 34, 'enrolled': 28, 'success_rate': 82},
])

SAMPLE_TIMELY_FILING = pd.DataFrame([
    {'payer': 'Medicare', 'total_claims': 1245, 'on_time': 1198, 'late': 47, 'rate': 96.2},
    {'payer': 'Blue Cross', 'total_claims': 987, 'on_time': 945, 'late': 42, 'rate': 95.7},
    {'payer': 'UnitedHealth', 'total_claims': 876, 'on_time': 832, 'late': 44, 'rate': 95.0},
    {'payer': 'Aetna', 'total_claims': 654, 'on_time': 629, 'late': 25, 'rate': 96.2},
])

SAMPLE_DOCUMENTATION = pd.DataFrame([
    {'status': 'Complete', 'count': 2345, 'percentage': 78},
    {'status': 'Pending Review', 'count': 456, 'percentage': 15},
    {'status': 'Incomplete', 'count': 189, 'percentage': 6},
    {'status': 'Query Sent', 'count': 34, 'percentage': 1},
])

# Navigation Bar
def create_navbar():
    return html.Div([
        html.Div([
            html.H1("R_Health Option-C",
                   style={
                       'color': 'white',
                       'margin': '0',
                       'fontSize': '28px',
                       'fontWeight': '700',
                       'letterSpacing': '0.5px'
                   }),
            html.P("Healthcare Analytics Platform",
                  style={'color': 'rgba(255,255,255,0.9)', 'margin': '5px 0 0 0', 'fontSize': '14px'})
        ], style={'flex': '1'}),

        html.Div([
            dcc.Link('Capacity', href='/capacity', className='nav-link',
                    style={'color': 'white', 'textDecoration': 'none', 'padding': '10px 20px',
                          'margin': '0 5px', 'borderRadius': '8px', 'fontSize': '15px'}),
            dcc.Link('Denials', href='/denials', className='nav-link',
                    style={'color': 'white', 'textDecoration': 'none', 'padding': '10px 20px',
                          'margin': '0 5px', 'borderRadius': '8px', 'fontSize': '15px'}),
            dcc.Link('Trials', href='/trials', className='nav-link',
                    style={'color': 'white', 'textDecoration': 'none', 'padding': '10px 20px',
                          'margin': '0 5px', 'borderRadius': '8px', 'fontSize': '15px'}),
            dcc.Link('Filing', href='/filing', className='nav-link',
                    style={'color': 'white', 'textDecoration': 'none', 'padding': '10px 20px',
                          'margin': '0 5px', 'borderRadius': '8px', 'fontSize': '15px'}),
            dcc.Link('Docs', href='/docs', className='nav-link',
                    style={'color': 'white', 'textDecoration': 'none', 'padding': '10px 20px',
                          'margin': '0 5px', 'borderRadius': '8px', 'fontSize': '15px'}),
        ], style={'display': 'flex', 'alignItems': 'center'})
    ], className='gradient-bg', style={
        'padding': '20px 40px',
        'display': 'flex',
        'alignItems': 'center',
        'boxShadow': '0 4px 6px -1px rgba(0, 0, 0, 0.1)',
        'position': 'sticky',
        'top': '0',
        'zIndex': '1000'
    })

# Stat Card Component
def stat_card(title, value, subtitle, color):
    return html.Div([
        html.H3(title, style={'color': COLORS['text_light'], 'fontSize': '14px', 'margin': '0 0 10px 0', 'fontWeight': '500'}),
        html.H2(value, style={'color': color, 'fontSize': '32px', 'margin': '0 0 5px 0', 'fontWeight': '700'}),
        html.P(subtitle, style={'color': COLORS['text_light'], 'fontSize': '13px', 'margin': '0'})
    ], className='stat-card', style={
        'backgroundColor': COLORS['card'],
        'padding': '24px',
        'borderRadius': '12px',
        'boxShadow': '0 1px 3px 0 rgba(0, 0, 0, 0.1)',
        'border': f'1px solid rgba(107, 70, 193, 0.1)'
    })

# Capacity Management Layout
def capacity_layout():
    fig = go.Figure(data=[
        go.Bar(
            x=SAMPLE_CAPACITY_DATA['utilization'],
            y=SAMPLE_CAPACITY_DATA['department'],
            orientation='h',
            marker=dict(
                color=SAMPLE_CAPACITY_DATA['utilization'],
                colorscale=[[0, COLORS['success']], [0.7, COLORS['warning']], [1, COLORS['danger']]],
                showscale=False
            ),
            text=SAMPLE_CAPACITY_DATA['utilization'].apply(lambda x: f'{x}%'),
            textposition='outside'
        )
    ])
    fig.update_layout(
        title='Department Bed Utilization',
        xaxis_title='Utilization (%)',
        template='plotly_white',
        height=400,
        margin=dict(l=20, r=20, t=40, b=20)
    )

    return html.Div([
        html.H2("Capacity Management", className='fade-in',
               style={'color': COLORS['text'], 'marginBottom': '30px', 'fontSize': '28px', 'fontWeight': '700'}),

        html.Div([
            stat_card('Total Beds', '180', '+5% from last month', COLORS['primary']),
            stat_card('Occupied', '150', '83% utilization', COLORS['secondary']),
            stat_card('Available', '30', '17% capacity', COLORS['success']),
            stat_card('Critical Depts', '2', 'Above 90% utilization', COLORS['danger']),
        ], className='slide-in', style={
            'display': 'grid',
            'gridTemplateColumns': 'repeat(4, 1fr)',
            'gap': '20px',
            'marginBottom': '30px'
        }),

        html.Div([
            dcc.Graph(figure=fig, className='chart-container')
        ], className='card-hover', style={
            'backgroundColor': COLORS['card'],
            'padding': '24px',
            'borderRadius': '12px',
            'boxShadow': '0 1px 3px 0 rgba(0, 0, 0, 0.1)'
        })
    ])

# Denials Management Layout
def denials_layout():
    fig = px.pie(
        SAMPLE_DENIALS_DATA,
        values='count',
        names='reason',
        color_discrete_sequence=[COLORS['primary'], COLORS['secondary'], COLORS['accent'],
                                COLORS['warning'], COLORS['danger']]
    )
    fig.update_layout(template='plotly_white', height=400)

    return html.Div([
        html.H2("Denials Management", className='fade-in',
               style={'color': COLORS['text'], 'marginBottom': '30px', 'fontSize': '28px', 'fontWeight': '700'}),

        html.Div([
            stat_card('Total Denials', '405', 'Last 30 days', COLORS['danger']),
            stat_card('Denied Amount', '$807K', 'Pending appeals', COLORS['warning']),
            stat_card('Overturn Rate', '64%', '+8% improvement', COLORS['success']),
            stat_card('Avg Days', '18', 'To resolution', COLORS['primary']),
        ], className='slide-in', style={
            'display': 'grid',
            'gridTemplateColumns': 'repeat(4, 1fr)',
            'gap': '20px',
            'marginBottom': '30px'
        }),

        html.Div([
            dcc.Graph(figure=fig, className='chart-container')
        ], className='card-hover', style={
            'backgroundColor': COLORS['card'],
            'padding': '24px',
            'borderRadius': '12px',
            'boxShadow': '0 1px 3px 0 rgba(0, 0, 0, 0.1)'
        })
    ])

# Clinical Trial Matching Layout
def trials_layout():
    fig = go.Figure(data=[
        go.Bar(name='Matched', x=SAMPLE_CLINICAL_TRIALS['trial'], y=SAMPLE_CLINICAL_TRIALS['matched_patients'],
              marker_color=COLORS['primary']),
        go.Bar(name='Enrolled', x=SAMPLE_CLINICAL_TRIALS['trial'], y=SAMPLE_CLINICAL_TRIALS['enrolled'],
              marker_color=COLORS['secondary'])
    ])
    fig.update_layout(barmode='group', template='plotly_white', height=400,
                     title='Clinical Trial Patient Matching')

    return html.Div([
        html.H2("Clinical Trial Matching", className='fade-in',
               style={'color': COLORS['text'], 'marginBottom': '30px', 'fontSize': '28px', 'fontWeight': '700'}),

        html.Div([
            stat_card('Active Trials', '4', 'Currently recruiting', COLORS['primary']),
            stat_card('Matched Patients', '169', 'Eligible candidates', COLORS['secondary']),
            stat_card('Enrolled', '136', '80% conversion', COLORS['success']),
            stat_card('Success Rate', '80%', 'Above target', COLORS['accent']),
        ], className='slide-in', style={
            'display': 'grid',
            'gridTemplateColumns': 'repeat(4, 1fr)',
            'gap': '20px',
            'marginBottom': '30px'
        }),

        html.Div([
            dcc.Graph(figure=fig, className='chart-container')
        ], className='card-hover', style={
            'backgroundColor': COLORS['card'],
            'padding': '24px',
            'borderRadius': '12px',
            'boxShadow': '0 1px 3px 0 rgba(0, 0, 0, 0.1)'
        })
    ])

# Timely Filing Layout
def filing_layout():
    fig = go.Figure(data=[
        go.Bar(
            x=SAMPLE_TIMELY_FILING['payer'],
            y=SAMPLE_TIMELY_FILING['rate'],
            marker=dict(
                color=SAMPLE_TIMELY_FILING['rate'],
                colorscale=[[0, COLORS['danger']], [0.95, COLORS['warning']], [1, COLORS['success']]],
                showscale=False
            ),
            text=SAMPLE_TIMELY_FILING['rate'].apply(lambda x: f'{x}%'),
            textposition='outside'
        )
    ])
    fig.update_layout(
        title='On-Time Filing Rate by Payer',
        yaxis_title='Rate (%)',
        template='plotly_white',
        height=400
    )

    return html.Div([
        html.H2("Timely Filing & Appeals", className='fade-in',
               style={'color': COLORS['text'], 'marginBottom': '30px', 'fontSize': '28px', 'fontWeight': '700'}),

        html.Div([
            stat_card('Total Claims', '3,762', 'Last 30 days', COLORS['primary']),
            stat_card('On-Time', '3,604', '95.8% success rate', COLORS['success']),
            stat_card('Late Filings', '158', '4.2% of total', COLORS['warning']),
            stat_card('Avg Processing', '12 days', '-2 days vs target', COLORS['secondary']),
        ], className='slide-in', style={
            'display': 'grid',
            'gridTemplateColumns': 'repeat(4, 1fr)',
            'gap': '20px',
            'marginBottom': '30px'
        }),

        html.Div([
            dcc.Graph(figure=fig, className='chart-container')
        ], className='card-hover', style={
            'backgroundColor': COLORS['card'],
            'padding': '24px',
            'borderRadius': '12px',
            'boxShadow': '0 1px 3px 0 rgba(0, 0, 0, 0.1)'
        })
    ])

# Documentation Management Layout
def docs_layout():
    fig = go.Figure(data=[
        go.Pie(
            labels=SAMPLE_DOCUMENTATION['status'],
            values=SAMPLE_DOCUMENTATION['count'],
            marker=dict(colors=[COLORS['success'], COLORS['warning'], COLORS['danger'], COLORS['primary']]),
            hole=0.4
        )
    ])
    fig.update_layout(template='plotly_white', height=400, title='Documentation Status Distribution')

    return html.Div([
        html.H2("Documentation Management", className='fade-in',
               style={'color': COLORS['text'], 'marginBottom': '30px', 'fontSize': '28px', 'fontWeight': '700'}),

        html.Div([
            stat_card('Total Records', '3,024', 'Active documents', COLORS['primary']),
            stat_card('Complete', '2,345', '78% completion rate', COLORS['success']),
            stat_card('Pending', '456', 'In review queue', COLORS['warning']),
            stat_card('Queries', '34', 'Awaiting response', COLORS['secondary']),
        ], className='slide-in', style={
            'display': 'grid',
            'gridTemplateColumns': 'repeat(4, 1fr)',
            'gap': '20px',
            'marginBottom': '30px'
        }),

        html.Div([
            dcc.Graph(figure=fig, className='chart-container')
        ], className='card-hover', style={
            'backgroundColor': COLORS['card'],
            'padding': '24px',
            'borderRadius': '12px',
            'boxShadow': '0 1px 3px 0 rgba(0, 0, 0, 0.1)'
        })
    ])

# Home Layout
def home_layout():
    return html.Div([
        html.Div([
            html.H1("Welcome to R_Health Option-C", className='fade-in',
                   style={'color': COLORS['text'], 'fontSize': '42px', 'fontWeight': '700', 'marginBottom': '20px'}),
            html.P("Advanced Healthcare Analytics Platform with Real-Time Insights", className='slide-in',
                  style={'color': COLORS['text_light'], 'fontSize': '18px', 'marginBottom': '40px'})
        ], style={'textAlign': 'center', 'padding': '60px 0 40px 0'}),

        html.Div([
            html.Div([
                html.Div([
                    html.H3("🏥 Capacity Management", style={'color': COLORS['primary'], 'marginBottom': '15px'}),
                    html.P("Monitor bed utilization and optimize resource allocation across departments",
                          style={'color': COLORS['text_light'], 'lineHeight': '1.6'})
                ], className='card-hover', style={
                    'backgroundColor': COLORS['card'],
                    'padding': '30px',
                    'borderRadius': '12px',
                    'boxShadow': '0 1px 3px 0 rgba(0, 0, 0, 0.1)',
                    'border': f'2px solid {COLORS["primary"]}'
                }),
            ], style={'marginBottom': '20px'}),

            html.Div([
                html.Div([
                    html.H3("💰 Denials Management", style={'color': COLORS['secondary'], 'marginBottom': '15px'}),
                    html.P("Track claim denials, analyze root causes, and improve overturn rates",
                          style={'color': COLORS['text_light'], 'lineHeight': '1.6'})
                ], className='card-hover', style={
                    'backgroundColor': COLORS['card'],
                    'padding': '30px',
                    'borderRadius': '12px',
                    'boxShadow': '0 1px 3px 0 rgba(0, 0, 0, 0.1)',
                    'border': f'2px solid {COLORS["secondary"]}'
                }),
            ], style={'marginBottom': '20px'}),

            html.Div([
                html.Div([
                    html.H3("🔬 Clinical Trial Matching", style={'color': COLORS['accent'], 'marginBottom': '15px'}),
                    html.P("Match eligible patients with clinical trials and track enrollment success",
                          style={'color': COLORS['text_light'], 'lineHeight': '1.6'})
                ], className='card-hover', style={
                    'backgroundColor': COLORS['card'],
                    'padding': '30px',
                    'borderRadius': '12px',
                    'boxShadow': '0 1px 3px 0 rgba(0, 0, 0, 0.1)',
                    'border': f'2px solid {COLORS["accent"]}'
                }),
            ], style={'marginBottom': '20px'}),

            html.Div([
                html.Div([
                    html.H3("⏰ Timely Filing & Appeals", style={'color': COLORS['warning'], 'marginBottom': '15px'}),
                    html.P("Ensure claims are filed within deadlines and monitor appeal processes",
                          style={'color': COLORS['text_light'], 'lineHeight': '1.6'})
                ], className='card-hover', style={
                    'backgroundColor': COLORS['card'],
                    'padding': '30px',
                    'borderRadius': '12px',
                    'boxShadow': '0 1px 3px 0 rgba(0, 0, 0, 0.1)',
                    'border': f'2px solid {COLORS["warning"]}'
                }),
            ], style={'marginBottom': '20px'}),

            html.Div([
                html.Div([
                    html.H3("📄 Documentation Management", style={'color': COLORS['success'], 'marginBottom': '15px'}),
                    html.P("Track documentation completeness and manage clinical queries efficiently",
                          style={'color': COLORS['text_light'], 'lineHeight': '1.6'})
                ], className='card-hover', style={
                    'backgroundColor': COLORS['card'],
                    'padding': '30px',
                    'borderRadius': '12px',
                    'boxShadow': '0 1px 3px 0 rgba(0, 0, 0, 0.1)',
                    'border': f'2px solid {COLORS["success"]}'
                }),
            ]),
        ], className='slide-in', style={
            'maxWidth': '900px',
            'margin': '0 auto',
            'padding': '0 20px'
        })
    ])

# Main App Layout
app.layout = html.Div([
    dcc.Location(id='url', refresh=False),
    create_navbar(),
    html.Div(id='page-content', style={
        'backgroundColor': COLORS['background'],
        'minHeight': 'calc(100vh - 80px)',
        'padding': '40px'
    })
])

# Callback for page navigation
@callback(Output('page-content', 'children'), Input('url', 'pathname'))
def display_page(pathname):
    if pathname == '/capacity':
        return capacity_layout()
    elif pathname == '/denials':
        return denials_layout()
    elif pathname == '/trials':
        return trials_layout()
    elif pathname == '/filing':
        return filing_layout()
    elif pathname == '/docs':
        return docs_layout()
    else:
        return home_layout()

if __name__ == '__main__':
    app.run_server(debug=True, host='0.0.0.0', port=8000)
