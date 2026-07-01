#!/usr/bin/env bash
#
# Generates the X.509 material for the svc_etcd <-> {svc_coredns,
# external-dns on red/green} mTLS triangle.
#
# Output: tmp/etcd-pki/   (gitignored, chmod 700)
#   ca.pem, ca-key.pem
#   etcd-server.pem,        etcd-server-key.pem        (SAN: 192.168.60.188 + melissa.host + svc_etcd + localhost)
#   coredns-client.pem,     coredns-client-key.pem     (CN=coredns)
#   extdns-red-client.pem,  extdns-red-client-key.pem  (CN=external-dns-red)
#   extdns-green-client.pem,extdns-green-client-key.pem(CN=external-dns-green)
#
# Operator workflow (run once, regenerate on rotation):
#
#   ./scripts/gen_etcd_pki.sh
#
#   # 1. Vault the deerhide-side material into ansible-vars.yml under the
#   #    keys consumed by ansible/roles/svc_coredns/tasks/setup_etcd_pki.yml:
#   #      etcd_ca_pem
#   #      etcd_server_pem
#   #      etcd_server_key
#   #      coredns_etcd_client_pem
#   #      coredns_etcd_client_key
#   #
#   #    For each value, paste it into ansible-vars.yml as plaintext, then
#   #    encrypt in place:
#   #      ./scripts/encrypt_ansible-vault_file.sh etcd_ca_pem
#   #      ./scripts/encrypt_ansible-vault_file.sh etcd_server_pem
#   #      ... etc.
#
#   # 2. Hand the external-dns slices to velmios-infrastructure SOPS:
#   #      tmp/etcd-pki/ca.pem
#   #      tmp/etcd-pki/extdns-red-client.pem      + extdns-red-client-key.pem
#   #      tmp/etcd-pki/extdns-green-client.pem    + extdns-green-client-key.pem
#   #
#   #    See secrets/external-dns/README.md in that repo for the SOPS +
#   #    kubeseal sealing flow.
#
#   # 3. Wipe tmp/etcd-pki when done:
#   #      rm -rf tmp/etcd-pki

set -euo pipefail

if ! command -v openssl >/dev/null 2>&1; then
  echo "openssl is required" >&2
  exit 1
fi

OUT="${OUT:-tmp/etcd-pki}"
DAYS_CA="${DAYS_CA:-3650}"
DAYS_LEAF="${DAYS_LEAF:-825}"

ETCD_SERVER_DNS=("melissa.host" "svc_etcd" "localhost")
ETCD_SERVER_IPS=("192.168.60.188" "127.0.0.1")

mkdir -p "$OUT"
chmod 700 "$OUT"

cat > "$OUT/openssl.cnf" <<'EOF'
[req]
default_bits       = 4096
prompt             = no
distinguished_name = req_dn
encrypt_key        = no

[req_dn]
O  = deerhide
OU = velmios-dns

[v3_ca]
basicConstraints     = critical, CA:TRUE
keyUsage             = critical, keyCertSign, cRLSign
subjectKeyIdentifier = hash

[v3_server]
basicConstraints     = critical, CA:FALSE
keyUsage             = critical, digitalSignature, keyEncipherment
extendedKeyUsage     = serverAuth, clientAuth
subjectKeyIdentifier = hash

[v3_client]
basicConstraints     = critical, CA:FALSE
keyUsage             = critical, digitalSignature, keyEncipherment
extendedKeyUsage     = clientAuth
subjectKeyIdentifier = hash
EOF

# --- CA -----------------------------------------------------------------
if [[ ! -f "$OUT/ca-key.pem" ]]; then
  echo "[gen_etcd_pki] Generating CA"
  openssl genrsa -out "$OUT/ca-key.pem" 4096
  openssl req -x509 -new -nodes -key "$OUT/ca-key.pem" \
    -days "$DAYS_CA" -sha256 \
    -subj "/O=deerhide/OU=velmios-dns/CN=deerhide-velmios-dns-ca" \
    -extensions v3_ca -config "$OUT/openssl.cnf" \
    -out "$OUT/ca.pem"
fi

issue_leaf() {
  local name="$1" cn="$2" ext="$3" san_block="$4"
  local key="$OUT/$name-key.pem"
  local crt="$OUT/$name.pem"
  local csr="$OUT/$name.csr"
  local cnf="$OUT/$name.cnf"

  cat > "$cnf" <<EOF
[req]
default_bits       = 4096
prompt             = no
distinguished_name = req_dn
req_extensions     = v3_req
encrypt_key        = no

[req_dn]
O  = deerhide
OU = velmios-dns
CN = $cn

[v3_req]
basicConstraints = critical, CA:FALSE
keyUsage         = critical, digitalSignature, keyEncipherment
$( [[ "$ext" == "v3_server" ]] && echo "extendedKeyUsage = serverAuth, clientAuth" )
$( [[ "$ext" == "v3_client" ]] && echo "extendedKeyUsage = clientAuth" )
$san_block
EOF

  echo "[gen_etcd_pki] Issuing $name (CN=$cn)"
  openssl genrsa -out "$key" 4096
  openssl req -new -key "$key" -out "$csr" -config "$cnf"
  openssl x509 -req -in "$csr" -CA "$OUT/ca.pem" -CAkey "$OUT/ca-key.pem" \
    -CAcreateserial -out "$crt" -days "$DAYS_LEAF" -sha256 \
    -extfile "$cnf" -extensions v3_req
  rm -f "$csr"
}

# --- etcd server --------------------------------------------------------
SAN_LINES="subjectAltName = @alt_names\n[alt_names]"
i=1
for d in "${ETCD_SERVER_DNS[@]}"; do
  SAN_LINES+=$'\n'"DNS.$i = $d"
  i=$((i+1))
done
i=1
for ip in "${ETCD_SERVER_IPS[@]}"; do
  SAN_LINES+=$'\n'"IP.$i = $ip"
  i=$((i+1))
done

issue_leaf "etcd-server" "etcd-server" "v3_server" "$(printf "%b" "$SAN_LINES")"

# --- clients ------------------------------------------------------------
issue_leaf "coredns-client"      "coredns"            "v3_client" ""
issue_leaf "extdns-red-client"   "external-dns-red"   "v3_client" ""
issue_leaf "extdns-green-client" "external-dns-green" "v3_client" ""

chmod 600 "$OUT"/*-key.pem
rm -f "$OUT"/*.cnf "$OUT"/*.srl

echo
echo "[gen_etcd_pki] Done. Material in $OUT/"
ls -la "$OUT"
