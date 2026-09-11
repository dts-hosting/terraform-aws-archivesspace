#!/usr/bin/env sh
set -eu

# Only redirect to the public prefix when the PUI is enabled, to avoid hijacking / to a dead /public/ upstream.
if [ "$PUBLIC_ENABLED" = "true" ] && [ "$PUBLIC_PREFIX" != "/" ]; then
  REDIRECT_BLOCK="rewrite ^${PUBLIC_PREFIX%/}$ $PUBLIC_PREFIX permanent;"
  ROOT_REDIRECT_BLOCK="rewrite ^/$ $PUBLIC_PREFIX permanent;"
else
  REDIRECT_BLOCK=""
  ROOT_REDIRECT_BLOCK=""
fi

export REDIRECT_BLOCK
export ROOT_REDIRECT_BLOCK

# Single-domain mode shares one server block between UIs; root/unprefixed assets must route to whichever UI is actually running, since app_public never starts when PUBLIC_ENABLED is false.
if [ "$PUBLIC_ENABLED" = "true" ]; then
  ROOT_UPSTREAM="app_public"
else
  ROOT_UPSTREAM="app_staff"
fi
export ROOT_UPSTREAM

envsubst '${API_IPS_ALLOWED} ${API_PREFIX} ${OAI_PREFIX} ${PUBLIC_NAME} ${PUBLIC_PREFIX} ${PUI_IPS_ALLOWED} ${REAL_IP_CIDR} ${ROOT_UPSTREAM} ${STAFF_NAME} ${STAFF_PREFIX} ${SUI_IPS_ALLOWED} ${UPSTREAM_HOST} ${REDIRECT_BLOCK} ${ROOT_REDIRECT_BLOCK}' \
  < /etc/nginx/conf.d/$PROXY_TYPE-domain.conf.template > /etc/nginx/conf.d/default.conf

# Render the anti-abuse include; only DISCOVERY_MAX_CONN is substituted, nginx runtime vars pass through untouched.
envsubst '${DISCOVERY_MAX_CONN}' \
  < /etc/nginx/discovery-config.template > /etc/nginx/discovery-config

exec "$@"
