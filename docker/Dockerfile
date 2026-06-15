FROM --platform=linux/amd64 nginx

ENV API_IPS_ALLOWED="allow 0.0.0.0/0" \
    API_PREFIX="/api/" \
    OAI_PREFIX="/oai" \
    PROXY_TYPE="single" \
    PUBLIC_ENABLED="false" \
    PUBLIC_NAME="" \
    PUBLIC_PREFIX="/" \
    PUI_IPS_ALLOWED="allow 0.0.0.0/0" \
    REAL_IP_CIDR="10.0.0.0/16" \
    STAFF_NAME="" \
    STAFF_PREFIX="/" \
    UPSTREAM_HOST="localhost"

COPY templates/*-domain.conf.template /etc/nginx/conf.d/
COPY common-config /etc/nginx/

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
