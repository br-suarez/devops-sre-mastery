#!/usr/bin/env bash
#
# Game Day II — failure injection across the full platform (modules 00-15).
#
# ############################################################################
# #  DO NOT READ THIS FILE BEFORE RUNNING IT.                                #
# #                                                                          #
# #  You read gameday-1.sh after the exercise. Do the same here. Knowing     #
# #  the catalogue in advance turns diagnosis into recall.                   #
# ############################################################################
#
# Usage:
#   ./scripts/gameday-2.sh inject          # one random failure
#   ./scripts/gameday-2.sh inject 5        # five at once — the module 16 target
#   ./scripts/gameday-2.sh status          # spoiler
#   ./scripts/gameday-2.sh restore
#
# Every injection is reversible. Unlike Game Day I, several of these interact:
# one failure can mask another, and the order you fix them matters.

set -euo pipefail

NS=${PULSE_NAMESPACE:-pulse}
MON_NS=${MONITORING_NAMESPACE:-monitoring}
ARGO_NS=${ARGOCD_NAMESPACE:-argocd}
STATE_DIR=${GAMEDAY_STATE:-/tmp/gameday-2}

readonly RED=$'\033[31m' GREEN=$'\033[32m' DIM=$'\033[2m' RESET=$'\033[0m'
log() { printf '%s\n' "$*" >&2; }
die() { log "${RED}error:${RESET} $*"; exit 1; }

mkdir -p "$STATE_DIR"
save()      { printf '%s' "$2" > "$STATE_DIR/$1"; }
saved()     { [ -f "$STATE_DIR/$1" ] && cat "$STATE_DIR/$1"; }
mark()      { touch "$STATE_DIR/active-$1"; }
unmark()    { rm -f "$STATE_DIR/active-$1"; }
is_active() { [ -f "$STATE_DIR/active-$1" ]; }
have()      { command -v "$1" >/dev/null 2>&1; }

# Restore is best-effort per step: one failed command must not stop the others,
# because a partial recovery still beats none. But the failure has to survive to
# the summary. A restore that reports success it did not achieve is worse than
# one that fails loudly — you run this when the cluster is already on fire.
#
# `try` records the failure instead of aborting. `done_step` clears the active
# marker only if every try in that function succeeded, so `status` keeps telling
# the truth and re-running `restore` retries only what is still broken.
STEP_RC=0
try() { "$@" >/dev/null 2>&1 || STEP_RC=1; }
done_step() {
  if [ "$STEP_RC" -eq 0 ]; then unmark "$1"; fi
  return "$STEP_RC"
}

# =============================================================================
# INJECTIONS — one per layer of the platform
# =============================================================================

# --- 1: probe pointed at the wrong endpoint (module 04) ----------------------
inject_1() {
  save 1-orig "$(kubectl get deployment pulse-api -n "$NS" \
    -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}')"
  kubectl patch deployment pulse-api -n "$NS" --type=json -p \
    '[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/path","value":"/healthz"}]' >/dev/null
  mark 1
}
restore_1() {
  local p; p=$(saved 1-orig); p=${p:-/readyz}
  try kubectl patch deployment pulse-api -n "$NS" --type=json -p \
    "[{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/readinessProbe/httpGet/path\",\"value\":\"$p\"}]"
  done_step 1
}

