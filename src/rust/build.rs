use std::fs;
use std::path::Path;

/// Extract the resolved version of the `polyglot-sql` dependency from
/// `Cargo.lock` so the R package can report exactly which upstream release it
/// is linked against. Works fully offline (reads only the local lockfile).
fn main() {
    let manifest_dir = std::env::var("CARGO_MANIFEST_DIR").unwrap_or_default();
    let lockfile = Path::new(&manifest_dir).join("Cargo.lock");
    println!("cargo:rerun-if-changed={}", lockfile.display());

    let version = fs::read_to_string(&lockfile)
        .ok()
        .and_then(|contents| locked_version(&contents, "polyglot-sql"))
        .unwrap_or_else(|| "unknown".to_string());

    println!("cargo:rustc-env=POLYGLOT_SQL_VERSION={version}");
}

fn locked_version(lock: &str, name: &str) -> Option<String> {
    let mut in_package = false;
    for line in lock.lines() {
        let line = line.trim();
        if line == "[[package]]" {
            in_package = false;
        } else if line == format!("name = \"{name}\"") {
            in_package = true;
        } else if in_package {
            if let Some(rest) = line.strip_prefix("version = \"") {
                return rest.strip_suffix('"').map(str::to_string);
            }
        }
    }
    None
}
