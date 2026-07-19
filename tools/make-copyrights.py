#!/usr/bin/env python3
"""Generate inst/COPYRIGHTS from the vendored crate tree.

Run from src/rust (as tools/update-vendor.sh does) with a populated vendor/
directory. Collects every crate's name, version, license expression and
authors from its Cargo.toml, plus the special upstream attributions.
"""
import os
import re
import sys

HERE = os.getcwd()
VENDOR = os.path.join(HERE, "vendor")
OUT = os.path.normpath(os.path.join(HERE, "..", "..", "inst", "COPYRIGHTS"))

HEADER = """\
Copyright and license inventory for polyglotSQL
===============================================

The polyglotSQL R package is distributed under the MIT license (see the
package LICENSE file). Its compiled library statically links the Rust crates
listed below, which are vendored in the source package
(src/rust/vendor.tar.xz).

Primary upstream
----------------

polyglot-sql (the Polyglot project)
  https://github.com/tobilg/polyglot
  License: MIT
  Copyright (c) 2026 TobiLG <github@tobilg.com>

  Polyglot is derived from SQLGlot:

SQLGlot
  https://github.com/tobymao/sqlglot
  License: MIT
  Copyright (c) 2026 Toby Mao

  The full text of both MIT notices is reproduced at the end of this file.

Vendored Rust crates
--------------------
"""

MIT_NOTICES = """
Full license texts
------------------

MIT License (Polyglot)

Copyright (c) 2026 TobiLG <github@tobilg.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

MIT License (SQLGlot)

Copyright (c) 2026 Toby Mao

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""


def toml_field(text, field):
    m = re.search(rf'^{field}\s*=\s*"([^"]*)"', text, re.M)
    return m.group(1) if m else None


def toml_list(text, field):
    m = re.search(rf"^{field}\s*=\s*\[(.*?)\]", text, re.M | re.S)
    if not m:
        return []
    return re.findall(r'"([^"]*)"', m.group(1))


def main():
    if not os.path.isdir(VENDOR):
        sys.exit("vendor/ not found; run from src/rust after cargo vendor")
    rows = []
    for crate in sorted(os.listdir(VENDOR)):
        ct = os.path.join(VENDOR, crate, "Cargo.toml")
        if not os.path.exists(ct):
            continue
        with open(ct, encoding="utf-8") as fh:
            text = fh.read()
        name = toml_field(text, "name") or crate
        version = toml_field(text, "version") or "?"
        license_ = toml_field(text, "license") or "see crate"
        authors = toml_list(text, "authors")
        rows.append((name, version, license_, authors))

    with open(OUT, "w", encoding="utf-8") as out:
        out.write(HEADER)
        for name, version, license_, authors in rows:
            out.write(f"\n{name} {version}\n")
            out.write(f"  License: {license_}\n")
            for a in authors:
                out.write(f"  Author: {a}\n")
        out.write(MIT_NOTICES)
    print(f"wrote {OUT} ({len(rows)} crates)")


if __name__ == "__main__":
    main()
