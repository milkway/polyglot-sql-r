#!/usr/bin/env sh
# Update the embedded polyglot-sql crate and regenerate the offline vendor
# archive and the license inventory.
#
# Usage:
#   tools/update-vendor.sh            # re-vendor at the currently pinned version
#   tools/update-vendor.sh 0.6.3     # bump polyglot-sql to 0.6.3, then re-vendor
#
# Afterwards:
#   * update Config/polyglotSQL/upstream in DESCRIPTION to the same version;
#   * run devtools::test() -- a test asserts the linked version matches;
#   * verify src/rust/Cargo.toml rust-version still equals the maximum
#     rust-version printed by this script, and keep DESCRIPTION
#     SystemRequirements in sync.

set -eu

cd "$(dirname "$0")/../src/rust"

if [ "${1:-}" != "" ]; then
  NEW_VERSION="$1"
  echo "==> Bumping polyglot-sql to ${NEW_VERSION}"
  POLYGLOT_NEW_VERSION="${NEW_VERSION}" python3 - <<'PY'
import os, re
version = os.environ['POLYGLOT_NEW_VERSION']
with open('Cargo.toml', encoding='utf-8') as fh:
    text = fh.read()
text, n = re.subn(
    r"(\[dependencies\.polyglot-sql\]\nversion = ')[^']*(')",
    lambda m: m.group(1) + version + m.group(2),
    text,
)
assert n == 1, 'could not find [dependencies.polyglot-sql] version line'
with open('Cargo.toml', 'w', encoding='utf-8') as fh:
    fh.write(text)
PY
  cargo update -p polyglot-sql --precise "${NEW_VERSION}"
else
  echo "==> Refreshing lockfile (no version bump)"
  cargo generate-lockfile 2>/dev/null || true
fi

echo "==> Vendoring dependencies"
rm -rf vendor vendor.tar.xz
mkdir -p ../.cargo-vendor-tmp
cargo vendor --locked vendor > vendor-config.toml.new

# Normalize the generated config so the Makevars can always use it:
# cargo prints a [source] config pointing at the vendor dir.
mv vendor-config.toml.new vendor-config.toml

echo "==> License inventory -> inst/COPYRIGHTS"
python3 ../../tools/make-copyrights.py

echo "==> Minimum supported Rust version across vendored crates:"
python3 - <<'PY'
import os, re
best = (0, 0, 0); who = "(none declared)"
for crate in os.listdir('vendor'):
    ct = os.path.join('vendor', crate, 'Cargo.toml')
    if not os.path.exists(ct):
        continue
    with open(ct, encoding='utf-8') as fh:
        m = re.search(r'^rust-version\s*=\s*"([0-9.]+)"', fh.read(), re.M)
    if m:
        v = tuple(int(x) for x in m.group(1).split('.'))
        if v > best:
            best, who = v, crate
print('   max rust-version =', '.'.join(map(str, best)), 'required by', who)
PY

echo "==> Packing vendor.tar.xz"
XZ_OPT=-9e tar -cJf vendor.tar.xz vendor
rm -rf vendor
ls -lh vendor.tar.xz

echo "==> Done. Remember to update DESCRIPTION (Config/polyglotSQL/upstream,"
echo "    SystemRequirements) and NEWS.md, then run the tests."
