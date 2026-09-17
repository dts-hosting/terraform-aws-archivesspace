FROM nginx

# Pin to 1 worker so limit_req_zone's shared memory enforces a true global rate instead of ~N x rate across N workers.
RUN sed -i 's/^worker_processes.*/worker_processes 1;/' /etc/nginx/nginx.conf

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

# Per-tenant concurrency ceiling for public discovery/browse/search; override per instance_spec for large/xlarge sites.
ENV DISCOVERY_MAX_CONN="48"

COPY templates/*-domain.conf.template /etc/nginx/conf.d/
COPY common-config /etc/nginx/
# Anti-abuse rule snippet included by the discovery/search/browse locations; rendered via envsubst at container start.
COPY discovery-config /etc/nginx/discovery-config.template

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
