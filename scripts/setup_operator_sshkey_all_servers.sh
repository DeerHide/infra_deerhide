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
    echo "Setup SSH keys for deerhide-operator users on selected servers"
    echo ""
    echo "Options:"
    echo "  -u, --user USERNAME     Username (e.g., bob, francis, david)"
    echo "  -k, --key KEY_FILE      Path to public key file"
    echo "  --help                  Show this help"
    echo ""
    echo "Example:"
    echo "  $0 -u bob -k ~/.ssh/YOUR_KEY.pub"
}

# Function to select site
function select_site() {
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}  Site/Location Selection${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo ""
    echo "1) CLB Site (${#CLB_HOSTS[@]} servers)"
    echo "   - ${CLB_HOSTS[*]}"
    echo ""
    echo "2) PRG Site (${#PRG_HOSTS[@]} servers)"
    echo "   - ${PRG_HOSTS[*]}"
    echo ""
    echo "3) LUZ Site (${#LUZ_HOSTS[@]} servers)"
    echo "   - ${LUZ_HOSTS[*]}"
    echo ""

    while true; do
        read -p "Your choice [1-3]: " site_choice
        case $site_choice in
            1)
                SELECTED_SITE="CLB"
                SELECTED_HOSTS=("${CLB_HOSTS[@]}")
                break
                ;;
            2)
                SELECTED_SITE="PRG"
                SELECTED_HOSTS=("${PRG_HOSTS[@]}")
                break
                ;;
            3)
                SELECTED_SITE="LUZ"
                SELECTED_HOSTS=("${LUZ_HOSTS[@]}")
                break
                ;;
            *)
                log_error "Invalid choice. Please select 1, 2, or 3."
                ;;
        esac
    done
}

# Function to select servers
function select_servers() {
    echo ""
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}  Server Selection - $SELECTED_SITE Site${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo ""
    echo "1) All servers in site (${#SELECTED_HOSTS[@]} servers)"
    echo "   - ${SELECTED_HOSTS[*]}"
    echo ""
    echo "2) Custom selection"
    echo "   - Manual selection of individual servers"
    echo ""

    while true; do
        read -p "Your choice [1-2]: " server_choice
        case $server_choice in
            1)
                SERVERS=("${SELECTED_HOSTS[@]}")
                break
                ;;
            2)
                select_custom_servers
                break
                ;;
            *)
                log_error "Invalid choice. Please select 1 or 2."
                ;;
        esac
    done
}

