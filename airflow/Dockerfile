FROM apache/airflow:3.1.8

# Install pipeline dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt