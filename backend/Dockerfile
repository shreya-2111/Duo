FROM python:3.12-slim

# Prevent Python from writing .pyc files and enable unbuffered output
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PORT=8000

WORKDIR /app

# Install system dependencies (build-essential, default-libmysqlclient-dev if needed, curl for health check)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gcc \
    libmariadb-dev-compat \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Install python dependencies
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend source code
COPY . /app/

# Collect static files
RUN python manage.py collectstatic --noinput || true

# Expose HTTP port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:${PORT}/api/health/ || exit 1

# Run Gunicorn WSGI server
CMD ["sh", "-c", "gunicorn duo_backend.wsgi:application --bind 0.0.0.0:${PORT} --workers 3 --timeout 120"]

