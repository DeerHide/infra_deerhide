# Deerhide Infrastructure Scripts

This directory contains automation scripts for managing the Deerhide infrastructure.

<!-- Table of Contents for quick access to scripts -->
## Table of Contents

- [ansible_facts.sh](#ansiblefactssh--ping-or-deploy-do-it-to-)
- [apply_ansible_on_hosts.sh](#applyansibleonhostssh)
- [ping_ansible_hosts.sh](#pingansiblehostssh)
- [create_and_install_sshkey.sh](#createandinstallsshkeysh)
- [setup_operator_sshkey_all_servers.sh](#setupoperatorsshkeyallserverssh)

## Ansible Scripts

### `ansible_facts.sh`
**Purpose:** Collects system information from all hosts via Ansible and saves it to `ansible_facts.json`.

**Requirements:**
- Environment variable `ANSIBLE_VAULT_PASSWORD_FILE` set
- `.env` file (optional)
- Python virtual environment with Ansible installed

### `apply_ansible_on_hosts.sh`
**Purpose:** Executes an Ansible playbook on selected hosts. Provides an interactive menu to choose the playbook.

**Requirements:**
- Environment variable `ANSIBLE_VAULT_PASSWORD_FILE` set
- `.env` file (optional)
- Python virtual environment with Ansible installed
- `ansible-vars.yml` file

### `ping_ansible_hosts.sh`
**Purpose:** Tests connectivity with all hosts defined in the Ansible inventory.

**Requirements:**
- You must have already deployed the keys at least once if you don't want to have an permissions denied
- Environment variable `ANSIBLE_VAULT_PASSWORD_FILE` set
- `.env` file (optional)
- Python virtual environment with Ansible installed
- `ansible/ping-playbook.yml` playbook available

## SSH Key Management Scripts

### `create_and_install_sshkey.sh`
**Purpose:** Generates a new ED25519 SSH key and deploys it to a specific server.

**Requirements:**
- SSH access to target server
- `deerhide-operator` user on the server
- `force` option to force regeneration

**Usage:** `./create_and_install_sshkey.sh [force]`

### `setup_operator_sshkey_all_servers.sh`
**Purpose:** Configures SSH keys for a user on all infrastructure servers.

**Requirements:**
- SSH access to servers via `deerhide-operator`
- Valid public key file

**Usage:** `./setup_operator_sshkey_all_servers.sh -u USERNAME -k KEY_FILE_PATH`

### `setup_operator_sshkey_by_hosts.sh`
**Purpose:** Configures SSH keys for a user on a specific server.

**Requirements:**
- SSH access to target server via `deerhide-operator`
- Valid public key file

**Usage:** `./setup_operator_sshkey_by_hosts.sh -h HOSTNAME -u USERNAME -k KEY_FILE_PATH`

## Deployment Scripts

### `create_deploy_key.sh`
**Purpose:** Generates an SSH key pair for GitHub deployment.

**Requirements:**
- `./tmp` directory writable

### `install_ansible.sh`
**Purpose:** Installs Ansible and associated tools in a Python virtual environment.

**Requirements:**
- Python 3 installed
- pip access

### `install_kube_tools.sh`
**Purpose:** Installs Kubernetes tools (kubectl, clusterctl, talosctl).

**Requirements:**
- sudo privileges
- Internet access
- Linux AMD64 architecture

## Ansible Variables Management Scripts

### `encrypt_ansible-vault_file.sh`
**Purpose:** Encrypts a specific variable in the `ansible-vars.yml` file with Ansible Vault.

**Requirements:**
- Environment variable `ANSIBLE_VAULT_PASSWORD_FILE` set
- `ansible-vars.yml` file exists
- `yq` tool installed
- Python virtual environment with Ansible installed

**Usage:** `./encrypt_ansible-vault_file.sh VARIABLE_NAME`

### `view_ansible-vault_file.sh`
**Purpose:** Displays the decrypted content of variables from the `ansible-vars.yml` file.

**Requirements:**
- Environment variable `ANSIBLE_VAULT_PASSWORD_FILE` set
- `ansible-vars.yml` file exists
- `yq` tool installed
- Python virtual environment with Ansible installed

## Required Configuration

### Environment Variables
```bash
export ANSIBLE_VAULT_PASSWORD_FILE="/path/to/your/vault-password"
```

### Configuration Files
- `.env`: Environment variables (optional)
- `ansible-vars.yml`: Ansible variables
- `ansible/inventories/inventory.ini`: Host inventory

### External Tools
- `yq`: For YAML file manipulation
- `ssh-keygen`: For SSH key generation
- `ssh-copy-id`: For SSH key deployment
