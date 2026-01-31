import streamlit as st
import pandas as pd
import snowflake.connector

# -------------------------------
# CONFIG STREAMLIT
# -------------------------------
st.set_page_config(
    page_title="Marketing ROI Dashboard",
    layout="wide"
)

st.title("📣 Marketing ROI Dashboard")
st.caption("Pilotage simple et actionnable de la performance marketing")

# -------------------------------
# CONNEXION SNOWFLAKE
# -------------------------------
def get_connection():
    return snowflake.connector.connect(
        user="TEAMSNOWFLAKE",
        password="jebxusbabgap5nicgA",
        account="hi80903.eu-west-3.aws",
        warehouse="COMPUTE_WH",
        database="ANYCOMPANY_LAB",
        schema="SILVER"
    )

@st.cache_data
def load_data():
    query = """
        SELECT
            campaign_id,
            campaign_name,
            campaign_type,
            region,
            start_date,
            budget,
            reach,
            conversion_rate
        FROM ANYCOMPANY_LAB.SILVER.MARKETING_CAMPAIGNS_CLEAN
        WHERE budget IS NOT NULL
    """
    conn = get_connection()
    df = pd.read_sql(query, conn)
    conn.close()

    df["START_DATE"] = pd.to_datetime(df["START_DATE"])
    return df

df = load_data()

# -------------------------------
# FILTRES
# -------------------------------
st.sidebar.header("🔎 Filtres")

years = sorted(df["START_DATE"].dt.year.unique(), reverse=True)
selected_year = st.sidebar.selectbox("Année", years)

regions = sorted(df["REGION"].dropna().unique())
selected_regions = st.sidebar.multiselect(
    "Régions",
    regions,
    default=regions
)

df_filtered = df[
    (df["START_DATE"].dt.year == selected_year) &
    (df["REGION"].isin(selected_regions))
]

# -------------------------------
# KPIs MARKETING
# -------------------------------
total_budget = df_filtered["BUDGET"].sum()
avg_conversion = df_filtered["CONVERSION_RATE"].mean()
total_reach = df_filtered["REACH"].sum()

col1, col2, col3 = st.columns(3)

col1.metric("💰 Budget marketing total", f"{total_budget:,.0f} €")
col2.metric("🎯 Reach total", f"{total_reach:,.0f}")
col3.metric("📈 Taux de conversion moyen", f"{avg_conversion:.2%}")

st.divider()

# -------------------------------
# PERFORMANCE DES CAMPAGNES
# -------------------------------
st.subheader("🏆 Campagnes les plus performantes")

campaign_perf = (
    df_filtered
    .groupby("CAMPAIGN_NAME")[["BUDGET", "REACH", "CONVERSION_RATE"]]
    .mean()
    .sort_values("CONVERSION_RATE", ascending=False)
)

st.dataframe(
    campaign_perf,
    use_container_width=True
)

st.divider()

# -------------------------------
# BUDGET PAR RÉGION
# -------------------------------
st.subheader("🌍 Répartition du budget par région")

budget_by_region = (
    df_filtered
    .groupby("REGION")["BUDGET"]
    .sum()
    .sort_values(ascending=False)
)

st.bar_chart(budget_by_region)