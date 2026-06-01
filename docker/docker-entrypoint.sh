#!/usr/bin/env sh
set -eu

if [ "$PUBLIC_PREFIX" != "/" ]; then
  REDIRECT_BLOCK="rewrite ^${PUBLIC_PREFIX%/}$ $PUBLIC_PREFIX permanent;"
  ROOT_REDIRECT_BLOCK="rewrite ^/$ $PUBLIC_PREFIX permanent;"
else
  REDIRECT_BLOCK=""
  ROOT_REDIRECT_BLOCK=""
fi

export REDIRECT_BLOCK
export ROOT_REDIRECT_BLOCK

envsubst '${API_IPS_ALLOWED} ${API_PREFIX} ${OAI_PREFIX} ${PUBLIC_NAME} ${PUBLIC_PREFIX} ${PUI_IPS_ALLOWED} ${REAL_IP_CIDR} ${STAFF_NAME} ${STAFF_PREFIX} ${SUI_IPS_ALLOWED} ${UPSTREAM_HOST} ${REDIRECT_BLOCK} ${ROOT_REDIRECT_BLOCK}' \
  < /etc/nginx/conf.d/$PROXY_TYPE-domain.conf.template > /etc/nginx/conf.d/default.conf
exec "$@"
