# Must-Know Quick Start

A condensed cheat-sheet to be productive fast.

## 1) Bootstrap a New Host

- Create operator user with sudo and SSH key (or use `./scripts/create_and_install_sshkey.sh` after editing variables at the top)
- Ensure network/DNS and time are correct
- Add host to `ansible/inventories/inventory.ini` (set `ansible_host`, `ansible_user`, optional port/interpreter)
- Test connectivity: `./scripts/ping_ansible_hosts.sh`

## 2) Secrets/Vault Essentials

- Put vault password in a file and export once per shell:

```bash
export ANSIBLE_VAULT_PASSWORD_FILE=/path/to/vault-pass.txt
```

- View/edit `ansible-vars.yml` with the helpers:
  - View: `./scripts/view_ansible-vault_file.sh`
  - Encrypt/rotate: `./scripts/encrypt_ansible-vault_file.sh`
- Store secrets in `ansible-vars.yml`; host/group-specific secrets may live in `host_vars`/`group_vars`

## 3) Run the Right Scope

- All hosts (interactive): `./scripts/apply_ansible_on_hosts.sh`
- Ping only: `./scripts/ping_ansible_hosts.sh`
- Limit to one host or group with raw `ansible-playbook` (examples):

```bash
ansible-playbook -i ansible/inventories/inventory.ini \
  --vault-id="default@$ANSIBLE_VAULT_PASSWORD_FILE" -e @ansible-vars.yml \
  ansible/playbook.yml --limit melissa

ansible-playbook -i ansible/inventories/inventory.ini \
  --vault-id="default@$ANSIBLE_VAULT_PASSWORD_FILE" -e @ansible-vars.yml \
  ansible/playbook.yml --limit rasp
```

- Use tags to run subsets:

```bash
ansible-playbook ... --tags svc_minio
ansible-playbook ... --skip-tags updates
```

## 4) Inventory Conventions (quick)

- Define hosts in `ansible/inventories/inventory.ini`
- Use `group_vars/<group>.yml` for shared settings; `host_vars/<host>.yml` for host-specific
- If a host needs a non-default Python, set `ansible_python_interpreter` (see `bunryl` example)

## 5) Scripts Reference (most used)

- `install_ansible.sh`: creates `.venv`, installs Ansible and tools
- `apply_ansible_on_hosts.sh`: interactive runner; injects vault and `ansible-vars.yml`
- `ping_ansible_hosts.sh`: connectivity check with vault injection
- `create_and_install_sshkey.sh`: generate/deploy SSH key; writes client config include
- `view_ansible-vault_file.sh`: view vault contents
- `encrypt_ansible-vault_file.sh`: encrypt/rotate `ansible-vars.yml`

## 6) Troubleshooting (fast)

- Vault error: check `ANSIBLE_VAULT_PASSWORD_FILE` path and permissions (0600)
- SSH refused/timeouts: verify `ansible_host`, port, user; ensure key deployed; try `ssh <user>@<host>`
- Become/sudo prompts: set `ansible_become_pass` (vaulted) for that host/group
- Interpreter issues: set `ansible_python_interpreter` in inventory or `host_vars`
- Dry run: append `--check` (be mindful outputs may differ)

## 7) Optional: Ansible Pull

- For self-managing hosts, see `docs/ANSIBLE_PULL.md` for `ansible-pull` + systemd timer
