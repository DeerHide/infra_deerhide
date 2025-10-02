#!/usr/bin/env bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Function to show usage
function show_usage() {
    echo -e "${BLUE}Usage: $0 -u USERNAME -k KEY_FILE${NC}"
    echo ""
    echo "Setup SSH keys for deerhide-operator users on all servers"
    echo ""
    echo "Options:"
    echo "  -u, --user USERNAME     Username (e.g., bob, francis, david)"
    echo "  -k, --key KEY_FILE      Path to public key file"
    echo "  --help                  Show this help"
    echo ""
    echo "Example:"
    echo "  $0 -u bob -k ~/.ssh/id_ed25519.pub"
}

# Parse arguments
USERNAME=""
KEY_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
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
if [[ -z "$USERNAME" || -z "$KEY_FILE" ]]; then
    log_error "Missing required arguments"
    show_usage
    exit 1
fi

if [[ ! -f "$KEY_FILE" ]]; then
    log_error "Key file not found: $KEY_FILE"
    exit 1
fi

# List of servers
# Add more servers if needed in the list below
SERVERS=(
    "192.168.60.188" # melissa
    "192.168.60.59" # claudia
    "192.168.60.115" # helene
    "192.168.60.93" # giustina
    "192.168.60.220" # elise
    "192.168.60.121" # sibylle
    "192.168.60.58" # marion
    "192.168.60.200" # marlene
    "192.168.3.220" # bunryl
)

# Show what we're going to do
echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  SSH Setup for all servers${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""
echo "User: deerhide-operator-$USERNAME"
echo "Key file: $KEY_FILE"
echo "Servers: ${#SERVERS[@]}"
echo ""
for server in "${SERVERS[@]}"; do
    echo "  - $server"
done
echo ""

# Confirm
read -p "Continue? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    log_info "Cancelled"
    exit 0
fi

# Execute for each server
SUCCESS_COUNT=0
FAILED_COUNT=0

for server in "${SERVERS[@]}"; do
    echo ""
    log_info "Setting up SSH for $server..."

    if ./scripts/setup_ssh_simple.sh -h "$server" -u "$USERNAME" -k "$KEY_FILE"; then
        log_success "SSH setup completed for $server"
        ((SUCCESS_COUNT++))
    else
        log_error "SSH setup failed for $server"
        ((FAILED_COUNT++))
    fi
done

# Summary
echo ""
echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  Setup Summary${NC}"
echo -e "${BLUE}==========================================${NC}"
echo "Total servers: ${#SERVERS[@]}"
echo -e "${GREEN}Successful: $SUCCESS_COUNT${NC}"
echo -e "${RED}Failed: $FAILED_COUNT${NC}"

if [[ $FAILED_COUNT -eq 0 ]]; then
    log_success "All servers configured successfully!"
else
    log_error "Some servers failed. Check the output above."
    exit 1
fi
