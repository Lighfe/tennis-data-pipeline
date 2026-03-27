# Tennis Data Pipeline

An end-to-end batch data pipeline built on ATP and WTA tennis data (Jeff Sackmann, GitHub CSVs). Built as a final project for the [DataTalksClub Data Engineering Zoomcamp](https://github.com/DataTalksClub/data-engineering-zoomcamp) 2026 cohort.

## Research Questions

- How has the age of successful players changed over time? (ATP vs WTA comparison)
- Most common match outcomes — likelihood of going to a third/fourth/fifth set

## Architecture

```
GitHub CSVs (ATP + WTA)
        │
        ▼
   Airflow DAG (Docker Compose)
        │
        ├── cleanup_gcs         — delete existing tour files from GCS
        ├── download_{year}     — download CSV from GitHub (one task per year)
        ├── upload_{year}       — upload to GCS, delete local file
        ├── load_bigquery       — load all CSVs via wildcard URI (WRITE_TRUNCATE)
        └── dbt_run             — run dbt transformations
                │
                ▼
        Looker Studio Dashboard
```

**Stack:**
- **IaC:** Terraform — provisions GCS bucket + BigQuery datasets (`tennis_raw`, `tennis_prod`)
- **Orchestration:** Airflow 3 via Docker Compose (GitHub Codespaces)
- **Data lake:** Google Cloud Storage (GCS)
- **Warehouse:** BigQuery (partitioned by year, clustered by tour)
- **Transformations:** dbt Core (staging → intermediate → marts)
- **Dashboard:** Looker Studio

## Project Structure

```
tennis-data-pipeline/
├── .devcontainer/
│   ├── devcontainer.json       # Codespaces environment definition
│   └── install.sh              # installs gcloud, uv; configures auth and PATH
├── airflow/
│   ├── Dockerfile              # extends apache/airflow:3.1.8
│   ├── docker-compose.yaml
│   ├── requirements.txt        # pipeline + dbt dependencies for the container
│   └── dags/
│       └── tennis_pipeline.py  # main DAG
├── dbt/
│   ├── dbt_project.yml
│   ├── packages.yml
│   ├── analyses/               # example queries (not materialized)
│   ├── models/
│   │   ├── staging/            # stg_atp_matches, stg_wta_matches
│   │   ├── intermediate/       # int_matches_unionized, int_matches_enriched
│   │   └── marts/              # fct_player_age_trends, fct_match_outcomes
│   └── tests/                  # singular data tests
├── pipeline/
│   ├── download.py             # download CSVs from GitHub
│   ├── upload_gcs.py           # upload files to GCS
│   └── load_bigquery.py        # load GCS files into BigQuery
├── schemas/
│   └── matches.json            # BigQuery schema for raw tables
└── terraform/
    ├── main.tf
    ├── variables.tf
    └── terraform.tfvars.example
```

---

## Reproducing This Project

### Prerequisites

- A [GitHub](https://github.com) account with Codespaces access
- A [Google Cloud Platform](https://console.cloud.google.com) account (free tier is sufficient)

---

### Step 1 — Fork the repository

Fork this repository to your own GitHub account so you can create Codespaces secrets against it.

---

### Step 2 — Create a GCP project

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Create a new project — note the **Project ID**
3. Enable the following APIs:
   - [Cloud Resource Manager API](https://console.developers.google.com/apis/api/cloudresourcemanager.googleapis.com)
   - [Cloud Storage API](https://console.developers.google.com/apis/api/storage.googleapis.com)
   - [BigQuery API](https://console.developers.google.com/apis/api/bigquery.googleapis.com)

---

### Step 3 — Create a service account

1. Go to **IAM & Admin → Service Accounts → Create Service Account**
2. Name it `terraform-sa`
3. Assign the following roles:
   - `Storage Admin`
   - `BigQuery Admin`
   - `Service Usage Consumer`
4. Go to the **Keys** tab → **Add Key → Create new key → JSON**
5. Download the JSON key file

> ⚠️ Never commit the JSON key file to the repository.

---

### Step 4 — Add the service account key as a Codespaces secret

1. Go to **github.com → Settings → Codespaces → New secret**
2. Name: `GOOGLE_APPLICATION_CREDENTIALS_JSON`
3. Value: paste the **full contents** of the JSON key file
4. Repository access: select your forked `tennis-data-pipeline` repository

---

### Step 5 — Start the Codespace

1. Open the forked repository on GitHub
2. Click **Code → Codespaces → New codespace**
3. Wait for the environment to build — this takes a few minutes on first run

The devcontainer automatically:
- Installs Terraform, Google Cloud CLI (`gcloud`), and `uv`
- Authenticates with GCP using the secret from Step 4
- Adds `dbt` and Docker API version to `PATH` via `~/.bashrc`

**Open a new terminal** after the build completes to ensure all environment variables are loaded. You should see:

```
GCP authentication complete.
```

Verify the setup:

```bash
terraform version
gcloud version
uv --version
gcloud projects describe <your-project-id>
```

---

### Step 6 — Configure Terraform variables

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Edit `terraform/terraform.tfvars`:

```hcl
project_id   = "your-gcp-project-id"
region       = "us-central1"
bucket_name  = "your-unique-bucket-name"
```

---

### Step 7 — Provision cloud infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

This creates:
- A GCS bucket for raw data
- A BigQuery dataset `tennis_raw` for raw tables
- A BigQuery dataset `tennis_prod` for dbt models

---

### Step 8 — Configure the Airflow environment

Create `airflow/.env` with the following contents (replace values with your own):

```bash
AIRFLOW_UID=0
GOOGLE_APPLICATION_CREDENTIALS=/tmp/gcp/key.json
GCP_PROJECT_ID=your-gcp-project-id
GCS_BUCKET=your-unique-bucket-name
GCS_PREFIX=raw
BQ_DATASET=tennis_raw
AIRFLOW_PROJ_DIR=/workspaces/tennis-data-pipeline/airflow
```

The `AIRFLOW__WEBSERVER__BASE_URL` line is written automatically by `install.sh` using the Codespace name — do not add it manually.

---

### Step 9 — Start Airflow

```bash
cd airflow
docker compose up --build -d
```

Wait ~2 minutes for all services to start, then check:

```bash
docker compose ps
```

The `airflow-apiserver` and `airflow-scheduler` should show `(healthy)`.

Open the Airflow UI via the **Ports** tab in Codespaces (port 8080). Log in with `airflow` / `airflow`.

---

### Step 10 — Set Airflow Variables

In the Airflow UI go to **Admin → Variables** and create:

| Key | Value | Description |
|-----|-------|-------------|
| `tennis_start_year` | `1995` | First year to download |
| `tennis_end_year` | `2024` | Last year to download |

The DAG re-parses within ~30 seconds. The graph should show two parallel task groups (ATP + WTA) with the correct number of year tasks.

---

### Step 11 — Configure dbt

dbt requires a `profiles.yml` file at `~/.dbt/profiles.yml`. Run the interactive setup:

```bash
cd dbt
uv run dbt init dbt
```

When prompted:
- **Database**: `bigquery`
- **Authentication**: `service_account`
- **Keyfile**: `/tmp/gcp-key.json`
- **Project**: your GCP project ID
- **Dataset**: `tennis_prod`
- **Threads**: `4`
- **Location**: `us-central1`

Then install dbt packages:

```bash
uv run dbt deps
```

Verify the connection:

```bash
uv run dbt debug
```

---

### Step 12 — Trigger the pipeline

In the Airflow UI, enable and trigger the `tennis_pipeline` DAG. The full run for 30 years of data takes approximately 20-30 minutes.

Once complete, verify in BigQuery:
- `tennis_raw.atp_matches` and `tennis_raw.wta_matches` should exist with data
- `tennis_prod` should contain the dbt views and tables

---

### Step 13 — View the dashboard

The Looker Studio dashboard is available at: `<link>`

---

## Restarting the Codespace

After a Codespace **restart** (not rebuild), GCP auth is re-applied automatically via `postStartCommand`. Open a new terminal to ensure `~/.bashrc` is sourced, then restart Airflow:

```bash
cd airflow
docker compose up -d
```