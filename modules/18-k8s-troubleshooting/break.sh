#!/bin/bash
# break.sh — Simulación de live troubleshooting
# Ejecutar SIN LEER (spoilers) — el diagnóstico es la prueba :)
# Uso: bash ~/Projects/lab-soporte/break.sh

set -e
K="kubectl -n cliente-truist"

$K delete deploy pagos-api --ignore-not-found >/dev/null 2>&1 || true
$K delete svc pagos-svc --ignore-not-found >/dev/null 2>&1 || true

$K apply -f - >/dev/null <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pagos-api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: pagos
  template:
    metadata:
      labels:
        app: pagos
    spec:
      containers:
      - name: api
        image: nginx:1.27
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: pagos-svc
spec:
  selector:
    app: pago
  ports:
  - port: 80
    targetPort: 80
EOF

echo ""
echo "=== ESCENARIO INYECTADO ==="
echo "El cluster tiene un servicio nuevo desplegado hace minutos."
echo "Regla: diagnostica en VOZ ALTA como en la entrevista real."