# Function to select custom servers
function select_custom_servers() {
    echo ""
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}  Server Selection - $SELECTED_SITE Site${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo ""
    echo "Available servers:"
    for i in "${!SELECTED_HOSTS[@]}"; do
        echo "$((i+1))) ${SELECTED_HOSTS[i]}"
    done
    echo ""

    while true; do
        read -p "Select servers (ex: 1,3,4 or 1-3): " selection
        if [[ -z "$selection" ]]; then
            log_error "Empty selection. Please choose at least one server."
            continue
        fi

        # Parse selection
        SERVERS=()
        IFS=',' read -ra PARTS <<< "$selection"
        for part in "${PARTS[@]}"; do
            if [[ "$part" =~ ^[0-9]+-[0-9]+$ ]]; then
                # Range selection (e.g., 1-3)
                start=$(echo "$part" | cut -d'-' -f1)
                end=$(echo "$part" | cut -d'-' -f2)
                for ((i=start; i<=end; i++)); do
                    if [[ $i -ge 1 && $i -le ${#SELECTED_HOSTS[@]} ]]; then
                        SERVERS+=("${SELECTED_HOSTS[$((i-1))]}")
                    fi
                done
            elif [[ "$part" =~ ^[0-9]+$ ]]; then
                # Single selection
                if [[ $part -ge 1 && $part -le ${#SELECTED_HOSTS[@]} ]]; then
                    SERVERS+=("${SELECTED_HOSTS[$((part-1))]}")
                else
                    log_error "Invalid number: $part"
                    continue 2
                fi
            else
                log_error "Invalid format: $part"
                continue 2
            fi
        done

        if [[ ${#SERVERS[@]} -eq 0 ]]; then
            log_error "No servers selected."
            continue
        fi

        # Remove duplicates
        SERVERS=($(printf '%s\n' "${SERVERS[@]}" | sort -u))
        break
    done
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

# Groups of servers by site/location
CLB_HOSTS=(
    "melissa"
    "claudia"
    "helene"
    "giustina"
    "elise"
    "sibylle"
    "marion"
    "marlene"
    "melanie"
)

PRG_HOSTS=(
    "maria"
    "caroline"
    "lisa"
    "ashley"
    "miranda"
    "lucile"
    "ludivine"
)

LUZ_HOSTS=(
    "sayuri"
)

# Interactive selection
select_site
select_servers

# Show what we're going to do
echo ""
echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  SSH Configuration - Summary${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""
echo "Site: $SELECTED_SITE"
echo "User: deerhide-operator-$USERNAME"
echo "Key file: $KEY_FILE"
echo "Selected servers: ${#SERVERS[@]}"
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

# Execute for each server in parallel
SUCCESS_COUNT=0
FAILED_COUNT=0

# Function to process a single server
process_server() {
    local server="$1"
    local username="$2"
    local key_file="$3"

    # Use the original script with automatic confirmation and suppress output
    printf "y\n" | ./scripts/setup_operator_sshkey_by_hosts.sh -h "$server" -u "$username" -k "$key_file" >/dev/null 2>&1
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        echo "SUCCESS:$server" >> /tmp/ssh_setup_results_$$
    else
        echo "FAILED:$server" >> /tmp/ssh_setup_results_$$
    fi
}

# Create temporary file for results
rm -f /tmp/ssh_setup_results_$$

# Disable exit on error for parallel execution
set +e

# Start all processes in parallel
for server in "${SERVERS[@]}"; do
    process_server "$server" "$USERNAME" "$KEY_FILE" &
done

# Wait for all background processes to complete
wait

# Display results in order
echo ""
echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  Processing Results${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""
if [[ -f /tmp/ssh_setup_results_$$ ]]; then
    while IFS=':' read -r status server; do
        if [[ "$status" == "SUCCESS" ]]; then
            log_success "SSH setup completed for $server"
        else
            log_error "SSH setup failed for $server"
        fi
    done < /tmp/ssh_setup_results_$$
fi

# Count results
SUCCESS_COUNT=0
FAILED_COUNT=0

if [[ -f /tmp/ssh_setup_results_$$ ]]; then
    # Count SUCCESS entries
    if grep -q "SUCCESS:" /tmp/ssh_setup_results_$$ 2>/dev/null; then
        SUCCESS_COUNT=$(grep -c "SUCCESS:" /tmp/ssh_setup_results_$$ 2>/dev/null)
    fi

    # Count FAILED entries
    if grep -q "FAILED:" /tmp/ssh_setup_results_$$ 2>/dev/null; then
        FAILED_COUNT=$(grep -c "FAILED:" /tmp/ssh_setup_results_$$ 2>/dev/null)
    fi

    rm -f /tmp/ssh_setup_results_$$
fi

# Ensure variables are numeric
SUCCESS_COUNT=$((SUCCESS_COUNT + 0))
FAILED_COUNT=$((FAILED_COUNT + 0))

# Re-enable exit on error
set -e

# Summary
echo ""
echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  Configuration Summary${NC}"
echo -e "${BLUE}==========================================${NC}"
echo "Site: $SELECTED_SITE"
echo "Total servers: ${#SERVERS[@]}"
echo -e "${GREEN}Successful: $SUCCESS_COUNT${NC}"
echo -e "${RED}Failed: $FAILED_COUNT${NC}"

if [[ $FAILED_COUNT -eq 0 ]]; then
    log_success "All servers configured successfully!"
else
    log_error "Some servers failed. Check the output above."
    exit 1
fi
