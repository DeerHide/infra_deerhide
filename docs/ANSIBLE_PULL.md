# Ansible Pull on Target Hosts

This guide explains how to run Ansible in pull mode directly on a target host, so the host pulls playbooks and applies them autonomously.

## When to Use

- You want hosts to self-manage on a schedule (cron/systemd timer)
- Hosts have limited inbound connectivity but can reach your Git repo
- You prefer no central control node pushing changes

## Requirements on Target Host

- Python 3
- Git installed and network access to the repository
- Ansible installed locally on the host
- SSH keys or token configured for repo access if private
- Vault password accessible locally (file path or askpass script)

## Install Ansible on the Host

Install Ansible via your distro or pip. Example with pip in a venv:

```bash
python3 -m venv /opt/ansible
source /opt/ansible/bin/activate
pip install ansible jmespath
```

## Repository Layout Assumptions

- Root of repo contains `ansible.cfg`, `ansible/`, and `ansible-vars.yml`
- The target playbook to run is e.g. `ansible/playbook.yml` or a host/site specific playbook

## ansible-pull Basics

Run manually first to validate:

```bash
export ANSIBLE_VAULT_PASSWORD_FILE=/root/.secrets/ansible-vault-pass.txt
ansible-pull \
  --url "<GIT_REPO_URL>" \
  --checkout main \
  --directory /opt/infra_deerhide \
  --full \
  --accept-host-key \
  --vault-id "default@$ANSIBLE_VAULT_PASSWORD_FILE" \
  -e @ansible-vars.yml \
  ansible/playbook.yml
```

Notes

- `--directory` is where the repo will be cloned/updated on the host
- If your inventory is inside the repo and `ansible.cfg` points to it (as in this project), no extra `-i` is needed
- Use a host/site specific playbook if you want to limit scope on that host

## Vault on the Host

- Store the vault password securely on the host (e.g., `/root/.secrets/ansible-vault-pass.txt`, `0600`)
- Reference it with `--vault-id "default@$ANSIBLE_VAULT_PASSWORD_FILE"`
- Alternatively, use a custom `--vault-id` script that retrieves the secret from a key store

## Make It Periodic

### systemd Timer (recommended)

Create a service:

```ini
# /etc/systemd/system/ansible-pull.service
[Unit]
Description=Ansible Pull
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
Environment=ANSIBLE_VAULT_PASSWORD_FILE=/root/.secrets/ansible-vault-pass.txt
WorkingDirectory=/opt/infra_deerhide
ExecStart=/bin/bash -lc '\
  if [ ! -d /opt/infra_deerhide/.git ]; then \
    ansible-pull --url "<GIT_REPO_URL>" --checkout main --directory /opt/infra_deerhide --accept-host-key; \
  fi; \
  ansible-pull --url "<GIT_REPO_URL>" --checkout main --directory /opt/infra_deerhide \
    --vault-id "default@$ANSIBLE_VAULT_PASSWORD_FILE" -e @ansible-vars.yml ansible/playbook.yml'
```

Create a timer:

```ini
# /etc/systemd/system/ansible-pull.timer
[Unit]
Description=Run Ansible Pull periodically

[Timer]
OnBootSec=2min
OnUnitActiveSec=15min
Persistent=true

[Install]
WantedBy=timers.target
```

Enable and start:

```bash
systemctl daemon-reload
systemctl enable --now ansible-pull.timer
systemctl status ansible-pull.timer
```

### Cron (alternative)

```bash
# Run every 30 minutes
*/30 * * * * root ANSIBLE_VAULT_PASSWORD_FILE=/root/.secrets/ansible-vault-pass.txt \
  ansible-pull --url "<GIT_REPO_URL>" --checkout main --directory /opt/infra_deerhide \
  --vault-id "default@$ANSIBLE_VAULT_PASSWORD_FILE" -e @ansible-vars.yml ansible/playbook.yml >> /var/log/ansible-pull.log 2>&1
```

## Inventory Considerations

- Keep using the repo’s `ansible/inventories/inventory.ini` and `ansible.cfg` so `ansible-pull` picks the right inventory automatically
- If you want the host to only apply host-specific roles, consider using a dedicated `ansible/<hostname>-playbook.yml` and call that in `ansible-pull`

## Troubleshooting

- Git auth failure: ensure deploy key/token is configured and host can reach the Git remote
- Vault decryption errors: verify `ANSIBLE_VAULT_PASSWORD_FILE` path/permissions and vault policy name (`default@...`)
- Role/path not found: confirm `--directory` matches and playbook paths are correct
- Long runs: check `journalctl -u ansible-pull.service` or cron logs for detailed output
