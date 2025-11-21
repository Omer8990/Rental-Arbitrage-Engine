# 🏠 Rental Arbitrage Engine: End-to-End ELT Pipeline

   

## 📋 Project Overview

This project is a fully containerized, self-healing ELT data platform designed to identify **rental arbitrage opportunities**. It ingests short-term rental data (Airbnb) and compares it against long-term market lease rates (Zillow/Realty APIs) to calculate projected ROI for property investors.

The goal is not just to move data, but to enforce **strict data quality** contracts and ensure **idempotency** across the pipeline.

## 🏗 Architecture & Tech Stack

  * **Infrastructure:** Terraform (AWS S3, IAM, ECR, EC2).
  * **Containerization:** Docker & Docker Compose.
  * **Orchestration:** Apache Airflow (Local Executor).
  * **Ingestion:** Python (Custom Extractors with Pydantic validation).
  * **Storage:** AWS S3 (Raw Lake) $\to$ Snowflake (Data Warehouse).
  * **Transformation:** dbt Core (Data Build Tool).
  * **CI/CD:** GitHub Actions (SQL linting, Python testing, dbt manifest checks).

## 🧠 Key Design Decisions (The "Why")

### 1\. ELT over ETL

I chose an **ELT (Extract-Load-Transform)** pattern. Raw data is loaded immediately into S3 and Snowflake (`RAW` schema) before processing.

  * *Benefit:* This preserves the original data state for auditing and allows for replayability if transformation logic changes later.

### 2\. Idempotent Ingestion

The Python extraction scripts are designed to be idempotent. Running the pipeline for the same "business date" multiple times will **not** result in duplicate records in the warehouse. This is achieved via composite keys during the merge process.

### 3\. Infrastructure as Code (IaC)

All cloud resources are provisioned via **Terraform**. No manual clicking in the AWS Console. This ensures the environment is reproducible and version-controlled.

### 4\. Data Quality as a First-Class Citizen

  * **Pre-Load:** Pydantic models validate API responses structure.
  * **Post-Load:** dbt `generic tests` (unique, not\_null) and `singular tests` (custom SQL business logic) run before data is promoted to the `MART` layer.

-----

## 📂 Project Structure

```bash
├── .github/workflows    # CI/CD pipelines (sqlfluff, pytest)
├── airflow/             # Airflow DAGs and plugins
│   ├── dags/
│   ├── docker/
│   └── scripts/         # Python extraction scripts
├── dbt_project/         # dbt transformation logic
│   ├── models/
│   ├── tests/
│   └── snapshots/       # SCD Type 2 definitions
├── terraform/           # AWS Infrastructure definitions
├── docker-compose.yml   # Local orchestration setup
├── Makefile             # Shortcut commands for dev experience
└── README.md
```

-----

## 🚀 Getting Started

### Prerequisites

  * Docker Desktop
  * AWS CLI (configured)
  * Terraform
  * Snowflake Account (Trial is fine)

### 1\. Infrastructure Setup

Initialize the cloud resources (S3 buckets, IAM roles):

```bash
cd terraform
terraform init
terraform apply
```

### 2\. Environment Config

Create a `.env` file in the root directory:

```bash
AWS_ACCESS_KEY_ID=xxx
AWS_SECRET_ACCESS_KEY=xxx
SNOWFLAKE_ACCOUNT=xxx
SNOWFLAKE_USER=xxx
SNOWFLAKE_PASSWORD=xxx
AIRFLOW_UID=50000
```

### 3\. Launch the Stack

I've included a `Makefile` to abstract Docker complexity:

```bash
make up      # Builds images and starts Airflow webserver/scheduler
make init    # Initializes Airflow DB
```

### 4\. Run the Pipeline

Navigate to `localhost:8080` and trigger the `daily_arbitrage_pipeline` DAG.

-----

## 🛡 Data Quality & Testing

### Linting & Static Analysis

Before any code is merged, GitHub Actions runs:

  * **Black/Isort:** For Python formatting.
  * **SQLFluff:** For SQL style enforcement (aligned with dbt standards).

### Transformation Tests

The dbt pipeline includes the following critical checks:

  * **Stale Data Warning:** Alerts if listing data is older than 30 days.
  * **Negative Price Check:** Pipeline fails if `nightly_price < 0`.
  * **Orphaned Rows:** Checks referential integrity between `fact_listings` and `dim_hosts`.

-----

## 🔮 Future Improvements

  * **Dashboarding:** Connect Superset or Metabase for geospatial visualization of high-ROI zip codes.
  * **Reverse ETL:** Alert users via Slack/Email when a "Golden Listing" (ROI \> 20%) is found.
