#!/usr/bin/env bash
# Active l'authentification "Forms" sur Sonarr et Prowlarr et génère le hash
# basic auth Traefik (variable ADMIN_BASICAUTH dans .env).
# Le mot de passe est saisi au clavier et n'est jamais affiché ni stocké en clair.
set -euo pipefail
cd "$(dirname "$0")/.."

read -rp "Nom d'utilisateur : " USER_NAME
read -rsp "Mot de passe : " PASS; echo
read -rsp "Confirmez : " PASS2; echo
[ "$PASS" = "$PASS2" ] || { echo "Les mots de passe ne correspondent pas."; exit 1; }
[ ${#PASS} -ge 12 ] || { echo "12 caractères minimum."; exit 1; }

set_forms_auth() { # $1=nom $2=port $3=version api $4=config.xml
  local key cfg
  key=$(grep -oP '(?<=<ApiKey>)[^<]+' "$4")
  cfg=$(curl -sf -H "X-Api-Key: $key" "http://127.0.0.1:$2/api/$3/config/host")
  echo "$cfg" | jq --arg u "$USER_NAME" --arg p "$PASS" \
    '.authenticationMethod="forms" | .authenticationRequired="enabled" | .username=$u | .password=$p | .passwordConfirmation=$p' \
  | curl -sf -o /dev/null -X PUT -H "X-Api-Key: $key" -H 'Content-Type: application/json' \
      --data @- "http://127.0.0.1:$2/api/$3/config/host/$(echo "$cfg" | jq -r .id)"
  echo "✓ $1 : authentification par formulaire activée"
}

set_forms_auth Sonarr 8989 v3 sonarr/data/config.xml
set_forms_auth Prowlarr 9696 v1 prowlarr/data/config.xml

HASH="$USER_NAME:$(openssl passwd -apr1 "$PASS")"
touch .env && chmod 600 .env
sed -i '/^ADMIN_BASICAUTH=/d' .env
printf "ADMIN_BASICAUTH='%s'\n" "$HASH" >> .env
echo "✓ Hash basic auth Traefik écrit dans .env (ADMIN_BASICAUTH)"
echo "Redémarrez Sonarr et Prowlarr pour appliquer : docker restart sonarr prowlarr"
