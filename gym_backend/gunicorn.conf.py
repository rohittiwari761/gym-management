"""
Gunicorn configuration for production deployment.
Optimized for 100k+ concurrent users.
"""

import multiprocessing
import os

# Server socket - Railway provides PORT environment variable
port = os.environ.get("PORT", "8000")
bind = f"0.0.0.0:{port}"
backlog = 2048

# Worker processes - Conservative for Railway
workers = 1  # Start with single worker for Railway
worker_class = "sync"
worker_connections = 1000
max_requests = 1000  # Restart workers after this many requests
max_requests_jitter = 50
preload_app = True  # Load application code before forking workers

# Timeouts
timeout = 120
keepalive = 2
graceful_timeout = 30

# Logging - Railway uses stdout/stderr
accesslog = "-"  # Log to stdout
errorlog = "-"   # Log to stderr
loglevel = "info"
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s'

# Process naming
proc_name = 'gym_management_api'

# Security
limit_request_line = 4096
limit_request_fields = 100
limit_request_field_size = 8190

# Performance tuning - Railway compatible
# worker_tmp_dir = '/dev/shm'  # Commented out for Railway compatibility

# Environment variables
raw_env = [
    'DJANGO_SETTINGS_MODULE=gym_backend.settings_production',
]

# SSL (if needed)
# keyfile = "/path/to/keyfile"
# certfile = "/path/to/certfile"

# Hooks for monitoring
def when_ready(server):
    server.log.info("Server is ready. Spawning workers")

def worker_int(worker):
    worker.log.info("worker received INT or QUIT signal")

def pre_fork(server, worker):
    server.log.info("Worker spawned (pid: %s)", worker.pid)

def pre_exec(server):
    server.log.info("Forked child, re-executing.")

def when_ready(server):
    server.log.info("Server is ready. Spawning workers")

def worker_abort(worker):
    worker.log.info("worker received SIGABRT signal")