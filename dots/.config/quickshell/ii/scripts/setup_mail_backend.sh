#!/bin/bash

# --- Quickshell Mail Setup Script ---
# This script sets up mbsync and notmuch for Gmail.

set -e

echo "------------------------------------------------"
echo "   Quickshell Mail Backend Setup (Gmail)        "
echo "------------------------------------------------"
echo ""
echo "PREREQUISITE: You MUST have a Gmail 'App Password'."
echo "1. Enable 2-Factor Auth on your Google Account."
echo "2. Go to Security > App Passwords."
echo "3. Generate one for 'Mail' and copy the 16-character code."
echo ""

read -p "Enter your Gmail address: " GMAIL_USER
read -s -p "Enter your Gmail App Password: " GMAIL_PASS
echo ""

MAIL_DIR="$HOME/Mail"
mkdir -p "$MAIL_DIR"

# 1. Install Dependencies (Detect package manager)
echo "[1/5] Checking dependencies..."
if command -v pacman >/dev/null; then
    sudo pacman -S --needed --noconfirm isync notmuch python-beautifulsoup4
elif command -v apt-get >/dev/null; then
    sudo apt-get update && sudo apt-get install -y isync notmuch python3-bs4
elif command -v dnf >/dev/null; then
    sudo dnf install -y isync notmuch python3-beautifulsoup4
else
    echo "Warning: Could not detect package manager. Please install 'isync', 'notmuch', and 'python3-bs4' manually."
fi

# 2. Configure mbsync
echo "[2/5] Configuring mbsync..."
MBSYNC_CONFIG="$HOME/.mbsyncrc"

# Handle existing config locations that might override ~/.mbsyncrc
# mbsync checks ~/.config/isyncrc (can be a file or directory) and ~/.mbsyncrc
for conflict in "$HOME/.config/isyncrc" "$HOME/.config/isync/mbsyncrc"; do
    if [ -e "$conflict" ]; then
        echo "Found existing config at $conflict. Moving it to ${conflict}.bak"
        mv "$conflict" "${conflict}.bak"
    fi
done

cat > "$MBSYNC_CONFIG" <<EOF
IMAPAccount gmail
Host imap.gmail.com
User $GMAIL_USER
Pass $GMAIL_PASS
SSLType IMAPS
AuthMechs LOGIN

IMAPStore gmail-remote
Account gmail

MaildirStore gmail-local
SubFolders Verbatim
Path $MAIL_DIR/
Inbox $MAIL_DIR/Inbox

Channel gmail
Far :gmail-remote:
Near :gmail-local:
Patterns *
Create Near
SyncState *
EOF

# 3. Initial Sync
echo "[3/5] Syncing mail from Gmail (this may take a while for the first time)..."
mbsync -a

# 4. Configure Notmuch
echo "[4/5] Configuring notmuch..."
notmuch setup <<EOF
$GMAIL_USER
$GMAIL_USER
$MAIL_DIR

inbox;unread
EOF

# 5. Setup Hooks (Auto-tagging)
echo "[5/5] Setting up automation hooks..."
HOOK_DIR="$MAIL_DIR/.notmuch/hooks"
mkdir -p "$HOOK_DIR"

cat > "$HOOK_DIR/post-new" <<EOF
#!/bin/bash
# Automatically tag new mail
notmuch tag +inbox +unread -- tag:new
notmuch tag -new -- tag:new
EOF

chmod +x "$HOOK_DIR/post-new"

# Initial index
notmuch new

echo ""
echo "------------------------------------------------"
echo "   SUCCESS! Mail backend is ready.              "
echo "------------------------------------------------"
echo "The Mail tab in your Cheatsheet should now work."
echo "Mail is stored in: $MAIL_DIR"
echo "------------------------------------------------"
