# Ansible Vault: Create, Edit, and Use

This guide explains how to create and manage the vault used by this repository and how it ties into scripts and playbooks.

## What is in the Vault

- Secrets such as passwords, tokens, and deploy keys (see `ansible-vars.yml`)
- Some host- or group-specific secrets may also live under `ansible/host_vars/` or `ansible/group_vars/`

## Vault Password File

- Create a file on your machine that contains the vault password (single line)
- Example path: `/home/user/.secrets/ansible-vault-pass.txt`
- Restrict permissions: `chmod 600 /home/user/.secrets/ansible-vault-pass.txt`
- Export once per shell session:

```bash
export ANSIBLE_VAULT_PASSWORD_FILE=/home/user/.secrets/ansible-vault-pass.txt
```

The helper scripts in `./scripts/` pass `--vault-id "default@$ANSIBLE_VAULT_PASSWORD_FILE"` to Ansible.

## Initialize a New Vault File

- This repo already contains `ansible-vars.yml` with vaulted secrets. To create a new file from scratch:

```bash
ansible-vault create ansible-vars.yml
```

- You will be prompted for the vault password (or it will use `--vault-id` policy). The file opens in `$EDITOR`.
- Add YAML keys and values, save and exit.

## Encrypt or Re-Encrypt an Existing File

- To encrypt an unencrypted file or rotate encryption:

```bash
ansible-vault encrypt ansible-vars.yml
```

- Or use the provided helper:

```bash
./scripts/encrypt_ansible-vault_file.sh
```

## View and Edit the Vault

- View contents (read-only):

```bash
./scripts/view_ansible-vault_file.sh
```

- Edit with your `$EDITOR`:

```bash
ansible-vault edit ansible-vars.yml
```

## Add/Update a Secret

1. Open the vault for editing:

   ```bash
   ansible-vault edit ansible-vars.yml
   ```

2. Add or modify YAML keys, e.g.:

   ```yaml
   slack_webhook_url: https://hooks.slack.com/services/XXX/YYY/ZZZ
   my_db_password: super-secret
   ```

3. Save and exit. The file remains encrypted at rest.

## Using Vault in Playbooks and Scripts

- This repo’s scripts already inject the vault:

  ```bash
  ansible-playbook \
      -i ansible/inventories/inventory.ini \
      --vault-id="default@$ANSIBLE_VAULT_PASSWORD_FILE" \
      -e @ansible-vars.yml \
      ./ansible/playbook.yml
  ```

- Inside tasks and roles, reference variables like any other var (e.g., `{{ slack_webhook_url }}`)

## Rotating the Vault Password

1. Generate a new password and update the local password file.
2. Rekey the vault file to the new password policy:

   ```bash
   ansible-vault rekey ansible-vars.yml
   ```

3. Distribute the updated password securely to other operators.

## Common Issues

- "ERROR! Decryption failed": ensure `ANSIBLE_VAULT_PASSWORD_FILE` points to the correct file and permissions allow reading.
- Mixed encryption: confirm the file is fully encrypted (`$ANSIBLE_VAULT;1.1;AES256` header present).
- Editor not opening: set the `EDITOR` environment variable, e.g., `export EDITOR=vim`.
