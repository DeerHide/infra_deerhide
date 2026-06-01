# CoreDNS + etcd (velmios.io zone)

Melissa runs three coupled containers managed by the `svc_coredns` role:

| Container    | Image                       | Role                                                      |
| ------------ | --------------------------- | --------------------------------------------------------- |
| `svc_etcd`   | `quay.io/coreos/etcd:v3.5.x` | Single-node etcd v3 datastore, mTLS-only client listener |
| `svc_coredns`| `coredns/coredns:latest`    | LAN resolver. `velmios.io` zone is backed by `svc_etcd`   |

```
                                +-------------------------+
                                |   external-dns (red)    |
                                |   external-dns (green)  |
                                +-----------+-------------+
                                            | mTLS write   /skydns/...
                                            v
+----------------+    mTLS read    +-------------------+
|  svc_coredns   | <-------------- |     svc_etcd      |
|  velmios.io {  |                 |  client-cert-auth |
|    etcd ...    |                 |  :2379 (TLS-only) |
|  }             |                 +-------------------+
+----------------+
```

`deerhide.run` is still served from the static `hosts {}` block in
[`ansible/roles/svc_coredns/templates/Corefile.j2`](../ansible/roles/svc_coredns/templates/Corefile.j2). Only `velmios.io` moved to etcd.

## PKI

The etcd <-> CoreDNS <-> external-dns triangle is mTLS-only. There is no
RBAC username/password fallback. Cert layout:

| Cert                | CN                  | EKU                  | Used by                                |
| ------------------- | ------------------- | -------------------- | -------------------------------------- |
| `ca.pem`            | `deerhide-velmios-dns-ca` | (CA)            | All sides as the trust anchor          |
| `etcd-server.pem`   | `etcd-server`       | serverAuth, clientAuth | `svc_etcd` listener cert (SAN: 192.168.60.188, melissa.host) |
| `coredns-client.pem`| `coredns`           | clientAuth           | CoreDNS etcd plugin on melissa         |
| `extdns-red-client.pem` | `external-dns-red` | clientAuth      | external-dns Deployment in `red` cluster |
| `extdns-green-client.pem` | `external-dns-green` | clientAuth  | external-dns Deployment in `green` cluster |

### One-shot generation

```bash
./scripts/gen_etcd_pki.sh
ls tmp/etcd-pki/
```

Outputs land in `tmp/etcd-pki/` (gitignored, `chmod 700`). Re-running the
script keeps the existing CA but reissues every leaf if you delete them
first.

### Vaulting the deerhide-side material

`ansible/roles/svc_coredns/tasks/setup_etcd_pki.yml` consumes five
top-level variables. Paste each plaintext into `ansible-vars.yml`, then
encrypt in place with the helper:

```bash
./scripts/encrypt_ansible-vault_file.sh etcd_ca_pem
./scripts/encrypt_ansible-vault_file.sh etcd_server_pem
./scripts/encrypt_ansible-vault_file.sh etcd_server_key
./scripts/encrypt_ansible-vault_file.sh coredns_etcd_client_pem
./scripts/encrypt_ansible-vault_file.sh coredns_etcd_client_key
```

| Variable                   | Source file in `tmp/etcd-pki/` |
| -------------------------- | ------------------------------ |
| `etcd_ca_pem`              | `ca.pem`                       |
| `etcd_server_pem`          | `etcd-server.pem`              |
| `etcd_server_key`          | `etcd-server-key.pem`          |
| `coredns_etcd_client_pem`  | `coredns-client.pem`           |
| `coredns_etcd_client_key`  | `coredns-client-key.pem`       |

When the playbook runs against `melissa`, `setup_etcd_pki.yml` lays the
files down at `{{ etcd_tls_dir }}` and `{{ coredns_tls_dir }}` (defined
in [`ansible/group_vars/all/coredns.yml`](../ansible/group_vars/all/coredns.yml)).

### Handing the external-dns slice to velmios

The four files needed by `velmios-infrastructure` are:

```
tmp/etcd-pki/ca.pem
tmp/etcd-pki/extdns-red-client.pem      tmp/etcd-pki/extdns-red-client-key.pem
tmp/etcd-pki/extdns-green-client.pem    tmp/etcd-pki/extdns-green-client-key.pem
```

In the velmios repo, paste them into the SOPS source
`secrets/external-dns/etcd-client.sops.yaml` and re-seal per cluster
with `secrets/scripts/seal.sh red` and `... green`. See that repo's
[`secrets/external-dns/README.md`](../../laelidona/velmios-infrastructure/secrets/external-dns/README.md)
(if present) or the platform README. The Argo CD `sealed-secrets`
ApplicationSet reconciles the result.

### Cleanup

```bash
rm -rf tmp/etcd-pki
```

## Rotation

1. Delete the leaf cert(s) you want to rotate from `tmp/etcd-pki/` and
   re-run `./scripts/gen_etcd_pki.sh` (CA is preserved when `ca-key.pem`
   is still present).
2. Re-vault the changed deerhide variables and reseal the changed
   external-dns secrets in velmios.
3. Re-apply the playbook on `melissa` and re-sync the affected Argo CD
   apps.

To rotate the CA, delete the whole `tmp/etcd-pki/` directory, regenerate
everything, and re-vault / re-seal all five entries on each side.
