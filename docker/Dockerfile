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

# Per-tenant concurrency ceiling for public discovery/browse/search (consumed by
# discovery-config via envsubst in the entrypoint). Default suits a medium
# tenant; override per instance_spec from Terraform for large/xlarge sites.
ENV DISCOVERY_MAX_CONN="48"

COPY templates/*-domain.conf.template /etc/nginx/conf.d/
COPY common-config /etc/nginx/
# Public-side anti-abuse rule snippet `include`d by the discovery/search/browse
# locations in both domain templates. Shipped as a .template; the entrypoint
# renders it with envsubst (only ${DISCOVERY_MAX_CONN} is substituted) to
# /etc/nginx/discovery-config. Its many nginx $variables are passed through
# verbatim and evaluated at request time.
COPY discovery-config /etc/nginx/discovery-config.template

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
