# Oomph SFX Packaging for jpmcli

This branch implements the **self-extracting archive** packaging pattern
inspired by the [Eclipse Oomph installer](https://github.com/eclipse-oomph/oomph).

The Oomph installer prepends a tiny native C launcher stub to a ZIP archive
containing the application and a bundled JRE; on launch the stub unzips the
payload to a temp directory and starts Java.  This branch achieves the same
result for all five required platform/arch targets using shell and PowerShell
scripts — no pre-built native binary required.

## Target platforms

| Output file              | OS      | Architecture |
|--------------------------|---------|--------------|
| `jpm-linux-amd64.run`    | Linux   | x86\_64      |
| `jpm-linux-aarch64.run`  | Linux   | aarch64      |
| `jpm-macos-amd64.run`    | macOS   | x86\_64      |
| `jpm-macos-aarch64.run`  | macOS   | aarch64 (M1+)|
| `jpm-windows-amd64.bat`  | Windows | x86\_64      |

Each output file is entirely self-contained.  Users need neither Java nor any
package manager installed.

## How it works

```
Maven package  →  fat JAR
                      │
                      ├──  jlink  →  minimal JRE (~50 MB)
                      │
                      └──  create-sfx-* script
                                │
                          ┌─────▼──────────────────────────────────────┐
                          │  Unix .run                                  │
                          │  ─────────────────────────────────────────  │
                          │  #!/bin/sh  (stub = sfx-launcher.sh)        │
                          │  … self-extraction logic …                  │
                          │  __PAYLOAD__                                │
                          │  <base64-encoded tar.gz of jre/ + jpm.jar> │
                          └────────────────────────────────────────────┘
                          ┌─────▼──────────────────────────────────────┐
                          │  Windows .bat                               │
                          │  ─────────────────────────────────────────  │
                          │  @echo off  (PowerShell decode + run stub)  │
                          │  __PAYLOAD__                                │
                          │  <base64-encoded zip of jre/ + jpm.jar>    │
                          └────────────────────────────────────────────┘
```

### Unix `.run` file

On first run:
1. `awk` locates the `__PAYLOAD__` marker line inside the script itself.
2. `tail -n +<line>` pipes everything after the marker into `base64 -d | tar -xz`.
3. The tarball is extracted to a `mktemp -d` temp directory.
4. `exec $tmpdir/jre/bin/java -jar $tmpdir/jpm.jar "$@"` replaces the shell process.
5. An EXIT trap removes the temp directory on completion.

### Windows `.bat` file

On first run:
1. The batch reads itself line-by-line, collecting lines after `__PAYLOAD__`.
2. PowerShell decodes the base64 and calls `ZipFile::ExtractToDirectory`.
3. Extracted files are cached in `%LOCALAPPDATA%\jpm-sfx\<version>`.
4. Subsequent launches skip extraction and go straight to step 4.
5. `java.exe -jar jpm.jar %*` is called with all original arguments.

## jlink module set

The jlink JRE bundles these Java modules (defined in `pom.xml`, profile
`jlink-sfx`):

| Module | Reason |
|--------|--------|
| `java.base` | Always required |
| `java.logging` | `java.util.logging` used by slf4j |
| `java.xml` | XML processing in bnd/OSGi |
| `java.management` | JMX — used by bnd |
| `java.naming` | JNDI — used by bnd |
| `java.net.http` | HttpClient for repository access |
| `java.sql` | JDBC — used by bnd repository |
| `java.compiler` | Java compiler API — used by bnd |

Run `jdeps --multi-release 21 -recursive --ignore-missing-deps
target/biz.aQute.jpm.run-*.jar` after each dependency upgrade to verify
the module list is still complete.

## Local usage

### Prerequisites

- JDK 21 (for both Maven compile and jlink)
- Bash 3.2+ (macOS default, Linux default) or PowerShell 5.1+ (Windows)

### Build (Unix)

```bash
# 1. Build fat JAR and create jlink JRE image
./mvnw -Drevision=4.0.0 -Pjlink-sfx package -DskipTests

# 2. Create the SFX launcher
chmod +x packaging/oomph-sfx/create-sfx-unix.sh
packaging/oomph-sfx/create-sfx-unix.sh \
    target/biz.aQute.jpm.run-4.0.0-SNAPSHOT.jar \
    target/jre-image \
    target/jpm-linux-amd64.run

# 3. Test it (no Java in PATH required)
./target/jpm-linux-amd64.run --version
```

### Build (Windows)

```powershell
# 1. Build fat JAR and create jlink JRE image
./mvnw -Drevision=4.0.0 -Pjlink-sfx package -DskipTests

# 2. Create the SFX launcher
pwsh -File packaging\oomph-sfx\create-sfx-windows.ps1 `
     -JarFile "target\biz.aQute.jpm.run-4.0.0-SNAPSHOT.jar" `
     -JreDir  "target\jre-image" `
     -OutFile "target\jpm-windows-amd64.bat"

# 3. Test it
target\jpm-windows-amd64.bat --version
```

### CI (GitHub Actions)

`.github/workflows/oomph-sfx-build.yml` runs a matrix over all five
platform/arch combinations.  Each runner builds the fat JAR independently,
creates its platform-native jlink JRE, and then produces the SFX file.
Workflow artifacts are retained for 30 days.

## Files in this branch

| File | Purpose |
|------|---------|
| `packaging/oomph-sfx/sfx-launcher.sh` | Unix SFX stub template |
| `packaging/oomph-sfx/create-sfx-unix.sh` | Builds Unix `.run` SFX |
| `packaging/oomph-sfx/create-sfx-windows.ps1` | Builds Windows `.bat` SFX |
| `packaging/oomph-sfx/README.md` | This file |
| `.github/workflows/oomph-sfx-build.yml` | CI matrix workflow |
| `pom.xml` (profile `jlink-sfx`) | Runs jlink after Maven package |

## Comparison with the Oomph native approach

| Aspect | Oomph native launcher | This branch |
|--------|----------------------|-------------|
| Stub type | Pre-built C binary | Shell script / Batch file |
| Cross-compilation | Not needed (one binary per arch) | Each CI runner builds its own |
| External deps | None (stub is static binary) | `base64`, `tar` (Unix); PowerShell/.NET (Windows) |
| Startup overhead | Negligible | ~0.5 s extra on first run (extract) |
| Result size | ~100 kB stub + ZIP | Same-size payload, slightly larger stub |

To use the actual Oomph native launcher binaries (smallest possible stub),
replace `sfx-launcher.sh` with the appropriate Oomph binary from
`https://download.eclipse.org/oomph/products/` and adjust `create-sfx-unix.sh`
to use binary concatenation (`cat stub payload > output`) instead of the
base64 approach.

## Upgrading the JVM

Change the `--add-modules` list in the `jlink-sfx` profile in `pom.xml` and
update the `java-version` in `.github/workflows/oomph-sfx-build.yml`.
Java 25 LTS (available September 2025) includes Project Leyden AOT
class-data archives which reduce cold-start time further.
