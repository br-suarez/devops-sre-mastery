# K8s Support Lab — Troubleshooting Scenarios

Kubernetes troubleshooting lab oriented to Technical Support Engineering.
Every scenario was reproduced, diagnosed and remediated on a live kind cluster —
these are not notes, they are incidents I lived.

## Scenarios

| # | Scenario | Ticket symptom | Forensic signature |
|---|----------|----------------|--------------------|
| 1 | OOMKill | "The report job fails since we increased the data size" | exit 137, Reason OOMKilled, exponential backoff across new pods |
| 2 | Ghost probe | "The service drops every 3 minutes, logs are clean" | exit 0 + Completed, rhythmic restarts (period × threshold) |
| 3 | Node NotReady | "The dashboard stopped updating, the node looks weird" | frozen heartbeat, unreachable:NoExecute taints, 300s tolerations |
| 4 | ImagePullBackOff | "The new deployment won't start" | ErrImagePull → ImagePullBackOff, explicit cause in events |
| 5 | Intermittent DNS | "Slow ONLY sometimes, everything Running" | ndots:5, search list, undersized CoreDNS |
| 6 | Service with no endpoints | "The service ignores healthy pods" | selector mismatch — `kubectl get endpoints` gives it away |

## Usage

```bash
kind create cluster --name lab-soporte
kubectl create namespace cliente-truist

# Scenarios 1-2: apply the yamls and work the break-fix diagnosis
kubectl apply -f job-reporte.yaml
kubectl apply -f deploy-web.yaml

# Scenario 6: automated injection (diagnose BEFORE reading the script)
bash break.sh
```

## Lessons the lab left behind

- CrashLoopBackOff is a symptom, not a diagnosis — the cause lives in the exit code and the events
- The killer matters: kernel (OOMKill, 137) vs kubelet (probe, restarts and announces it in events)
- liveness kills and restarts; readiness only pulls you out of the Service
- `kubectl config current-context` before any diagnosis (wrong cluster = mistake #1)
- On events with retries, group by pattern: the first error is not always the root cause
- busybox nslookup does not use the search list — NXDOMAIN ≠ timeout
- 137 = 128+9 (SIGKILL) · 143 = 128+15 (SIGTERM) · 0 + Completed = something external killed a healthy app
- Mitigate hot (kubectl patch), then fix the root (commit to the repo) — the cluster reflects Git, not the other way around

## Context

Interview prep lab for a Kubernetes Support Engineer role (Sep–Oct 2026),
built on kind (`lab-soporte`), namespace `cliente-truist` — one "customer"
per namespace, as in real support work. Final quiz score: 29/30.

`prep-screening.html` also contains the complete exit-code forensics table
(137/143/0), the fine-grained lessons per scenario and the diagnosis checklist.
