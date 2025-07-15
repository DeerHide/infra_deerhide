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
PLAYBOOKS+=("ansible/playbook.yml (All hosts)")

# Dynamically add host-specific playbooks if they exist
for host in $(awk '/^\[/{g=$0} /^[^#].*ansible_host=/{print $1}' ${ANSIBLE_INVENTORY}); do
  pb="ansible/${host}-playbook.yml"
  if [[ -f "$pb" ]]; then
    PLAYBOOKS+=("$pb ($host only)")
  fi
done

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

ansible-playbook \
    -i ${ANSIBLE_INVENTORY} \
    --vault-id="default@${ANSIBLE_VAULT_PASSWORD_FILE}" \
    -e @ansible-vars.yml \
    "$PB_PATH"