# --- 2: gateway stops admitting routes (module 05) ---------------------------
inject_2() {
  local gw; gw=$(kubectl get gateway -n "$NS" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  [ -n "$gw" ] || { log "${DIM}skip 2: no Gateway${RESET}"; return; }
  save 2-gw "$gw"
  save 2-orig "$(kubectl get gateway "$gw" -n "$NS" \
    -o jsonpath='{.spec.listeners[0].allowedRoutes.namespaces.from}')"
  kubectl patch gateway "$gw" -n "$NS" --type=json -p \
    '[{"op":"replace","path":"/spec/listeners/0/allowedRoutes/namespaces/from","value":"Selector"},
      {"op":"add","path":"/spec/listeners/0/allowedRoutes/namespaces/selector","value":{"matchLabels":{"gateway-access":"none"}}}]' >/dev/null
  mark 2
}
restore_2() {
  local gw; gw=$(saved 2-gw); [ -n "$gw" ] || { unmark 2; return 0; }
  local o; o=$(saved 2-orig); o=${o:-Same}
  try kubectl patch gateway "$gw" -n "$NS" --type=json -p \
    "[{\"op\":\"replace\",\"path\":\"/spec/listeners/0/allowedRoutes/namespaces/from\",\"value\":\"$o\"},
      {\"op\":\"remove\",\"path\":\"/spec/listeners/0/allowedRoutes/namespaces/selector\"}]"
  done_step 2
}

# --- 3: cardinality explosion (module 07) ------------------------------------
# Prometheus degrades slowly rather than failing, so this one masks others.
inject_3() {
  save 3-orig "$(kubectl get deployment pulse-worker -n "$NS" \
    -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="METRIC_LABEL_MODE")].value}')"
  kubectl set env deployment/pulse-worker -n "$NS" METRIC_LABEL_MODE=per-url >/dev/null
  mark 3
}
restore_3() {
  local o; o=$(saved 3-orig)
  if [ -n "$o" ]; then
    try kubectl set env deployment/pulse-worker -n "$NS" METRIC_LABEL_MODE="$o"
  else
    try kubectl set env deployment/pulse-worker -n "$NS" METRIC_LABEL_MODE-
  fi
  done_step 3
}

# --- 4: collector processors in the wrong order (module 08) ------------------
inject_4() {
  kubectl get configmap otel-collector-config -n "$MON_NS" >/dev/null 2>&1 \
    || { log "${DIM}skip 4: no collector config${RESET}"; return; }
  kubectl get configmap otel-collector-config -n "$MON_NS" -o yaml > "$STATE_DIR/4-orig.yaml"
  kubectl get configmap otel-collector-config -n "$MON_NS" -o yaml \
    | sed 's/\[memory_limiter, batch\]/[batch, memory_limiter]/' \
    | kubectl apply -f - >/dev/null
  kubectl rollout restart daemonset/otel-collector -n "$MON_NS" >/dev/null 2>&1 || true
  mark 4
}
restore_4() {
  if [ -f "$STATE_DIR/4-orig.yaml" ]; then
    try kubectl apply -f "$STATE_DIR/4-orig.yaml"
  fi
  try kubectl rollout restart daemonset/otel-collector -n "$MON_NS"
  done_step 4
}

# --- 5: self-heal reverting a fix (module 10) --------------------------------
# The most confusing one: a fix that works and then undoes itself.
inject_5() {
  kubectl get application pulse -n "$ARGO_NS" >/dev/null 2>&1 \
    || { log "${DIM}skip 5: no Argo Application${RESET}"; return; }
  save 5-mem "$(kubectl get deployment pulse-api -n "$NS" \
    -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}')"
  kubectl set resources deployment pulse-api -n "$NS" --limits=memory=32Mi >/dev/null
  kubectl patch application pulse -n "$ARGO_NS" --type=merge -p \
    '{"spec":{"syncPolicy":{"automated":{"selfHeal":true,"prune":true}}}}' >/dev/null
  mark 5
}
restore_5() {
  local m; m=$(saved 5-mem); m=${m:-256Mi}
  try kubectl set resources deployment pulse-api -n "$NS" --limits=memory="$m"
  done_step 5
}

# --- 6: canary analysis not scoped to the canary (module 11) -----------------
inject_6() {
  kubectl get analysistemplate error-rate -n "$NS" >/dev/null 2>&1 \
    || { log "${DIM}skip 6: no AnalysisTemplate${RESET}"; return; }
  kubectl get analysistemplate error-rate -n "$NS" -o yaml > "$STATE_DIR/6-orig.yaml"
  kubectl get analysistemplate error-rate -n "$NS" -o yaml \
    | sed 's/rollouts_pod_template_hash="{{args.canary-hash}}"//g' \
    | kubectl apply -f - >/dev/null
  mark 6
}
restore_6() {
  if [ -f "$STATE_DIR/6-orig.yaml" ]; then
    try kubectl apply -f "$STATE_DIR/6-orig.yaml"
  fi
  done_step 6
}

# --- 7: admission policy silently permitting (module 12) ---------------------
inject_7() {
  kubectl get clusterpolicy require-signed-images >/dev/null 2>&1 \
    || { log "${DIM}skip 7: no policy${RESET}"; return; }
  save 7-orig "$(kubectl get clusterpolicy require-signed-images \
    -o jsonpath='{.spec.validationFailureAction}')"
  kubectl patch clusterpolicy require-signed-images --type=merge -p \
    '{"spec":{"validationFailureAction":"Audit"}}' >/dev/null
  mark 7
}
restore_7() {
  local o; o=$(saved 7-orig); o=${o:-Enforce}
  try kubectl patch clusterpolicy require-signed-images --type=merge -p \
    "{\"spec\":{\"validationFailureAction\":\"$o\"}}"
  done_step 7
}

# --- 8: queue saturation (modules 07-08) -------------------------------------
inject_8() {
  save 8-conc "$(kubectl get deployment pulse-worker -n "$NS" \
    -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="WORKER_CONCURRENCY")].value}')"
  kubectl set env deployment/pulse-worker -n "$NS" \
    WORKER_CONCURRENCY=1 QUEUE_SIZE=8 SCHEDULE_INTERVAL_SECONDS=2 >/dev/null
  mark 8
}
restore_8() {
  local c; c=$(saved 8-conc)
  try kubectl set env deployment/pulse-worker -n "$NS" \
    WORKER_CONCURRENCY="${c:-4}" QUEUE_SIZE=64 SCHEDULE_INTERVAL_SECONDS=15
  done_step 8
}

# --- 9: TCP accept queue too small (module 08b) ------------------------------
# Application p99 stays fast; clients see seconds. Invisible above the socket.
inject_9() {
  save 9-orig "$(kubectl get deployment pulse-api -n "$NS" \
    -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="LISTEN_BACKLOG")].value}')"
  kubectl set env deployment/pulse-api -n "$NS" LISTEN_BACKLOG=2 >/dev/null
  mark 9
}
restore_9() {
  local o; o=$(saved 9-orig)
  if [ -n "$o" ]; then
    try kubectl set env deployment/pulse-api -n "$NS" LISTEN_BACKLOG="$o"
  else
    try kubectl set env deployment/pulse-api -n "$NS" LISTEN_BACKLOG-
  fi
  done_step 9
}

# --- 10: PDB that blocks all maintenance (module 06) -------------------------
inject_10() {
  local reps; reps=$(kubectl get deployment pulse-api -n "$NS" -o jsonpath='{.spec.replicas}')
  cat <<EOF | kubectl apply -f - >/dev/null
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: pulse-api-gameday
  namespace: $NS
spec:
  minAvailable: ${reps:-3}
  selector:
    matchLabels:
      app: pulse-api
EOF
  mark 10
}
restore_10() {
  try kubectl delete pdb pulse-api-gameday -n "$NS" --ignore-not-found
  done_step 10
}

readonly TOTAL=10

# =============================================================================

cmd_inject() {
  local count=${1:-1}

  # Cheapest precondition first: a bad argument should not require a working
  # cluster to be reported.
  if [ "$count" -lt 1 ] || [ "$count" -gt "$TOTAL" ]; then
    die "count must be 1-$TOTAL"
  fi
  have kubectl || die "kubectl not found"
  kubectl get namespace "$NS" >/dev/null 2>&1 || die "namespace $NS not found"

  local picked=()
  while [ ${#picked[@]} -lt "$count" ]; do
    local n=$(( (RANDOM % TOTAL) + 1 ))
    printf '%s\n' "${picked[@]:-}" | grep -qx "$n" || picked+=("$n")
  done

  local n
  for n in "${picked[@]}"; do
    is_active "$n" || "inject_$n"
  done

  log ""
  log "${RED}================================================${RESET}"
  log "${RED}  ${#picked[@]} failure(s) injected. Timer starts now.${RESET}"
  log "${RED}================================================${RESET}"
  log ""
  log "Some of these interact. One can mask another, and the order you fix"
  log "them changes what you can observe."
  log ""
  log "  1. Record every command, with your hypothesis before running it."
  log "  2. Mitigate first, root-cause second."
  log "  3. Write the postmortem in this session."
  log ""
  log "${DIM}Do not read this script. Finish with: $0 restore${RESET}"
}

cmd_status() {
  log "${DIM}(spoiler — only after the exercise)${RESET}"
  local n any=0
  for n in $(seq 1 $TOTAL); do
    if is_active "$n"; then log "  ${RED}active${RESET}  injection $n"; any=1; fi
  done
  [ "$any" -eq 1 ] || log "  ${GREEN}nothing injected${RESET}"
}

cmd_restore() {
  have kubectl || die "kubectl not found"

  # Only touch what was actually injected. Blindly running all ten restores
  # against a cluster that never saw them produces failures that mean nothing.
  local n done_ok=() failed=()
  for n in $(seq 1 "$TOTAL"); do
    is_active "$n" || continue
    STEP_RC=0
    if "restore_$n"; then done_ok+=("$n"); else failed+=("$n"); fi
  done

  if [ ${#done_ok[@]} -eq 0 ] && [ ${#failed[@]} -eq 0 ]; then
    log "${DIM}nothing was injected — nothing to restore${RESET}"
    return 0
  fi

  if [ ${#failed[@]} -gt 0 ]; then
    log "${RED}restore incomplete.${RESET} Still injected: ${failed[*]}"
    [ ${#done_ok[@]} -eq 0 ] || log "${DIM}restored: ${done_ok[*]}${RESET}"
    log ""
    log "The cluster is NOT back to baseline. Their markers were kept, so:"
    log "  ${DIM}$0 status${RESET}   shows what is still active"
    log "  ${DIM}$0 restore${RESET}  retries only those"
    log "Run the failing command by hand to see the error this swallowed."
    return 1
  fi

  log "${GREEN}restored${RESET} injections: ${done_ok[*]}. Waiting for rollout..."
  local rc=0
  kubectl rollout status deployment/pulse-api -n "$NS" --timeout=120s || rc=1
  kubectl rollout status deployment/pulse-worker -n "$NS" --timeout=120s || rc=1
  if [ "$rc" -ne 0 ]; then
    log "${RED}rollout did not converge.${RESET} The manifests are back, the pods are not."
    return 1
  fi

  log ""
  log "Verify with: ./platform/scripts/verify.sh"
}

case "${1:-}" in
  inject)  shift; cmd_inject "$@" ;;
  status)  cmd_status ;;
  restore) cmd_restore ;;
  *) log "usage: $0 {inject [count] | status | restore}"; exit 2 ;;
esac
