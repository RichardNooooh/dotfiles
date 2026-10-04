#!/usr/bin/env bash
set -euo pipefail

root=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
check="$root/scripts/bootstrap.sh"
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

core="$workdir/jupynvim-core"
printf '#!/usr/bin/env bash\nprintf "jupynvim-core 0.4.5\\n"\n' >"$core"
chmod +x "$core"

"$check" --check-jupynvim-core "$core" v0.4.5

printf '#!/usr/bin/env bash\nprintf "jupynvim-core 0.4.4\\n"\n' >"$core"
chmod +x "$core"
if "$check" --check-jupynvim-core "$core" v0.4.5; then
  printf 'wrong-version core was accepted\n' >&2
  exit 1
fi

chmod -x "$core"
if "$check" --check-jupynvim-core "$core" v0.4.5; then
  printf 'non-executable core was accepted\n' >&2
  exit 1
fi
