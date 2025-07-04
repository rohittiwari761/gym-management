#!/usr/bin/env python3
"""
Safe Git Push Script for Gym Management System
Securely pushes code to GitHub with proper error handling
"""

import subprocess
import sys
import os

def run_command(cmd, description="", allow_failure=False):
    """Run a command safely with error handling"""
    print(f"🔧 {description}...")
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        if result.stdout:
            print(f"✅ {result.stdout.strip()}")
        return True
    except subprocess.CalledProcessError as e:
        if allow_failure:
            print(f"⚠️ {description} failed (continuing): {e.stderr.strip()}")
            return False
        else:
            print(f"❌ {description} failed: {e.stderr.strip()}")
            return False

def main():
    """Main function to push gym management fixes"""
    print("🚀 Pushing Gym Management System fixes to GitHub...")
    
    # Change to project directory
    project_dir = "/Users/rohittiwari/Downloads/flutter-projects/GYMPROJECT/gym-management-system"
    os.chdir(project_dir)
    print(f"📁 Working in: {project_dir}")
    
    # Check if we're in a git repository
    if not os.path.exists(".git"):
        print("❌ Not a git repository. Please run 'git init' first.")
        return False
    
    # Add all changes
    if not run_command(["git", "add", "."], "Adding all changes"):
        return False
    
    # Check if there are changes to commit
    result = subprocess.run(["git", "diff", "--staged", "--quiet"], capture_output=True)
    if result.returncode == 0:
        print("ℹ️ No changes to commit")
        return True
    
    # Commit changes
    commit_message = """🔧 Fix Railway health check and deployment issues

✅ Critical Fixes:
- Simplified health check endpoint (no complex dependencies)  
- Created Railway-optimized Gunicorn configuration
- Fixed logging to use stdout/stderr for Railway
- Removed non-existent log file paths

🚀 Deployment Fixes:
- Health check now returns simple database test
- Gunicorn uses Railway PORT environment variable
- Trainer-member associations ready for production

🎯 This should resolve Railway health check failures!"""
    
    if not run_command(["git", "commit", "-m", commit_message], "Committing changes"):
        return False
    
    # Push to origin main
    if not run_command(["git", "push", "origin", "main"], "Pushing to GitHub"):
        return False
    
    print("\n🎉 Successfully pushed fixes to GitHub!")
    print("🚀 Railway will automatically detect changes and re-deploy")
    print("🎯 Check your Railway dashboard for deployment progress")
    print("\n📋 Next steps:")
    print("1. Monitor Railway deployment logs")
    print("2. Verify health check passes")
    print("3. Get your production URL")
    print("4. Test trainer-member associations!")
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)