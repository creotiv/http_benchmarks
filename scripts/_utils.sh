#!/usr/bin/env bash
set -euo pipefail

# bytes to human
b2h() {
  awk 'function human(x) {
    s="B   KB  MB  GB  TB  PB  EB  ZB  YB";
    while (x>=1024 && length(s)>1){x/=1024; s=substr(s,5)}
    return sprintf("%.2f %s", x, s)
  }
  {print human($1)}'
}

# human to bytes (supports Ki/Mi/Gi or MB/GB printed by docker)
h2b() {
  python3 - "$1" << 'PY'
import re,sys
s=sys.argv[1].strip().upper().replace('IB','B')
m=re.match(r'^([\d.]+)\s*([KMGTP]?B)$', s)
if not m:
    print(0); sys.exit(0)
n=float(m.group(1)); u=m.group(2)
mul={'B':1,'KB':1024,'MB':1024**2,'GB':1024**3,'TB':1024**4}
print(int(n*mul[u]))
PY
}
