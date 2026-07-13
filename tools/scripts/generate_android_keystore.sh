#!/usr/bin/env bash
## tools/scripts/generate_android_keystore.sh
##
## Gera a keystore de RELEASE do Android e mostra os comandos para
## registrar os GitHub Secrets que o CI usa para assinar o APK.
##
## ⚠️  IMPORTANTE:
##   - Rode este script VOCÊ MESMO (a senha é sua, não deve ficar em logs).
##   - Guarde o arquivo .keystore em local seguro (ex: gerenciador de senhas).
##     Perder a keystore = nunca mais atualizar o app na Play Store.
##   - NUNCA commite a keystore (o .gitignore já bloqueia *.keystore).
##
## Uso:
##   ./tools/scripts/generate_android_keystore.sh

set -euo pipefail

KS_FILE="dotway-release.keystore"
KS_ALIAS="dotway"

if [[ -f "$KS_FILE" ]]; then
  echo "❌ $KS_FILE já existe — não vou sobrescrever."
  exit 1
fi

echo "Gerando keystore de release ($KS_FILE, alias '$KS_ALIAS', RSA 2048, 10000 dias)…"
echo "O keytool vai pedir a senha e os dados do certificado:"
echo

keytool -genkeypair -v \
  -keystore "$KS_FILE" \
  -alias "$KS_ALIAS" \
  -keyalg RSA -keysize 2048 -validity 10000

echo
echo "✅ Keystore gerada: $KS_FILE"
echo
echo "Agora registre os GitHub Secrets (o CI passa a assinar release automaticamente):"
echo
echo "  base64 -w0 $KS_FILE | gh secret set ANDROID_KEYSTORE_B64 -R SEU_USUARIO/SEU_REPO"
echo "  gh secret set ANDROID_KEYSTORE_USER -R SEU_USUARIO/SEU_REPO --body \"$KS_ALIAS\""
echo "  gh secret set ANDROID_KEYSTORE_PASS -R SEU_USUARIO/SEU_REPO   # cola a senha quando pedir"
echo
echo "Depois disso, todo push na main gera APK de RELEASE assinado."
echo "⚠️  Faça backup da keystore AGORA (fora do repositório)."
