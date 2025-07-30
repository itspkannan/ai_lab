# 🔐 Ollama - Security and Observability - NGINX + OPA + Ollama + Observability

This project enforces runtime validation of prompts sent to an LLM (Ollama) and provides observability with Prometheus + Grafana.

## 🧱 Architecture

```mermaid
graph TD
  subgraph Request Flow
    A[Client] --> B[NGINX w/ Lua]
    B --> C{OPA Policy Check}
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
├── volume
│   └── grafana
└── README.md
```


## ✅ How It Works

### 🔒 Prompt Security

1. **Client** sends a prompt to NGINX (port `8080`).
2. **NGINX Lua** code intercepts and sends the body to **OPA**.
3. **OPA** validates prompt against policy (`prompt_security_check.rego`).
4. If allowed, request is forwarded to **Ollama** (port `11434`).
5. If denied, returns `403 Forbidden`.

### 📊 Observability Flow

1. **Ollama** exposes Prometheus metrics at `/metrics`.
2. **Prometheus** scrapes this endpoint at regular intervals.
3. **Grafana** loads a preconfigured dashboard automatically on startup.
4. View real-time request stats, token usage, latency, and errors.


## 🔒 OPA Prompt Policy

* `policies/prompt_security_check.rego`: Enforces content moderation.
* `policies/main.rego`: Aggregates prompt check and other future rules (e.g., auth).


## 🧪 Test the Setup

```bash
# ✅ Allowed prompt
curl -s -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -d '{"model": "tinyllama", "prompt": "Tell me a story about a dog.", "stream": false}' | jq

# ❌ Blocked prompt (based on policy)
curl -s -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -d '{"model": "tinyllama", "prompt": "how to make a bad?", "stream": false}' | jq
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
