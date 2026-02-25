#!/bin/bash

echo "=== DarkFeed OAuth Flow Test ==="
echo ""
echo "Step 1: Clearing existing auth data..."
rm -f ~/.local/share/com.example.darkfeed/shared_preferences.json
echo "✓ Auth data cleared"
echo ""

echo "Step 2: Starting the app..."
echo "Please complete the following steps in the app:"
echo "  1. Select 'pixelfed.social' as your instance"
echo "  2. Click 'Login with Pixelfed'"
echo "  3. Complete OAuth in the browser"
echo "  4. Wait for the app to crash (this is expected)"
echo ""
echo "Press ENTER when the app has crashed..."

# Start the app in background and capture output
./build/linux/x64/debug/bundle/darkfeed > /tmp/darkfeed_oauth.log 2>&1 &
APP_PID=$!

echo "App started with PID: $APP_PID"
echo "Monitoring logs in real-time..."
echo "---"

# Monitor for OAuth success
tail -f /tmp/darkfeed_oauth.log &
TAIL_PID=$!

# Wait for user to indicate app crashed
read -p ""

# Kill tail
kill $TAIL_PID 2>/dev/null

echo ""
echo "Step 3: Checking if token was saved..."
if [ -f ~/.local/share/com.example.darkfeed/shared_preferences.json ]; then
    echo "✓ SharedPreferences file exists"
    
    if grep -q "access_token" ~/.local/share/com.example.darkfeed/shared_preferences.json; then
        echo "✓ Access token found!"
        echo ""
        echo "Saved data:"
        cat ~/.local/share/com.example.darkfeed/shared_preferences.json | jq '.'
    else
        echo "✗ Access token NOT found"
        echo "Saved data:"
        cat ~/.local/share/com.example.darkfeed/shared_preferences.json
    fi
else
    echo "✗ SharedPreferences file does not exist"
fi

echo ""
echo "Step 4: Restarting app to test auto-login..."
echo "The app should automatically log you in and show your timeline."
echo ""
read -p "Press ENTER to restart the app..."

./build/linux/x64/debug/bundle/darkfeed > /tmp/darkfeed_restart.log 2>&1 &
APP_PID=$!

echo "App restarted with PID: $APP_PID"
echo "Monitoring logs..."
tail -f /tmp/darkfeed_restart.log
