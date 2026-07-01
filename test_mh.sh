#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MH_BIN="${ROOT_DIR}/mh"
PROFILE="${1:-demo}"
TIMEOUT="${TIMEOUT:-10}"
API_PORT="${API_PORT:-9090}"
MIXED_PORT="${MIXED_PORT:-7890}"
SOCKS_PORT="${SOCKS_PORT:-7891}"
OLD_PROXY_PORT="${OLD_PROXY_PORT:-}"
RUN_PID_FILE="${ROOT_DIR}/run.pid"
LOG_FILE="${ROOT_DIR}/${PROFILE}/mihomo.log"

PASS_COUNT=0
FAIL_COUNT=0

log() {
  printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"
}

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  log "PASS $*"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  log "FAIL $*"
}

run_check() {
  local label="$1"
  shift
  if "$@"; then
    pass "$label"
  else
    fail "$label"
  fi
}

print_section() {
  printf '\n== %s ==\n' "$1"
}

cleanup_env() {
  unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY no_proxy || true
}

port_listen_check() {
  local port="$1"
  ss -lnt 2>/dev/null | awk '{print $4}' | grep -qE "(:|\\.)${port}\$"
}

curl_proxy_head() {
  local url="$1"
  curl -I -m "$TIMEOUT" -x "http://127.0.0.1:${MIXED_PORT}" "$url" >/dev/null 2>&1
}

curl_env_head() {
  local url="$1"
  curl -I -m "$TIMEOUT" "$url" >/dev/null 2>&1
}

print_recent_log() {
  if [[ -f "$LOG_FILE" ]]; then
    print_section "Recent mihomo.log"
    tail -n 40 "$LOG_FILE" || true
  else
    print_section "Recent mihomo.log"
    echo "missing log file: $LOG_FILE"
  fi
}

print_context() {
  print_section "Context"
  echo "root_dir=${ROOT_DIR}"
  echo "profile=${PROFILE}"
  echo "api_port=${API_PORT}"
  echo "mixed_port=${MIXED_PORT}"
  echo "socks_port=${SOCKS_PORT}"
  echo "old_proxy_port=${OLD_PROXY_PORT}"
  echo "timeout=${TIMEOUT}"
}

print_env_snapshot() {
  print_section "Proxy Env Before Test"
  env | grep -iE 'http_proxy|https_proxy|all_proxy|no_proxy' || true
}

print_port_snapshot() {
  print_section "Port Snapshot"
  ss -lnt | grep -E ":(7890|7891|9090)\\b" || true
}

print_pid_snapshot() {
  print_section "PID Snapshot"
  if [[ -f "$RUN_PID_FILE" ]]; then
    local pid
    pid="$(cat "$RUN_PID_FILE" 2>/dev/null || true)"
    echo "run.pid=${pid:-<empty>}"
    if [[ -n "${pid:-}" ]]; then
      ps -fp "$pid" -o pid,ppid,cmd || true
    fi
  else
    echo "run.pid missing"
  fi
}

api_json() {
  local path="$1"
  curl -fsS --noproxy '*' "http://127.0.0.1:${API_PORT}${path}"
}

api_selector_now() {
  local selector="$1"
  api_json "/proxies" | jq -r --arg selector "$selector" '.proxies[$selector].now // empty'
}

selector_equals() {
  local selector="$1"
  local expected="$2"
  [[ "$(api_selector_now "$selector")" == "$expected" ]]
}

selector_non_empty() {
  local selector="$1"
  [[ -n "$(api_selector_now "$selector")" ]]
}

main() {
  [[ -x "$MH_BIN" ]] || { echo "missing executable: $MH_BIN"; exit 1; }

  print_context
  print_env_snapshot
  print_port_snapshot

  if [[ -n "$OLD_PROXY_PORT" ]] && port_listen_check "$OLD_PROXY_PORT"; then
    echo
    echo "旧代理端口 ${OLD_PROXY_PORT} 仍在监听。先手动关闭它，再重新运行此脚本。"
    exit 2
  fi

  cleanup_env

  print_section "Start Profile"
  "$MH_BIN" end >/dev/null 2>&1 || true
  "$MH_BIN" start "$PROFILE"

  run_check "API port ${API_PORT} is listening" port_listen_check "$API_PORT"
  run_check "mixed port ${MIXED_PORT} is listening" port_listen_check "$MIXED_PORT"
  run_check "socks port ${SOCKS_PORT} is listening" port_listen_check "$SOCKS_PORT"
  run_check "run.pid exists" test -f "$RUN_PID_FILE"

  if [[ -f "$RUN_PID_FILE" ]]; then
    pid="$(cat "$RUN_PID_FILE" 2>/dev/null || true)"
    run_check "run.pid process is alive" test -n "${pid:-}"
    if [[ -n "${pid:-}" ]]; then
      run_check "PID ${pid} exists" kill -0 "$pid"
    fi
  fi

  print_pid_snapshot

  print_section "API Checks"
  run_check "GET /configs" api_json "/configs"
  run_check "GET /proxies" api_json "/proxies"
  run_check "GLOBAL selector points to Proxy" selector_equals "GLOBAL" "Proxy"
  run_check "Proxy selector has current node" selector_non_empty "Proxy"

  print_section "Shell Proxy Checks"
  eval "$("$MH_BIN" env)"
  run_check "HTTP_PROXY points to ${MIXED_PORT}" bash -lc '[[ "${HTTP_PROXY:-}" == "http://127.0.0.1:'"${MIXED_PORT}"'" ]]'
  run_check "HTTPS_PROXY points to ${MIXED_PORT}" bash -lc '[[ "${HTTPS_PROXY:-}" == "http://127.0.0.1:'"${MIXED_PORT}"'" ]]'

  print_section "Network Through Proxy"
  run_check "proxy -> baidu" curl_proxy_head "https://www.baidu.com"
  run_check "proxy -> github" curl_proxy_head "https://www.github.com"
  run_check "proxy -> google" curl_proxy_head "https://www.google.com"

  print_section "Network Through Current Shell"
  run_check "env -> baidu" curl_env_head "https://www.baidu.com"
  run_check "env -> github" curl_env_head "https://www.github.com"
  run_check "env -> google" curl_env_head "https://www.google.com"

  print_recent_log

  print_section "Summary"
  echo "PASS=${PASS_COUNT}"
  echo "FAIL=${FAIL_COUNT}"

  if (( FAIL_COUNT > 0 )); then
    exit 1
  fi
}

main "$@"
