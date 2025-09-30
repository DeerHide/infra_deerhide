# Adapt and Remix

This guide explains how to reuse this repository for a different infrastructure and how to add new sites, server groups, and servers.

## Prerequisites

- Ansible installed (use `./scripts/install_ansible.sh`)
- SSH access to target hosts (see `./scripts/create_and_install_sshkey.sh`)
- Ansible Vault password file path exported: `ANSIBLE_VAULT_PASSWORD_FILE=/path/to/vault-pass.txt`

### Repository Layout Reference

- `ansible/inventories/inventory.ini`: Hosts and groups
- `ansible/group_vars/`: Variables per group (e.g., `all/`, `rasp/`)
- `ansible/host_vars/`: Variables per host (e.g., `bunryl.yml`)
- `ansible/roles/`: Service roles to enable on hosts
- Playbooks: `ansible/playbook.yml`, `*-playbook.yml` per host/group
- Global secrets and settings: `ansible-vars.yml` (vaulted entries)
- Runner scripts: `./scripts/*.sh`
- Ansible config: `ansible.cfg`

---

## Use for Another Infrastructure

1. Duplicate or fork the repo

   - Create a new repository and copy this tree.

1. Define your inventory

   - Edit `ansible/inventories/inventory.ini` to list your hosts with `ansible_host`, `ansible_user`, and optional `ansible_port`, `ansible_become_pass`, etc.

1. Create host variables (optional)

   - Add files under `ansible/host_vars/<hostname>.yml` for per-host settings.

1. Create or adapt groups

   - Use `[groupname]` sections in `inventory.ini`.
   - Add group variables under `ansible/group_vars/<groupname>.yml` or `ansible/group_vars/<groupname>/...`.

1. Adjust global variables and secrets

   - Review `ansible-vars.yml`. Add or rotate secrets using Ansible Vault.
     - View: `./scripts/view_ansible-vault_file.sh`
     - Encrypt: `./scripts/encrypt_ansible-vault_file.sh`

1. Select services (roles)

   - In the relevant playbook (`ansible/playbook.yml` or a new one), include roles from `ansible/roles/` that you need.

1. Verify connectivity

   - Ensure SSH keys are installed and hostnames resolve.
   - Test with `./scripts/ping_ansible_hosts.sh`.

1. Apply

   - Run `./scripts/apply_ansible_on_hosts.sh` and select the appropriate playbook.

Notes

- `ansible.cfg` points to `ansible/inventories/inventory.ini` by default.
- Vault is injected via `--vault-id="default@$ANSIBLE_VAULT_PASSWORD_FILE"` by the scripts.

---

## Add a Site (logical environment)

1. Create a group in the inventory

   - Add a section in `ansible/inventories/inventory.ini`, e.g.,
     - `[site_paris]` and list hosts under it.

1. Add group variables

   - Create `ansible/group_vars/site_paris.yml` or a directory `ansible/group_vars/site_paris/` for structured files.

1. Add or adapt a playbook (optional)

   - Create `ansible/site_paris-playbook.yml` including the hosts pattern and roles.
   - The `./scripts/apply_ansible_on_hosts.sh` script auto-detects `*-playbook.yml` files per host; you can run site playbooks by selecting them when prompted.

---

## Add a Server Group

1. Define the group in `inventory.ini`

   - Example: `[db]` with hosts listed below.

1. Create `group_vars`

   - Add `ansible/group_vars/db.yml` for common settings.

1. Ensure roles reference the group where needed

   - Some roles may target groups (e.g., DNS peers). Update role variables accordingly.

---

## Add a Server (host)

1. Add the host to `inventory.ini`

   - Example:
     - `myhost ansible_host=10.0.0.10 ansible_user=deployer`

1. Set per-host variables (optional)

   - Create `ansible/host_vars/myhost.yml` for host-specific values (passwords, paths, service flags).

1. Prepare SSH access

   - Generate and deploy an identity: `./scripts/create_and_install_sshkey.sh` (edit variables inside to match host, user, and port).
   - Or manually copy your public key.

1. Test connectivity

   - `./scripts/ping_ansible_hosts.sh`

1. Run a targeted playbook (optional)

   - Create `ansible/myhost-playbook.yml` to run only against this host and pick it from the runner script menu.

---

## Working with Vault

- Global secrets live in `ansible-vars.yml` and are referenced from roles and vars.
- Export once in your shell:
  - `export ANSIBLE_VAULT_PASSWORD_FILE=/absolute/path/to/vault-pass.txt`
- Edit/view helpers:
  - `./scripts/view_ansible-vault_file.sh`
  - `./scripts/encrypt_ansible-vault_file.sh`

---

## Service Catalog (Roles)

Browse `ansible/roles/` to see available services (e.g., `svc_traefik`, `svc_coredns`, `svc_minio`, `svc_svn`, `svc_nut`, `updates`, `deerhide_users`, `operator_gpg`, etc.).
Include the roles you need in your playbook and set role variables in `group_vars` or `host_vars`.
