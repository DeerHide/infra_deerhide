#!/usr/bin/env bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to show usage
function show_usage() {
    echo -e "${BLUE}Usage: $0 -h HOSTNAME -u USERNAME -k KEY_FILE${NC}"
    echo ""
    echo "Simple script to setup SSH keys for deerhide-operator users"
    echo ""
    echo "Options:"
    echo "  -h, --host HOSTNAME     Target server hostname or IP"
    echo "  -u, --user USERNAME     Username (e.g., bob, francis, david)"
    echo "  -k, --key KEY_FILE      Path to public key file"
    echo "  --help                  Show this help"
    echo ""
    echo "Example:"
    echo "  $0 -h deerhide -u bob -k ~/.ssh/YOUR_KEY.pub"
}

# Function to log
function log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

function log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

function log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse arguments
HOSTNAME=""
USERNAME=""
KEY_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--host)
            HOSTNAME="$2"
            shift 2
            ;;
        -u|--user)
            USERNAME="$2"
            shift 2
            ;;
        -k|--key)
            KEY_FILE="$2"
            shift 2
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate arguments
if [[ -z "$HOSTNAME" || -z "$USERNAME" || -z "$KEY_FILE" ]]; then
    log_error "Missing required arguments"
    show_usage
    exit 1
fi

if [[ ! -f "$KEY_FILE" ]]; then
    log_error "Key file not found: $KEY_FILE"
    exit 1
fi

# Set variables
FULL_USERNAME="deerhide-operator-${USERNAME}"
PUBLIC_KEY=$(cat "$KEY_FILE")

# Show what we're going to do
echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  SSH Setup for ${FULL_USERNAME}${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""
echo "Host: $HOSTNAME"
echo "User: $FULL_USERNAME"
echo "Key file: $KEY_FILE"
echo ""
echo "Public key:"
echo "$PUBLIC_KEY"
echo ""

# Confirm
read -p "Continue? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    log_info "Cancelled"
    exit 0
fi

# Execute commands
log_info "Creating .ssh directory..."
ssh deerhide-operator@$HOSTNAME "sudo mkdir -p /home/$FULL_USERNAME/.ssh"

log_info "Setting permissions..."
ssh deerhide-operator@$HOSTNAME "sudo chown $FULL_USERNAME:deerhide-operator /home/$FULL_USERNAME/.ssh"
ssh deerhide-operator@$HOSTNAME "sudo chmod 700 /home/$FULL_USERNAME/.ssh"

log_info "Adding public key to authorized_keys..."
ssh deerhide-operator@$HOSTNAME "echo '$PUBLIC_KEY' | sudo tee -a /home/$FULL_USERNAME/.ssh/authorized_keys > /dev/null"

log_info "Setting authorized_keys permissions..."
ssh deerhide-operator@$HOSTNAME "sudo chown $FULL_USERNAME:deerhide-operator /home/$FULL_USERNAME/.ssh/authorized_keys"
ssh deerhide-operator@$HOSTNAME "sudo chmod 600 /home/$FULL_USERNAME/.ssh/authorized_keys"

log_success "SSH setup completed for $FULL_USERNAME"
echo ""
echo "You can now connect with:"
echo -e "${GREEN}ssh $FULL_USERNAME@$HOSTNAME${NC}"
