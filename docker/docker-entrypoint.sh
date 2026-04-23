#!/usr/bin/env sh
set -eu

if [ "$PUBLIC_PREFIX" != "/" ]; then
  REDIRECT_BLOCK="location = ${PUBLIC_PREFIX%/} { return 301 \$scheme://\$host$PUBLIC_PREFIX\$is_args\$args; }"
else
  REDIRECT_BLOCK=""
fi

export REDIRECT_BLOCK

envsubst '${API_IPS_ALLOWED} ${API_PREFIX} ${OAI_PREFIX} ${PUBLIC_NAME} ${PUBLIC_PREFIX} ${PUI_IPS_ALLOWED} ${REAL_IP_CIDR} ${STAFF_NAME} ${STAFF_PREFIX} ${SUI_IPS_ALLOWED} ${UPSTREAM_HOST} ${REDIRECT_BLOCK}' \
  < /etc/nginx/conf.d/$PROXY_TYPE-domain.conf.template > /etc/nginx/conf.d/default.conf
exec "$@"
