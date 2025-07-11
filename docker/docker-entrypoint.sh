#!/usr/bin/env sh
set -eu

envsubst '${API_IPS_ALLOWED} ${API_PREFIX} ${OAI_PREFIX} ${PUBLIC_NAME} ${PUBLIC_PREFIX} ${PUI_IPS_ALLOWED} ${REAL_IP_CIDR} ${STAFF_NAME} ${STAFF_PREFIX} ${SUI_IPS_ALLOWED} ${UPSTREAM_HOST}' \
  < /etc/nginx/conf.d/$PROXY_TYPE-domain.conf.template > /etc/nginx/conf.d/default.conf

exec "$@"
