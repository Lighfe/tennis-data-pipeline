# Tennis Data Pipeline

An end-to-end batch data pipeline built on ATP and WTA tennis data (Jeff Sackmann, GitHub CSVs). Built as a final project for the [DataTalksClub Data Engineering Zoomcamp](https://github.com/DataTalksClub/data-engineering-zoomcamp) 2026 cohort.

## Architecture

```
GitHub CSVs (ATP + WTA)
        │
        ▼
   Airflow DAG
        │
        ├── Download CSVs from GitHub
        ├── Upload raw files to GCS (data lake)
        ├── Load from GCS into BigQuery (raw tables)
        └── Run dbt transformations
                │
                ▼
        Looker Studio Dashboard
```

**Stack:**
- **IaC:** Terraform (provisions GCS bucket + BigQuery dataset)
- **Orchestration:** Airflow via Docker Compose
- **Data lake:** Google Cloud Storage (GCS)
- **Warehouse:** BigQuery
- **Transformations:** dbt Core
- **Dashboard:** Looker Studio

## Research Questions

- How has the age of successful players changed over time? (ATP vs WTA comparison)
- Most common match outcomes — likelihood of going to a third set

---

## Reproducing This Project

### Prerequisites

- A [GitHub](https://github.com) account with Codespaces access
- A [Google Cloud Platform](https://console.cloud.google.com) account (free tier is sufficient)

---

### Step 1 — Fork or clone the repository

Fork this repository to your own GitHub account, or clone it:

```bash
git clone https://github.com/Lighfe/tennis-data-pipeline.git
```

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
4. After creating it, go to the **Keys** tab → **Add Key → Create new key → JSON**
5. Download the JSON key file to your local machine

---

### Step 4 — Add the service account key as a Codespaces secret

This ensures the key is injected securely into your Codespace without ever being committed to the repository.

1. Go to **github.com → Settings → Codespaces → New secret**
2. Name: `GOOGLE_APPLICATION_CREDENTIALS_JSON`
3. Value: paste the **full contents** of the JSON key file
4. Repository access: select your `tennis-data-pipeline` repository

> ⚠️ Never commit the JSON key file to the repository.

---

### Step 5 — Start the Codespace

1. Open the repository on GitHub
2. Click **Code → Codespaces → New codespace**
3. Wait for the environment to build — this takes a few minutes on first run

The devcontainer will automatically install:
- Terraform
- Google Cloud CLI (`gcloud`)
- `uv` (Python package manager)

And will authenticate with GCP using the secret from Step 4.

---

### Step 6 — Verify the setup

Once the Codespace is ready, open a terminal and verify:

```bash
terraform version
gcloud version
uv self version
gcloud projects describe <your-project-id>
```

All four commands should return version information or project metadata without errors.

---

### Step 7 — Configure your project ID

Update the Terraform variables file with your GCP project ID:

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Edit `terraform/terraform.tfvars`:

```hcl
project_id = "your-gcp-project-id"
region     = "us-central1"
```

---

### Step 8 — Provision cloud infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

This creates:
- A GCS bucket for raw data
- A BigQuery dataset

---

### Step 9 — Run the pipeline

```bash
cd airflow
docker compose up -d
```

Open the Airflow UI at `http://localhost:8080` and trigger the DAG.

---

### Step 10 — View the dashboard

The Looker Studio dashboard is available at: `<link>`

---

## Project Structure

```
tennis-data-pipeline/
├── .devcontainer/
│   ├── devcontainer.json
│   └── install.sh
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── terraform.tfvars.example
├── airflow/
│   ├── docker-compose.yml
│   └── dags/
├── dbt/
└── README.md
```