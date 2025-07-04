# Railway PostgreSQL Setup Guide

## 🚀 Setting Up PostgreSQL Database for Gym Management System

### Step 1: Add PostgreSQL Service in Railway

1. **Go to Railway Dashboard:**
   - Visit https://railway.app/dashboard
   - Select your `gym-management` project

2. **Add PostgreSQL Database:**
   - Click "**+ New Service**"
   - Select "**Database**" 
   - Choose "**PostgreSQL**"
   - Railway will automatically provision a PostgreSQL database

3. **Automatic Configuration:**
   - Railway automatically creates `DATABASE_URL` environment variable
   - This variable contains the complete PostgreSQL connection string
   - Format: `postgresql://user:password@host:port/database`

### Step 2: Verify Database Configuration

Your Django settings are already configured for PostgreSQL:

```python
# settings_production.py
DATABASE_URL = os.environ.get('DATABASE_URL')  # Railway provides this

if DATABASE_URL:
    # Uses PostgreSQL from Railway
    DATABASES = {
        'default': dj_database_url.config(
            default=DATABASE_URL,
            conn_max_age=300,
            conn_health_checks=True,
        )
    }
```

### Step 3: Check Database Connection

Run this command to verify PostgreSQL connection:

```bash
python manage.py check_db --settings=gym_backend.settings_production
```

**Expected Output:**
```
✅ DATABASE_URL found: postgresql://postgres:password@host...
✅ Using PostgreSQL: django.db.backends.postgresql
✅ Database connection successful
Database version: PostgreSQL 15.x
```

### Step 4: Deploy and Test

1. **Commit and Push:**
   ```bash
   git add .
   git commit -m "Add PostgreSQL database verification"
   git push origin main
   ```

2. **Railway Auto-Deploy:**
   - Railway automatically deploys from your main branch
   - Check deployment logs for database connection status

### Step 5: Verify PostgreSQL is Active

**In Railway Dashboard:**
- You should see two services:
  1. `gym-backend` (your Django app)
  2. `PostgreSQL` (your database)

**In Deployment Logs:**
- Look for: `✅ Using PostgreSQL database: django.db.backends.postgresql`
- Should NOT see: `WARNING: DATABASE_URL not found!`

### Common Issues and Solutions

#### Issue: "DATABASE_URL not found"
**Solution:** Add PostgreSQL service in Railway dashboard

#### Issue: "Connection refused"
**Solution:** 
- Ensure PostgreSQL service is running in Railway
- Check that DATABASE_URL is properly set

#### Issue: SQLite being used instead of PostgreSQL
**Solution:**
- Verify PostgreSQL service exists in Railway
- Check environment variables in Railway dashboard

### Environment Variables

Railway automatically provides:
- `DATABASE_URL` - PostgreSQL connection string
- `PORT` - Application port
- `RAILWAY_ENVIRONMENT` - Environment name

### Database Management

**Run Migrations:**
```bash
python manage.py migrate --settings=gym_backend.settings_production
```

**Create Superuser:**
```bash
python manage.py createsuperuser --settings=gym_backend.settings_production
```

**Access Database:**
- Use Railway dashboard database tab
- Or connect via `DATABASE_URL` with any PostgreSQL client

### Production Checklist

- [ ] PostgreSQL service added to Railway project
- [ ] `DATABASE_URL` environment variable exists
- [ ] Django settings use `settings_production.py`
- [ ] Database connection test passes
- [ ] Migrations run successfully
- [ ] Health check endpoint returns 200

---

## 🔍 Troubleshooting

If you see SQLite in logs instead of PostgreSQL:

1. **Check Railway Services:**
   - Ensure PostgreSQL service exists and is running

2. **Verify Environment Variables:**
   - In Railway dashboard, check if `DATABASE_URL` is set

3. **Check Django Settings:**
   - Verify `DJANGO_SETTINGS_MODULE=gym_backend.settings_production`

4. **Run Database Check:**
   ```bash
   python manage.py check_db --settings=gym_backend.settings_production
   ```

---

**✅ With PostgreSQL properly configured, your gym management system will have:**
- Reliable data persistence
- Better performance than SQLite
- Support for concurrent users
- Production-ready database features