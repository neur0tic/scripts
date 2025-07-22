#!/bin/bash

# Define variables
URL="https://raw.githubusercontent.com/neur0tic/scripts/refs/heads/development/thread_dumper_jcmd.sh"
DEST="/usr/local/bin/thread_dumper_jcmd.sh"
TMP_FILE="/tmp/thread_dumper_jcmd.sh"

# Download the script
curl -fsSL "$URL" -o "$TMP_FILE" || {
  echo "❌ Failed to download script from $URL"
  exit 1
}

# Move the script to /usr/local/bin
sudo mv "$TMP_FILE" "$DEST" || {
  echo "❌ Failed to move script to $DEST"
  exit 1
}

# Make it executable
sudo chmod +x "$DEST" || {
  echo "❌ Failed to make $DEST executable"
  exit 1
}

echo "✅ Script successfully installed at $DEST and made executable."
