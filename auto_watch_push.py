#!/usr/bin/env python3
"""
Auto-watch and push script for Gym Management System
Watches for file changes and automatically pushes to GitHub
"""

import time
import subprocess
import os
from pathlib import Path

def run_git_push():
    """Run the safe git push script"""
    try:
        result = subprocess.run(
            ["python3", "safe_git_push.py"],
            capture_output=True,
            text=True,
            check=True
        )
        print("✅ Auto-push successful!")
        print(result.stdout)
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Auto-push failed: {e.stderr}")
        return False

def watch_for_changes():
    """Watch for file changes and auto-push"""
    print("👀 Watching for changes in gym_backend/...")
    print("📝 Any file changes will auto-push to GitHub")
    print("🛑 Press Ctrl+C to stop watching\n")
    
    last_check = time.time()
    
    while True:
        try:
            # Check if any files have been modified recently
            backend_path = Path("gym_backend")
            recent_changes = False
            
            for file_path in backend_path.rglob("*.py"):
                if file_path.stat().st_mtime > last_check:
                    recent_changes = True
                    break
            
            if recent_changes:
                print(f"🔧 Changes detected at {time.strftime('%H:%M:%S')}")
                print("⏳ Waiting 10 seconds for more changes...")
                time.sleep(10)  # Wait for multiple changes
                
                print("🚀 Auto-pushing to GitHub...")
                run_git_push()
                
            last_check = time.time()
            time.sleep(5)  # Check every 5 seconds
            
        except KeyboardInterrupt:
            print("\n🛑 Stopped watching for changes")
            break
        except Exception as e:
            print(f"❌ Error watching files: {e}")
            time.sleep(10)

if __name__ == "__main__":
    # Change to project directory
    project_dir = "/Users/rohittiwari/Downloads/flutter-projects/GYMPROJECT/gym-management-system"
    os.chdir(project_dir)
    
    print("🤖 Auto Git Push Watcher")
    print("=" * 50)
    
    watch_for_changes()