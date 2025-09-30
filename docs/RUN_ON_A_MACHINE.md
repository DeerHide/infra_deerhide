# Run on a Machine

This guide shows what's needed and how to run the playbooks from this repository on a machine (your workstation) to configure target hosts.

## Requirements

- Linux or macOS shell with bash, Python 3, and SSH
- Internet access to install Python packages
- Access to the target hosts over SSH

Windows note: Use WSL2 or Git Bash to run the scripts. Native PowerShell is not supported by these bash scripts.

## Setup

1. Clone the repo

   - `git clone <your-fork-or-repo-url>`
   - `cd infra_deerhide`

2. Install Ansible locally in a virtualenv

   - `./scripts/install_ansible.sh`

3. Provide Ansible Vault password file

   - Create a local file with the vault password, e.g., `/home/user/.secrets/ansible-vault-pass.txt`.
   - Export the path as an environment variable:
     - `export ANSIBLE_VAULT_PASSWORD_FILE=/home/user/.secrets/ansible-vault-pass.txt`
   - Optional: put the export line in your shell profile so it's always set.

4. Configure SSH access to hosts

   - Ensure your user has SSH access to each host listed in `ansible/inventories/inventory.ini`.
   - You can use `./scripts/create_and_install_sshkey.sh` to generate and deploy an SSH key to a host (edit variables at the top of the script for host, user, and port).
   - Confirm you can `ssh deerhide-operator@<hostname>` without password prompts.

5. Verify inventory and variables

   - Check `ansible/inventories/inventory.ini` for host entries.
   - Review `ansible/group_vars/` and `ansible/host_vars/` for expected variables.
   - Global, vaulted values live in `ansible-vars.yml`.

## Connectivity Test

Run a simple ping to all hosts using the provided script:

```bash
./scripts/ping_ansible_hosts.sh
```

If all hosts respond with `SUCCESS`, you're ready to apply playbooks.

## Applying Playbooks

Use the interactive runner script, which auto-detects available playbooks:

```bash
./scripts/apply_ansible_on_hosts.sh
```

Notes

- The script reads `ansible.cfg` which points to `ansible/inventories/inventory.ini`.
- Vault is passed via `--vault-id="default@$ANSIBLE_VAULT_PASSWORD_FILE"`.
- It will prompt you to choose among:
  - `ansible/playbook.yml` (all hosts)
  - `ansible/rasp-playbook.yml` (Raspberry Pi group)
  - Any `*-playbook.yml` matching a host or site you added

## Troubleshooting

- Missing vault password
  - Ensure `ANSIBLE_VAULT_PASSWORD_FILE` is exported and the file exists.
- SSH failures
  - Verify hostnames/IPs, ports, and users in `inventory.ini`.
  - Regenerate and redeploy keys with `./scripts/create_and_install_sshkey.sh`.
- Python interpreter on target
  - If a host needs a specific interpreter, set `ansible_python_interpreter` in `inventory.ini` or `host_vars` (see `bunryl` example).
- Permission escalation
  - `ansible.cfg` sets `become=true`. If a host needs a sudo password, set `ansible_become_pass` in inventory or `host_vars` (use vault for secrets).

## Useful References

- Inventory: `ansible/inventories/inventory.ini`
- Global vars: `ansible-vars.yml`
- Roles: `ansible/roles/`
- Group vars: `ansible/group_vars/`
- Host vars: `ansible/host_vars/`
- Config: `ansible.cfg`
