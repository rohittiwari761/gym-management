#!/bin/bash

# Setup cron job for automatic member deactivation
# This script should be run once to set up the cron job

# Get the current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
VENV_DIR="$(dirname "$SCRIPT_DIR")/venv"

# Create the cron command
CRON_COMMAND="0 1 * * * cd $PROJECT_DIR && source $VENV_DIR/bin/activate && python manage.py deactivate_expired_members --send-notifications >> /var/log/gym_member_expiry.log 2>&1"

# Add to crontab (runs daily at 1 AM)
echo "Setting up cron job for automatic member deactivation..."
echo "This will run daily at 1:00 AM"
echo ""
echo "Cron command:"
echo "$CRON_COMMAND"
echo ""

# Add to current user's crontab
(crontab -l 2>/dev/null; echo "$CRON_COMMAND") | crontab -

if [ $? -eq 0 ]; then
    echo "✅ Cron job added successfully!"
    echo ""
    echo "The system will now:"
    echo "• Check for expired members daily at 1:00 AM"
    echo "• Automatically deactivate expired members"
    echo "• Send email notifications to gym owners"
    echo "• Create in-app notifications"
    echo "• Log activities to /var/log/gym_member_expiry.log"
    echo ""
    echo "To view current cron jobs: crontab -l"
    echo "To remove this cron job: crontab -e (then delete the line)"
else
    echo "❌ Failed to add cron job"
    exit 1
fi

# Create log directory if it doesn't exist
sudo mkdir -p /var/log
sudo touch /var/log/gym_member_expiry.log
sudo chmod 666 /var/log/gym_member_expiry.log

echo "✅ Setup complete!"