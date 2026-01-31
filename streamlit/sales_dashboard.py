import streamlit as st
import pandas as pd
import snowflake.connector

# -------------------------------
# CONFIG STREAMLIT
# -------------------------------
st.set_page_config(
    page_title="Sales Dashboard",
    layout="wide"
)

st.title("📊 Sales Dashboard")
st.caption("Vue simple et actionnable des ventes")

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
            transaction_date,
            region,
            amount
        FROM ANYCOMPANY_LAB.SILVER.FINANCIAL_TRANSACTIONS_CLEAN
    """
    conn = get_connection()
    df = pd.read_sql(query, conn)
    conn.close()

    # Normalisation propre
    df.columns = df.columns.str.upper()
    df["TRANSACTION_DATE"] = pd.to_datetime(df["TRANSACTION_DATE"])

    return df

df = load_data()

# -------------------------------
# FILTRES
# -------------------------------
st.sidebar.header("🔎 Filtres")

years = sorted(df["TRANSACTION_DATE"].dt.year.unique(), reverse=True)
selected_year = st.sidebar.selectbox("Année", years)

regions = sorted(df["REGION"].dropna().unique())
selected_regions = st.sidebar.multiselect(
    "Régions",
    regions,
    default=regions
)

df_filtered = df[
    (df["TRANSACTION_DATE"].dt.year == selected_year) &
    (df["REGION"].isin(selected_regions))
]

# -------------------------------
# KPIs
# -------------------------------
total_sales = df_filtered["AMOUNT"].sum()
nb_transactions = len(df_filtered)
avg_basket = df_filtered["AMOUNT"].mean()

col1, col2, col3 = st.columns(3)

col1.metric("💰 Ventes totales", f"{total_sales:,.0f} €")
col2.metric("🧾 Nombre de transactions", f"{nb_transactions:,}")
col3.metric("🛒 Panier moyen", f"{avg_basket:,.0f} €")

st.divider()

# -------------------------------
# ÉVOLUTION MENSUELLE DES VENTES
# -------------------------------
st.subheader("📈 Évolution mensuelle des ventes")

df_filtered["MONTH"] = df_filtered["TRANSACTION_DATE"].dt.to_period("M").dt.to_timestamp()

sales_by_month = (
    df_filtered
    .groupby("MONTH", as_index=False)["AMOUNT"]
    .sum()
    .sort_values("MONTH")
)

st.line_chart(
    sales_by_month.set_index("MONTH")["AMOUNT"]
)

# -------------------------------
# VENTES PAR RÉGION
# -------------------------------
st.subheader("🌍 Ventes par région")

sales_by_region = (
    df_filtered
    .groupby("REGION")["AMOUNT"]
    .sum()
    .sort_values(ascending=False)
)

st.bar_chart(sales_by_region)
