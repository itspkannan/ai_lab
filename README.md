# 🧪 AI Lab – Learn AI/ML by Building Real Projects

**AI Lab**, a hands-on portfolio of projects designed to help you **learn and showcase practical AI/ML engineering skills**. At attempt is made in each project combines AI concepts with production-grade infrastructure patterns like observability, security, and rate limiting.


## 📦 Project 1: 🔐 Secure and Observable LLM Gateway with NGINX, OPA, and Redis

This project builds a **secure API gateway** in front of a local LLM (e.g., Ollama), integrating:

- **NGINX + Lua** for request interception and Redis-based rate limiting (sliding window)
- **Open Policy Agent (OPA)** to enforce runtime prompt validation
- **Ollama** as the local LLM backend
- **Prometheus + Grafana** for real-time metrics and observability

### 🎯 Key Features

- ✅ Prompt policy enforcement via Rego rules
- 🔄 Rate limiting per client IP using Redis
- 📊 Prebuilt Grafana dashboard for request/latency/token tracking


