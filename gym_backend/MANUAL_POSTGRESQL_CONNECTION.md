# 🔧 Manual PostgreSQL Connection Guide for Railway

## Problem: PostgreSQL not auto-connecting to Django app

Follow these steps to manually connect Railway PostgreSQL to your Django application.

## 📋 Step-by-Step Instructions

### Step 1: Get PostgreSQL Connection Details

1. **Go to Railway Dashboard:**
   - Visit https://railway.app/dashboard
   - Click on your `gym-management` project

2. **Click on PostgreSQL Service:**
   - Find the PostgreSQL service box (NOT your app)
   - Click on it to open PostgreSQL settings

3. **Go to Variables Tab:**
   - Click on **"Variables"** tab
   - You'll see something like:
   ```
   PGHOST=containers-us-west-xx.railway.app
   PGPORT=5432
   PGDATABASE=railway  
   PGUSER=postgres
   PGPASSWORD=abc123xyz789
   DATABASE_URL=postgresql://postgres:abc123xyz789@containers-us-west-xx.railway.app:5432/railway
   ```

### Step 2: Connect to Your Django App

#### Option A: Copy DATABASE_URL (Recommended)

1. **Go to Your Django App Service:**
   - Click on your `gym-backend` service
   - Click **"Variables"** tab

2. **Add DATABASE_URL:**
   - Click **"+ New Variable"**
   - **Name:** `DATABASE_URL`
   - **Value:** Copy the entire `DATABASE_URL` from PostgreSQL service
   - Example: `postgresql://postgres:abc123@containers-us-west-xx.railway.app:5432/railway`
   - Click **"Add"**

#### Option B: Add Individual Variables

If DATABASE_URL doesn't work, add these variables to your Django app:

1. **Add PostgreSQL Variables:**
   - `PGHOST` = `containers-us-west-xx.railway.app`
   - `PGPORT` = `5432`
   - `PGDATABASE` = `railway`
   - `PGUSER` = `postgres`
   - `PGPASSWORD` = `your-actual-password`

### Step 3: Redeploy Your App

1. **Trigger Redeploy:**
   - Go to your Django app service
   - Click **"Deployments"** tab
   - Click **"Redeploy"** on the latest deployment

### Step 4: Verify Connection

After redeploy, check the logs. You should see:

```
✅ Using DATABASE_URL: postgresql://postgres:...
🔍 Database Engine: django.db.backends.postgresql
🐘 PostgreSQL Host: containers-us-west-xx.railway.app
🐘 PostgreSQL Database: railway
✅ PostgreSQL connection successful
```

## 🚨 Troubleshooting

### Issue 1: Still seeing SQLite
**Logs show:**
```
⚠️ WARNING: No PostgreSQL configuration found!
⚠️ Using SQLite: django.db.backends.sqlite3
```

**Solution:**
- Double-check DATABASE_URL is copied correctly
- Ensure no extra spaces in the variable value
- Verify PostgreSQL service is running

### Issue 2: Connection refused
**Logs show:**
```
connection to server at "host" failed: Connection refused
```

**Solution:**
- Verify PostgreSQL service is running (green status)
- Check if PGHOST matches exactly
- Ensure PGPASSWORD is correct

### Issue 3: Authentication failed
**Logs show:**
```
FATAL: password authentication failed
```

**Solution:**
- Copy PGPASSWORD exactly (no extra characters)
- Use DATABASE_URL instead of individual variables

## 🎯 Expected Success Logs

Once connected properly, you'll see:

```
✅ Using DATABASE_URL: postgresql://postgres:password@host...
🔍 Database Engine: django.db.backends.postgresql  
🐘 PostgreSQL Host: containers-us-west-xx.railway.app
🐘 PostgreSQL Database: railway
✅ PostgreSQL connection successful
Database version: PostgreSQL 15.x
Operations to perform:
  Apply all migrations: admin, auth, contenttypes, gym_api, sessions
Running migrations:
  Applying contenttypes.0001_initial... OK
  Applying auth.0001_initial... OK
  ...
```

## 🔍 Quick Verification Steps

1. **Check PostgreSQL Service Status:**
   - Should show green "Running" status
   - Should have connection variables

2. **Check Django App Variables:**
   - Should have `DATABASE_URL` variable
   - Value should start with `postgresql://`

3. **Check Deployment Logs:**
   - Should show PostgreSQL connection success
   - Should show migrations running

## 📝 Common Variable Formats

**DATABASE_URL format:**
```
postgresql://USER:PASSWORD@HOST:PORT/DATABASE
```

**Real examples:**
```
postgresql://postgres:AbC123XyZ@containers-us-west-123.railway.app:5432/railway
postgresql://postgres:my-secret-pass@viaduct-us-east-456.railway.app:5432/railway
```

---

## ✅ Success Checklist

- [ ] PostgreSQL service is running in Railway
- [ ] DATABASE_URL copied to Django app variables  
- [ ] Django app redeployed
- [ ] Logs show PostgreSQL connection success
- [ ] Migrations completed successfully
- [ ] No more "connection refused" errors

Once you see PostgreSQL in the logs instead of SQLite, your database connection is working!