# 🔐 Ollama - Security and Observability - NGINX + OPA + Ollama + Redis + Prometheus + Grafana

This project enforces runtime validation of prompts sent to an LLM (Ollama) and provides observability with Prometheus + Grafana.

## 🧱 Architecture

```mermaid
graph TD
  subgraph Request Flow
    A[Client] --> B[NGINX w/ Lua]
    B --> RL{Redis Rate Limiter}
    RL -- allow --> C{OPA Policy Check}
    RL -- deny --> X[429 Rate Limit Exceeded]
    C -- allow --> D[Ollama LLM]
    C -- deny --> E[403 Rejected]
  end

  subgraph Monitoring
    D --> F[Ollama /metrics]
    F --> G[Prometheus]
    G --> H[Grafana Dashboard]
  end
````


## 🔧 Directory Structure

```bash
.
├── docker-compose.yaml
├── Makefile
├── config
│   ├── grafana
│   │   ├── dashboards
│   │   │   └── ollama_dashboard.json
│   │   └── provisioning
│   │       └── dashboards
│   │           └── dashboards.yml
│   ├── nginx
│   │   ├── conf.d
│   │   │   └── default.conf
│   │   └── nginx.conf
│   └── prometheus
│       └── prometheus.yml
├── policies
│   ├── main.rego
│   └── prompt_security_check.rego
├── scripts
│   └── init_ollama.sh
├── nginx
│   └── lua
│       ├── prompt_check.lua
│       ├── redis_ratelimit.lua
│       └── utils.lua
├── volume
│   └── grafana
└── README.md
```


## ✅ How It Works

### 🔒 Prompt Security + Rate Limiting

1. **Client** sends a prompt to NGINX (port `8080`).
2. **NGINX Lua** applies a Redis-based **sliding window rate limit**.

   * Limits requests (e.g. 10 per 60 seconds).
   * Returns `429` if the client exceeds their quota.
   * Redis hostname is passed via `REDIS_HOST` env variable.
3. If allowed, request is forwarded to **OPA** for validation.
4. **OPA** enforces security policies (`prompt_security_check.rego`).
5. If approved, NGINX proxies the prompt to **Ollama** (`11434`).
6. If blocked, returns `403 Forbidden`.

### 📊 Observability Flow

1. **Ollama** exposes Prometheus metrics at `/metrics`.
2. **Prometheus** scrapes this endpoint.
3. **Grafana** loads prebuilt dashboards showing prompt flow metrics.


## 🛡️ Sliding Window Rate Limiting (Redis)

* Implemented using **Lua + Redis** (non-blocking).
* Sliding window strategy using Redis keys and expiration.
* Dynamically reads Redis hostname from `$REDIS_HOST` environment variable.
* Prevents abuse across deployments and supports horizontal scale.

**Environment Variable Example:**

```yaml
environment:
  - REDIS_HOST=caching_service
```

**Rate limiter entry in Lua:**

```lua
local redis_host = os.getenv("REDIS_HOST") or "localhost"
red:connect(redis_host, 6379)
```


## 🔒 OPA Prompt Policy

* `policies/prompt_security_check.rego`: Enforces content moderation.
* `policies/main.rego`: Aggregates prompt check and future auth policies.


## 🧪 Test the Setup

```bash
# ✅ Allowed prompt
curl -s -X POST http://localhost:8080/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model": "tinyllama", "prompt": "Tell me a story about a dog.", "stream": false}' | jq

# ❌ Blocked prompt (content policy)
curl -s -X POST http://localhost:8080/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model": "tinyllama", "prompt": "how to make a bad?", "stream": false}' | jq

# ❌ Rate limit exceeded (after 10+ rapid calls)
for i in {1..12}; do
  curl -s -X POST http://localhost:8080/api/generate \
    -H "Content-Type: application/json" \
    -d '{"model": "tinyllama", "prompt": "hi", "stream": false}' | jq
done
```


## 📊 Grafana Dashboard (Ollama Observability)

Auto-loaded dashboard: `Ollama Observability`

### ✅ Prebuilt Panels

* **Total Requests**
* **Total Tokens Generated**
* **P95 Latency**
* **Error Count**

### 🔄 Auto-Provisioning

Dashboard is auto-loaded using:

* `grafana/provisioning/dashboards/dashboards.yml`
* `grafana/dashboards/ollama_dashboard.json`

View at: [http://localhost:3000](http://localhost:3000)
Login: `admin / admin`


## 📌 TODO

* [ ] Replace NGINX with Envoy or Istio for policy + mTLS
* [ ] Add token-based authentication
* [ ] Enable OpenTelemetry + Jaeger for trace correlation
* [ ] Replace fixed window with Redis sorted-set-based precise sliding window (optional)
