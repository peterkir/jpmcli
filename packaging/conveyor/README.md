# Conveyor Packaging for jpmcli

This branch wires [Hydraulic Conveyor](https://conveyor.hydraulic.dev/) into
the jpmcli build pipeline.  Conveyor produces native packages for all five
required platform/architecture targets from a **single build machine**, with
the JVM (Eclipse Temurin 21 LTS) embedded automatically.

## Target platforms

| Conveyor machine key | OS      | Architecture |
|----------------------|---------|--------------|
| `windows.amd64`      | Windows | x86\_64      |
| `linux.amd64`        | Linux   | x86\_64      |
| `linux.aarch64`      | Linux   | aarch64      |
| `mac.amd64`          | macOS   | x86\_64      |
| `mac.aarch64`        | macOS   | aarch64 (M1+)|

## Output artifacts

`conveyor make site` writes to `output/`:

```
output/
  jpm-4.0.0-windows-amd64.zip
  jpm-4.0.0-linux-amd64.tar.gz
  jpm-4.0.0-linux-aarch64.tar.gz
  jpm-4.0.0-mac-amd64.zip
  jpm-4.0.0-mac-aarch64.zip
  download.html          ← ready-made download page
```

Each archive is self-contained: it includes the jpm launcher plus the embedded
JRE. Users do **not** need Java installed.

## How it works

```
Maven package  →  fat JAR  →  Conveyor reads Main-Class from manifest
                                     │
                     ┌───────────────┼───────────────┐
                     ↓               ↓               ↓
               Temurin JRE     launch script    platform package
               (per-platform   (per-platform    (.zip / .tar.gz)
                downloaded)     generated)
```

`bnd-maven-plugin` already embeds `Main-Class: aQute.jpm.main.Main` into the
JAR manifest, so Conveyor needs no additional launcher configuration.

## Local usage

### Prerequisites

1. Install Conveyor: <https://conveyor.hydraulic.dev/download/>
2. Register for a free OSS license (open-source projects are free):
   <https://hydraulic.dev/pricing>

### Build

```bash
# 1. Build the fat JAR
./mvnw -Drevision=4.0.0 package -DskipTests

# 2. Package for all platforms (trial mode — watermarks the packages)
conveyor make site

# 3. Inspect packages
ls output/
```

### CI (GitHub Actions)

The workflow at `.github/workflows/conveyor-release.yml` runs automatically on
every push to this branch.  Add two repository secrets to enable it:

| Secret                     | Value                                       |
|----------------------------|---------------------------------------------|
| `CONVEYOR_AGREE_TO_LICENSE`| `1`                                         |
| `CONVEYOR_LICENSE_KEY`     | Your key from <https://hydraulic.dev/>      |

On a tag push (`v*`) the workflow additionally creates a GitHub Release and
attaches all packages.

## Configuration reference (`conveyor.conf`)

| Key | Purpose |
|-----|---------|
| `app.jvm.version` | JDK version to embed (currently 21 LTS) |
| `app.machines` | Target platform/arch list |
| `app.windows.console` | Keep stdout/stderr in terminal on Windows |
| `app.inputs` | Fat JAR path (relative to project root) |

To switch to Java 25 LTS (available September 2025) change `app.jvm.version`
to `25`.  Java 25 includes Project Leyden AOT class-data sharing, which
reduces CLI startup time noticeably.

## Upgrading Conveyor

Update the `CONVEYOR_VERSION` variable in
`.github/workflows/conveyor-release.yml` and re-test locally.
