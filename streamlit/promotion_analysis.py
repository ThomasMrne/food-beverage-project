import streamlit as st
import pandas as pd
import snowflake.connector

# -------------------------
# CONFIG
# -------------------------
st.set_page_config(page_title="Promotion Analysis", layout="wide")

# -------------------------
# SNOWFLAKE CONNECTION
# -------------------------
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
            REGION,
            PRODUCT_CATEGORY,
            DISCOUNT_PERCENTAGE,
            DATEDIFF('day', START_DATE, END_DATE) + 1 AS PROMO_DURATION
        FROM PROMOTIONS_CLEAN
        WHERE DISCOUNT_PERCENTAGE IS NOT NULL
    """
    conn = get_connection()
    df = pd.read_sql(query, conn)
    conn.close()

    # nettoyage critique
    df = df[df["REGION"].notna()]
    df["REGION"] = df["REGION"].astype(str)
    df = df[~df["REGION"].isin(["0", "1"])]

    return df

df = load_data()

# -------------------------
# HEADER
# -------------------------
st.title("📦 Promotion Analysis")
st.caption("Vue simple et actionnable des promotions")

# -------------------------
# FILTER
# -------------------------
regions = ["ALL"] + sorted(df["REGION"].unique())
selected_region = st.selectbox("🌍 Région", regions)

if selected_region != "ALL":
    df = df[df["REGION"] == selected_region]

# -------------------------
# KPI METRICS
# -------------------------
col1, col2, col3 = st.columns(3)

nb_promos = len(df)
avg_discount = df["DISCOUNT_PERCENTAGE"].mean() * 100
avg_duration = df["PROMO_DURATION"].mean()

col1.metric("Nombre de promotions", nb_promos)
col2.metric("Remise moyenne (%)", f"{avg_discount:.1f} %")
col3.metric("Durée moyenne (jours)", f"{avg_duration:.1f}")

st.divider()

# -------------------------
# CHART 1 – Promotions par catégorie
# -------------------------
st.subheader("📊 Nombre de promotions par catégorie")

promo_by_cat = (
    df.groupby("PRODUCT_CATEGORY")
    .size()
    .sort_values(ascending=False)
)

st.bar_chart(promo_by_cat)

# -------------------------
# CHART 2 – Remise moyenne par catégorie
# -------------------------
st.subheader("💸 Remise moyenne par catégorie")

discount_by_cat = (
    df.groupby("PRODUCT_CATEGORY")["DISCOUNT_PERCENTAGE"]
    .mean()
    .mul(100)
    .sort_values(ascending=False)
)

st.bar_chart(discount_by_cat)

# -------------------------
# TABLE – Detail
# -------------------------
st.subheader("📋 Détail des promotions")
st.dataframe(
    df.sort_values("DISCOUNT_PERCENTAGE", ascending=False),
    use_container_width=True
)