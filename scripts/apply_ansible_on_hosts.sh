#!/usr/bin/env bash

# Activate python virtualenv
if [[ -d .venv ]]; then
  source .venv/bin/activate
fi

ANSIBLE_INVENTORY=ansible/inventories/inventory.ini

# Colors
RED='\033[0;31m'
ORANGE='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Load environment variables from .env file if it exists
if [[ -f .env ]]; then
  export $(cat .env | xargs)
fi

# Check if the ANSIBLE_VAULT_PASSWORD_FILE environment variable is set
if [[ -z "${ANSIBLE_VAULT_PASSWORD_FILE}" ]]
then
  echo "$RED ANSIBLE_VAULT_PASSWORD_FILE is not set $NC"
  exit 1
fi

# List available playbooks
declare -a PLAYBOOKS
PLAYBOOKS+=("ansible/playbook.yml (All hosts)", "ansible/rasp-playbook.yml (Rasp hosts)")

# Extract the unique list of hosts
while IFS= read -r host; do
  # Remove any trailing whitespace and newlines
  host=$(echo "$host" | tr -d '\n\r' | xargs)
  if [[ -n "$host" && "$host" != "" && "$host" =~ ^[a-zA-Z] ]]; then
    pb="ansible/${host}-playbook.yml"
    if [[ -f "$pb" ]]; then
      PLAYBOOKS+=("$pb ($host only)")
    fi
  fi
done < <(awk '/^[^#\[]/ && !/^\[/ && NF>0 {print $1}' ${ANSIBLE_INVENTORY} | sort -u)

# Detect if an argument is passed and use as PB_DESC
if [[ -n "$1" ]]; then
  # Check if the argument is a number (menu selection)
  if [[ "$1" =~ ^[0-9]+$ ]]; then
    # It's a numeric selection, treat it as a menu choice
    SELECTION_NUM=$1
    if [[ $SELECTION_NUM -ge 1 && $SELECTION_NUM -le ${#PLAYBOOKS[@]} ]]; then
      PB_DESC="${PLAYBOOKS[$((SELECTION_NUM-1))]}"
      PB_PATH=$(echo "$PB_DESC" | awk '{print $1}')
      echo "You selected: $PB_PATH"
    else
      echo "Invalid selection number: $SELECTION_NUM. Please choose between 1 and ${#PLAYBOOKS[@]}"
      exit 1
    fi
  else
    # It's a direct playbook path or description
    PB_DESC="$1"
    PB_PATH=$(echo "$PB_DESC" | awk '{print $1}')

    if [[ -f "$PB_PATH" ]]; then
      echo "You selected: $PB_PATH"
    else
      echo "Playbook not found: $PB_PATH"
      exit 1
    fi
  fi
else
  # Prompt user to select a playbook
  echo "Which playbook do you want to run?"
  select PB_DESC in "${PLAYBOOKS[@]}"; do
    if [[ -n "$PB_DESC" ]]; then
      # Extract the playbook path (before the first space)
      PB_PATH=$(echo "$PB_DESC" | awk '{print $1}')
      echo "You selected: $PB_PATH"
      break
    else
      echo "Invalid choice. Please select a valid playbook."
    fi
  done
fi

ansible-playbook \
    -i ${ANSIBLE_INVENTORY} \
    --vault-id="default@${ANSIBLE_VAULT_PASSWORD_FILE}" \
    -e @ansible-vars.yml \
    "$PB_PATH"
