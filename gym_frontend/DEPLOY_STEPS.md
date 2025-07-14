# 🚀 Quick Netlify Deployment Steps

## Step 1: Build Flutter Web
```bash
cd /Users/rohittiwari/Downloads/flutter-projects/GYMPROJECT/gym-management-system/gym_frontend

flutter clean
flutter pub get
flutter build web --release

# Create redirects file
echo "/*    /index.html   200" > build/web/_redirects
```

## Step 2: Deploy to Netlify
1. Go to https://netlify.com
2. Sign up with email (free)
3. Click "Add new site" → "Deploy manually"
4. **Drag the `build/web` folder** from Finder to Netlify
5. Wait 30-60 seconds
6. Get your URL: `https://random-name.netlify.app`

## Step 3: Test
- Open the URL on mobile browser
- Try "Add to Home Screen"
- Test all features

## Step 4: Share
Send the Netlify URL to your friend - works like a native app!

## For Automatic Updates (Optional)
1. Push to GitHub:
```bash
git add .
git commit -m "Add web deployment"
git push origin main
```

2. In Netlify: "Import from Git" → Select repo
3. Build settings:
   - Base directory: `gym_frontend`
   - Build command: `flutter build web --release`
   - Publish directory: `build/web`

Now every GitHub push = automatic deployment!