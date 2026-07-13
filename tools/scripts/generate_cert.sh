#!/usr/bin/env bash
## tools/scripts/generate_cert.sh — certificado autoassinado para o serve_web.py.
## iOS Safari exige HTTPS para Web Share API, PWA e afins mesmo em rede local.
## Gera tools/cert.pem + tools/key.pem válidos para localhost e o IP da máquina.
set -euo pipefail

cd "$(dirname "$0")/.."

# IP local (Linux: ip route; fallback: hostname -I; Windows git-bash: ipconfig)
IP=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' || true)
[[ -z "$IP" ]] && IP=$(hostname -I 2>/dev/null | awk '{print $1}' || true)
[[ -z "$IP" ]] && IP=$(ipconfig 2>/dev/null | grep -m1 "IPv4" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' || true)
[[ -z "$IP" ]] && IP="127.0.0.1"

echo "Gerando certificado para localhost e $IP..."

cat > openssl.cnf <<EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = $IP

[v3_req]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
IP.1 = 127.0.0.1
IP.2 = $IP
EOF

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout key.pem -out cert.pem -config openssl.cnf
rm openssl.cnf

echo "✅ tools/cert.pem + tools/key.pem prontos (gitignored — *.pem)."
echo "   No celular, aceite o aviso de certificado autoassinado."
