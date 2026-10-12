# K8s Support Lab — Troubleshooting Scenarios

Laboratorio de troubleshooting de Kubernetes orientado a soporte técnico (Support Engineer).
Cada escenario fue reproducido, diagnosticado y remediado en un cluster kind real —
no son apuntes, son incidentes vividos.

## Escenarios

| # | Escenario | Síntoma del ticket | Firma forense |
|---|-----------|-------------------|---------------|
| 1 | OOMKill | "El job falla desde que aumentó el reporte" | exit 137, Reason OOMKilled, backoff exponencial |
| 2 | Probe fantasma | "El servicio se cae cada 3 minutos, logs limpios" | exit 0 + Completed, reinicio rítmico period×threshold |
| 3 | Node NotReady | "El dashboard no actualiza, el nodo está raro" | heartbeat congelado, taints unreachable:NoExecute, tolerations 300s |
| 4 | ImagePullBackOff | "El despliegue nuevo no levanta" | ErrImagePull → ImagePullBackOff, causa explícita en events |
| 5 | DNS intermitente | "Lento SOLO a veces, todo Running" | ndots:5, search list, CoreDNS subdimensionado |
| 6 | Service sin endpoints | "El servicio ignora los pods sanos" | selector mismatch — `kubectl get endpoints` lo delata |

## Uso

```bash
kind create cluster --name lab-soporte
kubectl create namespace cliente-truist

# Escenarios 1-2: aplicar los yamls y seguir el diagnóstico en break-fix
kubectl apply -f job-reporte.yaml
kubectl apply -f deploy-web.yaml

# Escenario 6: inyección automatizada (diagnosticar ANTES de leer el script)
bash break.sh
```

## Lecciones que dejó el lab

- CrashLoopBackOff es un síntoma, no un diagnóstico — la causa está en el exit code y los events
- El asesino importa: kernel (OOMKill, 137) vs kubelet (probe, reinicia y lo anuncia)
- liveness mata y reinicia; readiness solo te saca del Service
- kubectl config current-context antes de cualquier diagnóstico (cluster equivocado = error #1)
- En eventos con reintentos, agrupa por patrón: el primer error no siempre es la causa raíz
- busybox nslookup no usa la search list — NXDOMAIN ≠ timeout
- 137 = 128+9 (SIGKILL) · 143 = 128+15 (SIGTERM) · 0 + Completed = algo externo mató una app sana

## Contexto

Lab de preparación para entrevistas de Kubernetes Support Engineer (sept-oct 2026),
construido en kind (`lab-soporte`), namespace `cliente-truist` — un "cliente" por namespace,
como en soporte real. Quiz final: 29/30.

`prep-screening.html` contiene además la tabla forense completa de exit codes
(137/143/0), las lecciones finas de cada escenario y el checklist de diagnóstico.
