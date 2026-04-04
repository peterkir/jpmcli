---
title: Installation
---
# Installation

Download the self-extracting launcher for your platform from the [Downloads](downloads) page.
Each launcher bundles a complete JRE — **no Java installation is required**.

## Linux / macOS

```bash
# Download the launcher (replace <platform> with linux-amd64, linux-aarch64,
# macos-amd64, or macos-aarch64)
curl -Lo jpm.run https://github.com/peterkir/jpmcli/releases/download/latest-main/jpm-<platform>.run

# Make it executable
chmod +x jpm.run

# Run the installer
./jpm.run init
```

After `init` completes, the `jpm` command is available in your PATH.

## Windows

```bat
:: Download jpm-windows-amd64.bat from the Downloads page, then run:
jpm-windows-amd64.bat init
```

On first launch the launcher extracts itself to `%LOCALAPPDATA%\jpm-sfx\` and
subsequent invocations start immediately from the cached location.

## Verifying the installation

```bash
jpm version
jpm help
```

## Uninstalling

```bash
jpm deinit
```

This removes all jpm-managed commands and services from your system.
