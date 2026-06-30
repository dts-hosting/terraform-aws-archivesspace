# ArchivesSpace proxy — public-side security hardening

This document describes the public-side anti-abuse hardening added to the
ArchivesSpace **proxy** image (`docker/`), what each piece does, how it was
tested, and how to deploy/tune it.

> Scope: **public (PUI) side only.** Nothing here touches the staff UI (`:8080`),
> the backend API (`:8089`), or OAI (`:8082`). Those remain IP-restricted and
> unchanged.

---

## 1. Why

The hosted fleet is multi-tenant: many sites **share one RDS database** (e.g.
`db-shared-p2` backs ~159 tenants). A single tenant being crawled or attacked can
therefore degrade every co-tenant on that shared database.

Observed abuse against the public faceted-browse / search endpoints:

1. **Distributed residential crawl** — hundreds of rotating IPs, each low-rate
   (so per-IP rate limits don't catch it), enumerating every facet combination.
   Distinguishing fingerprint: the wildcard arrives **double-encoded** (`q[]=%252A`)
   because the crawler re-encodes scraped hrefs.
2. **Single-IP SQL-injection scanners** (sqlmap) hammering search/browse params,
   throwing backend errors and flooding logs with stack traces (millions of log
   lines in minutes at the worst-hit tenants).
3. **Single-IP match-all enumeration** crawlers paging to `page=999`.
4. **Single-IP commercial-scanner blitz** (Acunetix/sqlmap-style) — one IP firing
   ~40k requests/hour across every discovery endpoint, mixing time-based SQLi,
   **OOB-callback** payloads (`bxss.me`, interactsh/Burp Collaborator) and **Ruby
   code-injection / SSTI** (`require'socket'`, `Socket.gethostbyname`) to canary
   for execution. Saturated the backend (502/500 storm) at the `utah` tenant.

No single signature catches all three, so the defense is **layered** and tuned to
leave normal human browsing untouched.

---

## 2. Where it lives / how it renders

| File | Role |
|------|------|
| `docker/discovery-config` | The shared rule snippet `include`d by the public discovery/search/browse `location` blocks. Shipped as a template; rendered at container start. |
| `docker/templates/single-domain.conf.template` | Public+staff on one host (staff under a prefix). Defines the zones/maps and the public `location` blocks. |
| `docker/templates/multi-domain.conf.template` | Public and staff on separate hostnames. Same defenses in the public `server {}`. |
| `docker/Dockerfile` | Copies `discovery-config` as `discovery-config.template`; sets `DISCOVERY_MAX_CONN` default. |
| `docker/docker-entrypoint.sh` | Renders the active domain template **and** `discovery-config` via `envsubst`. |

**Rendering notes**

- `limit_req_zone`, `limit_conn_zone`, `proxy_cache_path`, and `map` are
  http-context directives — they live at the top of the rendered `*-domain`
  config (http scope), **not** in `common-config` (which is included at server
  scope).
- `envsubst` only substitutes the explicit `${VAR}` allow-list in the entrypoint.
  All nginx runtime variables (`$args`, `$binary_remote_addr`, `$server_name`,
  `$http_cookie`, `$arg_page`, `$upstream_cache_status`, the `$aspace_*` map
  vars) pass through untouched.
- `discovery-config` is rendered separately so `${DISCOVERY_MAX_CONN}` can be set
  per tenant; only that one variable is substituted in it.

---

## 3. What each defense does

All of the following apply **only** to the public discovery surface: top-level
`/search`, `/objects`, `/agents`, `/subjects`, `/classifications`, `/cite`, the
cross-repo `/repositories/resources`, and per-repo
`/repositories/<id>/(resources|objects|accessions|classifications|agents|subjects|digital_objects|search)`
**list** pages. The matching regex deliberately **excludes record/detail views**
(`/repositories/N/resources/N`) and tree/waypoint loads, so opening and browsing a
finding aid is never rate-limited or cached.

| # | Mechanism | What it does | Key setting |
|---|-----------|--------------|-------------|
| 1 | `limit_conn discovery_perip` | Caps simultaneous in-flight discovery requests **per client IP**. | `24` |
| 2 | `limit_conn discovery_total` | Per-tenant circuit breaker on total concurrent discovery load — the core shared-DB protection. | `${DISCOVERY_MAX_CONN}` (default `48`) |
| 3 | SQLi block (`if $args ~* …`) | Returns `403` for sqlmap-style payloads (`sleep(`, `sysdate(`, `select(0)…`, `waitfor delay`, `extractvalue`, `information_schema`, `into outfile`, …). Stops the attack **and** the resulting stack-trace log flood. | tuned to avoid FPs |
| 3b | OOB/RCE block (second `if $args ~* …`) | Returns `403` for out-of-band-callback (`bxss.me`, `*.oast.*`, `oastify`, `burpcollaborator`, `interact.sh`) and Ruby code-injection (`Socket.gethostbyname`, `require'socket'`) payloads, plus the `n*n=` boolean-SQLi shape. Added from the `utah` blitz; net-new `403`s on shapes the time-based block misses (~6.9k there), ~zero FP. | tuned to avoid FPs |
| 4 | `limit_req search_limit` | Per-IP request rate on discovery; throttles a single aggressive client. | `120 r/m`, burst 20 |
| 5 | `limit_req doubleenc_limit` | Throttles the distributed crawl by its `%252A` fingerprint. Keyed **globally** (one bucket), so it throttles the rotating swarm in aggregate. | `30 r/m`, burst 5 |
| 6 | `limit_req deeppage_limit` | Throttles deep-offset pagination (`page >= 100`) **per IP** — a human's single "last page" click passes; sequential enumeration is throttled. | `20 r/m`, burst 10 |
| 7 | `limit_rate` | Caps per-connection bandwidth after the first 512 KB; slows bulk extraction, never affects normal small pages. | `1m` after `512k` |
| 8 | `proxy_cache` | 60s micro-cache of discovery responses; `proxy_cache_lock` collapses herds; **`proxy_cache_use_stale`** serves the last good copy during a backend error/restart (prevents 502 storms). Bypassed for sessions. | `60s` |
| 9 | `limit_req public_backstop` | Per-IP backstop on the public **catch-all** (record views, assets, `/cite`, random path-scanning the discovery rules don't cover). Generous; only single-IP floods trip it. | `20 r/s`, burst 200 |

### Design choices worth knowing

- **Concurrency, not just rate.** The distributed swarm is low-rate per IP, so
  per-IP rate limits alone miss it. `limit_conn` bounds backend load regardless of
  how many IPs rotate through — that's what actually protects the shared DB.
- **Deep-page is a throttle, not a `404`.** An earlier version hard-`404`'d
  `page >= 100`, which broke the PUI's legitimate "last page" pagination link on
  large collections. It now rate-limits instead (one click fine, enumeration not).
  A `Referer` exemption was rejected because the observed crawlers send same-site
  `Referer`s.
- **`%252A` is keyed globally.** Per-IP would never trip for a rotating swarm; a
  single shared bucket throttles the signature in aggregate. The PUI only ever
  emits `%2A`, and real traffic across 14 sampled sites produced `%252A` zero
  times, so false-positive risk is ~nil.
- **NAT-friendly thresholds.** Many users sit behind one institutional egress IP,
  so per-IP limits are set generously (perip concurrency 24, search 120 r/m,
  backstop 20 r/s). The per-tenant `limit_conn` carries the real protection.

---

## 4. Static junk-path blocklist (all paths)

Separate from the discovery-config stack above (which is scoped to the public
discovery surface), the domain templates also carry a **static denylist** that
applies to **every** path in the public server block (and, in the multi-domain
template, the staff server block too). It terminates guaranteed-bogus requests at
the edge — `return 403`/`404`, **no proxy to the backend** — so opportunistic
vulnerability scanners never reach the Rails PUI/staff app.

It has four parts (all `location` regexes, evaluated before the proxy locations):

| Match | Action | Catches |
|-------|--------|---------|
| `wp-admin\|wp-includes\|wp-content\|wp-json\|xmlrpc.php\|wp-login.php\|…` | `deny all` (403) | WordPress probes |
| `\.(php\|asp\|aspx\|cgi\|action\|dll\|sh\|bat\|exe\|jsp\|jhtml\|jsa\|cfm\|shtml)$` | `404` | server-side script extensions ArchivesSpace never serves |
| `^/(webdav\|sling\|adminer\|…\|geoserver\|wls-wsat\|autodiscover\|owa\|webui\|versa\|remote\|scadabr\|nifi\|pandora_console\|nidp\|officescan\|boaform\|mailinspector\|sap/bc)` | `403` | known scanner / appliance / CVE-login roots |
| `javax\.faces\.resource\|WEB-INF\|META-INF` | `403` | JSF / Java path-traversal |

**Why this is value-limited and safe to be aggressive.** ArchivesSpace serves no
PHP/ASPX/CGI/JSP and has no WordPress or appliance routes, so none of these can
actually be exploited and the block is **false-positive-free**. The benefit is
therefore **backend offload + log hygiene** (each blocked request is one fewer
Rails 404 to render and log across ~159 shared-DB tenants), *not* breach
prevention. No observed probe has ever succeeded — the only `200` seen from a
scanner was a plain `GET /` to the home page.

**Recently extended from observed fleet traffic.** The `wp-json`, the
`exe/jsp/jhtml/jsa/cfm/shtml` extensions, and the `owa..sap/bc` root group were
added after multi-site logs showed those probe families (Exchange OWA, Fortinet
`/remote`, Versa, ScadaBR, Apache NiFi, Pandora FMS, NetIQ `/nidp`, Trend Micro
OfficeScan, `/boaform`, mailinspector, SAP `/sap/bc`, and the `/start.<ext>`
family) slipping past the extension filter and reaching the backend as `404`s.
This list is a **maintained denylist** — extend it as new probe families appear.
The AWS WAF (next section) is the fleet-wide complement and the better place for
blocking that should apply uniformly across all tenants' ALBs.

---

## 5. Interaction with the AWS WAF (pre-existing)

These ALBs sit behind `aspace-hosting-production-REGIONAL-web-acl`, which already
implements bot management. The nginx hardening **complements** it:

- **WAF JS-Challenge** fires on `/repositories/*`, `/agents/{corporate_entities,
  families,people,software}/`, and any query containing `filter_fields` /
  `filter_term`. Real browsers solve it transparently; non-browser clients get a
  `202` interstitial. (This is why `curl` can't directly test those paths.)
- **Privileged UAs bypass the challenge** (allow rule, evaluated first):
  `Googlebot`, `bingbot`, `ArchiveGridCrawler`, `ArchivesWest`, `ArchivesSnake`,
  `ArchivesSpaceClient`, `pyoaiharvester`, monitors, etc. — so SEO and archival
  harvesting are preserved.
- **Banned UAs are blocked** (`GPTBot`, `ChatGPT`, `Claude`, `Amazonbot`,
  `Ahrefs`, `Semrush`, `Perplexity`, `Yandex`, `Baidu`, …) with a `403`.
- The PUI's own AJAX to `/repositories` (`X-Requested-With: XMLHttpRequest`) is
  allowed, so tree/waypoint lazy-loading works.

**Net layering:**
- Challenged paths (`/repositories/*`, faceted queries): WAF challenge is gate #1;
  nginx rules are gate #2 (catch UA-spoofers and anything that solves the
  challenge).
- Non-challenged paths (`/search`, `/objects`, `/agents`, `/subjects`): nginx
  rules are the primary defense.

> The WAF allow-list is **UA-based and therefore spoofable** (a client claiming
> `Googlebot` bypasses the challenge). The nginx layer is the backstop for that.
> If spoofing becomes a problem, switch the privileged-bot allow to AWS WAF
> verified-bot validation (Bot Control is already enabled).

---

## 6. How it was tested

### Local (every iteration)

Built the image and validated against the real `nginx` base:

- `nginx -t` passes for **both** single- and multi-domain renders.
- Container boots; `/health` → 200; cache dir created.
- **Functional tests** (single-domain, multi-domain, and `/public/`-prefix env):
  - SQLi payloads (exact strings from the vcu/montclair logs) → `403`.
  - Legit searches that look SQL-ish → **not** blocked: `select committee`,
    `union select committee`, `trade union selected papers`, `WaitForIt`,
    `sleep apnea study`, `Smith (John) papers`, `minutes (1990-2000)`.
  - Per-repo browse/search → covered (matches discovery rules); record views and
    `…/tree/root` → **not** matched (pass through untouched).
  - Deep page (`page=480`, single) → passes; 40 concurrent deep pages → throttled.
  - `%252A` flood → throttled after burst; normal `%2A` browse → passes.
  - `public_backstop`: 40 concurrent assets (real page load) → all pass; 300
    concurrent random paths (scanner) → ~burst pass, remainder `503`.
  - `DISCOVERY_MAX_CONN` rendering: default → `48`, override → `96`.
  - Staff/API paths → **not** affected (e.g. staff-side SQLi → passthrough, not
    `403`).

### Live (asqa.lyrtech.org)

- Verified the `:secure` image deployed and serving (ECS task def `qa:98`, healthy
  ALB target).
- Confirmed our rules active on the non-challenged surface: top-level SQLi →
  `403 by nginx`; cache active (`x-cache-status`).
- Identified that `/repositories/*` and faceted queries are behind the WAF
  JS-challenge (so `curl` gets `202` there; a browser/privileged-UA reaches nginx).
- **Normal-user session** (browser UA on open paths; privileged UA to pass the
  challenge on `/repositories`/faceted paths) — every action returned **200** with
  real content, no `403`/`500`/`503`:
  home, keyword search, multi-word search, results page 2, browse subjects/agents,
  repository landing, browse all collections, view a collection record, load the
  finding-aid tree, **apply a facet filter**, browse digital objects. (A `404` on a
  non-existent agent id is correct behavior, not a block.)
  → confirms the defenses do **not** false-positive on legitimate use.

### Re-verification script

`asqa-defense-tests.sh` (kept outside the repo) runs the suite against a live host:

```sh
./asqa-defense-tests.sh                          # gentle: normal ops + FP + single-shot efficacy
FLOOD=1 ./asqa-defense-tests.sh                  # + throttle tests (noisy)
WAF_TOKEN=<aws-waf-token> FLOOD=1 ./asqa-defense-tests.sh   # also exercise WAF-challenged paths
```

Get `WAF_TOKEN` by loading any challenged page in a browser once and copying the
`aws-waf-token` cookie (valid for the challenge immunity window).

---

## 7. Deploying

1. **Build + push the proxy image** (from a checkout that includes
   `docker/discovery-config`):
   ```sh
   cd docker
   export ASPACE_PROXY_ECR_IMG=<ecr-repo>/aspace-proxy:<tag>
   ./build_and_push.sh
   ```
   Prefer a **unique tag** (e.g. `:secure`, a date, or a git sha) over `:latest`
   so ECS deploys deterministically.
2. **Point the tenant at it** (`proxy_img` in the tenant tfvars) and
   **`terraform apply`** — editing the tfvar alone does not redeploy; the apply
   updates the ECS task definition and rolls a new task.
3. **Verify the cut-over** (flips once the new task serves):
   ```sh
   curl -sD- -o/dev/null 'https://<host>/repositories/resources?q%5B%5D=x' | grep -i x-cache-status   # present
   curl -so/dev/null -w '%{http_code}\n' 'https://<host>/repositories/2/search?q=sleep(15)'           # 403 (via browser/privileged UA past the WAF)
   ```

> ⚠️ `build_and_push.sh` builds from the local filesystem, so a local build picks
> up `discovery-config`. If a CI pipeline builds from a **git checkout**, ensure
> `discovery-config` is committed/available there or `COPY` will fail.

---

## 8. Tuning knobs

| Knob | Location | Default | Raise if… |
|------|----------|---------|-----------|
| `DISCOVERY_MAX_CONN` (per-tenant concurrency) | task env / Dockerfile | `48` | a busy/large (xlarge) tenant returns `503` under legit peaks |
| `discovery_perip` | `discovery-config` | `24` | NAT'd institutions hit it |
| `search_limit` rate | templates | `120 r/m` | heavy legit shared-IP traffic |
| `public_backstop` rate/burst | templates / catch-all | `20 r/s` / 200 | a large shared egress is throttled |
| `deeppage_limit` rate, page threshold | templates / `discovery-config` map | `20 r/m`, `page>=100` | tune how aggressively deep paging is throttled |
| `doubleenc_limit` rate | templates | `30 r/m` | (rarely needed) |
| cache TTL | `discovery-config` | `60s` | raise to offload backend more |

---

## 9. Out of scope / follow-ups

- **`/objects?q=…` without `limit` → 500.** An **upstream PUI bug**
  (`objects_controller.rb:31` calls `.include?` on a `nil` `params[:limit]` when
  `q` is present but `limit` is absent). It is **not** caused by the proxy/WAF/our
  changes, and has ~zero real-world impact: every PUI link/form includes `limit`,
  and 0 of ~2,000 sampled real `/objects` requests omitted it — only hand-built
  URLs trigger it. Optional one-line hardening:
  `params[:limit] ||= 'digital_object,archival_object'`.
- **WAF decisions (operator):** consider verified-bot validation instead of a
  spoofable UA allow-list; review whether `loc.gov`, `Applebot`, `GoogleOther` are
  intentionally on the banned list; `LinkCheck` appears in both the privileged and
  banned lists (privileged wins).
- **Per-tenant DB connection caps** would contain this class of incident at the
  database layer (structurally), independent of nginx.
