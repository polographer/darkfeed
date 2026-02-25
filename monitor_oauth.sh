#!/bin/bash

echo "=== DarkFeed OAuth Monitor ==="
echo ""
echo "This script monitors the SharedPreferences file for changes."
echo "Run the app in another terminal and complete the OAuth flow."
echo ""

PREFS_FILE="$HOME/.local/share/com.example.darkfeed/shared_preferences.json"

echo "Watching: $PREFS_FILE"
echo "Press Ctrl+C to stop"
echo ""
echo "---"

# Initial state
if [ -f "$PREFS_FILE" ]; then
    echo "Initial state:"
    cat "$PREFS_FILE" | jq '.' 2>/dev/null || cat "$PREFS_FILE"
    echo "---"
else
    echo "No existing preferences file"
    echo "---"
fi

# Watch for changes
while true; do
    if [ -f "$PREFS_FILE" ]; then
        CURRENT_CONTENT=$(cat "$PREFS_FILE")
        
        if [ "$CURRENT_CONTENT" != "$PREVIOUS_CONTENT" ]; then
            echo ""
            echo "[$(date '+%H:%M:%S')] File changed!"
            echo "$CURRENT_CONTENT" | jq '.' 2>/dev/null || echo "$CURRENT_CONTENT"
            echo "---"
            
            # Check for tokens
            if echo "$CURRENT_CONTENT" | grep -q "access_token"; then
                echo "✓ ACCESS TOKEN DETECTED!"
            fi
            
            if echo "$CURRENT_CONTENT" | grep -q "instance_url"; then
                INSTANCE=$(echo "$CURRENT_CONTENT" | jq -r '.["flutter.instance_url"]' 2>/dev/null)
                echo "✓ Instance: $INSTANCE"
            fi
            
            PREVIOUS_CONTENT="$CURRENT_CONTENT"
        fi
    fi
    
    sleep 1
done
