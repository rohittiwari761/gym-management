#!/bin/bash

# Production Deployment Script for Gym Management System
# Optimized for 100k+ users

set -e  # Exit on any error

echo "🚀 Starting Gym Management System Deployment..."

# Configuration
PROJECT_DIR="/app/gym_backend"
VENV_DIR="/app/venv"
LOG_DIR="/var/log/gym_app"
BACKUP_DIR="/backup/gym_db"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root for security reasons"
fi

# Create necessary directories
log "Creating necessary directories..."
sudo mkdir -p $LOG_DIR $BACKUP_DIR
sudo chown -R $USER:$USER $LOG_DIR $BACKUP_DIR

# Check if .env file exists
if [ ! -f ".env" ]; then
    warn ".env file not found. Please copy .env.example to .env and configure it."
    cp .env.example .env
    error "Please configure .env file before deployment"
fi

# Load environment variables
source .env

# Check dependencies
log "Checking system dependencies..."

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    error "PostgreSQL is not installed. Please install PostgreSQL first."
fi

# Check if Redis is installed
if ! command -v redis-cli &> /dev/null; then
    error "Redis is not installed. Please install Redis first."
fi

# Check if Docker is available (optional)
if command -v docker &> /dev/null; then
    log "Docker is available for containerized deployment"
else
    warn "Docker not found. Proceeding with traditional deployment."
fi

# Install Python dependencies
log "Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Database setup
log "Setting up database..."

# Check if database exists
if psql -h $DB_HOST -U $DB_USER -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
    log "Database $DB_NAME already exists"
else
    log "Creating database $DB_NAME..."
    createdb -h $DB_HOST -U $DB_USER $DB_NAME
fi

# Run migrations
log "Running database migrations..."
python manage.py migrate --settings=gym_backend.settings_production

# Create superuser if it doesn't exist
log "Checking for superuser..."
python manage.py shell -c "
from django.contrib.auth.models import User
if not User.objects.filter(is_superuser=True).exists():
    User.objects.create_superuser('admin', 'admin@gym.com', 'admin123')
    print('Superuser created: admin/admin123')
else:
    print('Superuser already exists')
" --settings=gym_backend.settings_production

# Collect static files
log "Collecting static files..."
python manage.py collectstatic --noinput --settings=gym_backend.settings_production

# Database optimization
log "Optimizing database..."
python manage.py optimize_database --all --settings=gym_backend.settings_production

# Test health endpoints
log "Testing health endpoints..."
python manage.py check --settings=gym_backend.settings_production

# Start services
log "Starting services..."

# Kill existing Gunicorn processes
pkill -f gunicorn || true

# Start Gunicorn
log "Starting Gunicorn server..."
gunicorn --config gunicorn.conf.py gym_backend.wsgi_production:application --daemon

# Wait for server to start
sleep 5

# Test server health
if curl -f http://localhost:8001/health/ > /dev/null 2>&1; then
    log "✅ Server is healthy and responding"
else
    error "❌ Server health check failed"
fi

# Setup log rotation
log "Setting up log rotation..."
sudo tee /etc/logrotate.d/gym_app > /dev/null <<EOF
$LOG_DIR/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 $USER $USER
    postrotate
        systemctl reload gunicorn
    endscript
}
EOF

# Setup systemd service (optional)
log "Setting up systemd service..."
sudo tee /etc/systemd/system/gym_backend.service > /dev/null <<EOF
[Unit]
Description=Gym Management System API
After=network.target postgresql.service redis.service

[Service]
Type=forking
User=$USER
WorkingDirectory=$PROJECT_DIR
Environment=DJANGO_SETTINGS_MODULE=gym_backend.settings_production
ExecStart=$VENV_DIR/bin/gunicorn --config gunicorn.conf.py gym_backend.wsgi_production:application
ExecReload=/bin/kill -s HUP \$MAINPID
PIDFile=/run/gunicorn/gym_backend.pid
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable gym_backend

# Setup monitoring
log "Setting up monitoring..."

# Create monitoring script
cat > monitor.sh << 'EOF'
#!/bin/bash
# Simple monitoring script for gym management system

LOG_FILE="/var/log/gym_app/monitor.log"

check_service() {
    service_name=$1
    if systemctl is-active --quiet $service_name; then
        echo "$(date): $service_name is running" >> $LOG_FILE
    else
        echo "$(date): $service_name is DOWN" >> $LOG_FILE
        systemctl restart $service_name
    fi
}

# Check services
check_service postgresql
check_service redis
check_service gym_backend

# Check disk space
df_output=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $df_output -gt 80 ]; then
    echo "$(date): Disk space critical: ${df_output}%" >> $LOG_FILE
fi

# Check memory usage
mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
if (( $(echo "$mem_usage > 90" | bc -l) )); then
    echo "$(date): Memory usage critical: ${mem_usage}%" >> $LOG_FILE
fi
EOF

chmod +x monitor.sh

# Add to crontab
(crontab -l 2>/dev/null; echo "*/5 * * * * $PROJECT_DIR/monitor.sh") | crontab -

# Final checks
log "Running final checks..."

# Check if all services are running
services=("postgresql" "redis")
for service in "${services[@]}"; do
    if systemctl is-active --quiet $service; then
        log "✅ $service is running"
    else
        warn "❌ $service is not running"
    fi
done

# Performance test
log "Running basic performance test..."
ab -n 100 -c 10 http://localhost:8001/health/ > /dev/null 2>&1 && \
    log "✅ Basic performance test passed" || \
    warn "❌ Performance test failed"

# Display final status
log "🎉 Deployment completed successfully!"
echo ""
log "Server Information:"
log "  - API URL: http://localhost:8001/api/"
log "  - Admin URL: http://localhost:8001/admin/"
log "  - Health Check: http://localhost:8001/health/"
log "  - Metrics: http://localhost:8001/metrics/"
echo ""
log "Next Steps:"
log "  1. Configure NGINX as reverse proxy"
log "  2. Setup SSL certificates"
log "  3. Configure monitoring dashboard"
log "  4. Setup backup automation"
echo ""
log "Log files location: $LOG_DIR"
log "Monitor with: tail -f $LOG_DIR/gunicorn_error.log"