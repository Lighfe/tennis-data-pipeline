import os
import sys
from pathlib import Path
from datetime import datetime

from airflow.sdk import DAG, TaskGroup
from airflow.providers.standard.operators.python import PythonOperator
from airflow.providers.standard.operators.bash import BashOperator
from airflow.models import Variable

sys.path.insert(0, '/opt/airflow')

from pipeline.download import download_csv
from pipeline.upload_gcs import upload_to_gcs
from pipeline.load_bigquery import load_tour_to_bigquery

# ── Config ────────────────────────────────────────────────────────────────────
GCP_PROJECT_ID = os.environ['GCP_PROJECT_ID']
GCS_BUCKET     = os.environ['GCS_BUCKET']
GCS_PREFIX     = os.environ.get('GCS_PREFIX', 'raw')
BQ_DATASET     = os.environ['BQ_DATASET']

LOCAL_DIR = '/tmp/tennis'

# Read at parse time — change via Airflow UI > Admin > Variables
START_YEAR = int(Variable.get('tennis_start_year', default_var=1995))
END_YEAR   = int(Variable.get('tennis_end_year',   default_var=2024))

# ── Task callables ─────────────────────────────────────────────────────────────
def _cleanup_gcs(tour: str) -> None:
    from google.cloud import storage
    from google.cloud.exceptions import NotFound
    client = storage.Client()
    bucket = client.bucket(GCS_BUCKET)
    blobs = bucket.list_blobs(prefix=f"{GCS_PREFIX}/{tour}_matches_")
    for blob in blobs:
        try:
            blob.delete()
            print(f"Deleted {blob.name}")
        except NotFound:
            print(f"Already deleted: {blob.name}")


def _download(tour: str, year: int) -> None:
    download_csv(tour=tour, year=year, dest_dir=LOCAL_DIR)


def _upload_and_delete(tour: str, year: int) -> None:
    local_path = Path(LOCAL_DIR) / f"{tour}_matches_{year}.csv"
    upload_to_gcs(local_path=local_path, bucket_name=GCS_BUCKET, gcs_prefix=GCS_PREFIX)
    local_path.unlink()


def _load_bq(tour: str) -> None:
    load_tour_to_bigquery(
        tour=tour,
        bucket_name=GCS_BUCKET,
        dataset_id=BQ_DATASET,
        project_id=GCP_PROJECT_ID,
        gcs_prefix=GCS_PREFIX,
    )


# ── DAG ───────────────────────────────────────────────────────────────────────
with DAG(
    dag_id='tennis_pipeline',
    schedule='@yearly',
    start_date=datetime(2025, 1, 1),
    catchup=False,
    tags=['tennis'],
) as dag:

    years = range(START_YEAR, END_YEAR + 1)
    group_end_tasks = []

    for tour in ['atp', 'wta']:
        with TaskGroup(group_id=f'{tour}_group') as tour_group:

            cleanup_task = PythonOperator(
                task_id='cleanup_gcs',
                python_callable=_cleanup_gcs,
                op_kwargs={'tour': tour},
            )

            prev_task = cleanup_task

            for year in years:
                download_task = PythonOperator(
                    task_id=f'download_{year}',
                    python_callable=_download,
                    op_kwargs={'tour': tour, 'year': year},
                )
                upload_task = PythonOperator(
                    task_id=f'upload_{year}',
                    python_callable=_upload_and_delete,
                    op_kwargs={'tour': tour, 'year': year},
                )

                prev_task >> download_task >> upload_task  # type: ignore
                prev_task = upload_task

            load_bq_task = PythonOperator(
                task_id='load_bigquery',
                python_callable=_load_bq,
                op_kwargs={'tour': tour},
            )

            prev_task >> load_bq_task  # type: ignore
            group_end_tasks.append(load_bq_task)

    dbt_run = BashOperator(
        task_id='dbt_run',
        bash_command=(
            'dbt run --profiles-dir /opt/airflow/dbt --project-dir /opt/airflow/dbt && '
            'dbt test --profiles-dir /opt/airflow/dbt --project-dir /opt/airflow/dbt'
        ),
    )

    group_end_tasks >> dbt_run  # type: ignore