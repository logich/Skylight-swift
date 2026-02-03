#!/bin/bash
# Watch Skylight App Intent logs in real-time

echo "🔍 Watching Skylight App Intent logs..."
echo "Press Ctrl+C to stop"
echo ""

xcrun simctl spawn booted log stream \
  --predicate 'processImagePath contains "SkylightApp" OR processImagePath contains "Shortcuts"' \
  --level=debug \
  --color=always \
  | grep --line-buffered -E "(CalendarEventQuery|CalendarIntent|Intent|Skylight)" \
  | while read line; do
    if [[ $line == *"CalendarEventQuery"* ]]; then
      echo "✅ $line"
    elif [[ $line == *"error"* ]] || [[ $line == *"Error"* ]]; then
      echo "❌ $line"
    else
      echo "   $line"
    fi
  done
