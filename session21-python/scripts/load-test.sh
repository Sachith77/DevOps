#!/usr/bin/env bash
set -euo pipefail
URL="${URL:-http://localhost:3000/api/tickets}"
REQUESTS="${REQUESTS:-1000}"
CONCURRENCY="${CONCURRENCY:-8}"
export URL
seq "$REQUESTS" | xargs -P "$CONCURRENCY" -I{} sh -c 'curl --fail --silent --show-error "$URL" >/dev/null'
echo "Completed $REQUESTS requests. Watch kubectl top pods and kubectl get hpa -n taskboard."
# A lightweight read workload may not generate enough CPU to trigger scaling.
