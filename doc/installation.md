---
title: Installation
---
# Installation

Download the self-extracting launcher for your platform from the [Downloads](downloads) page.
Each launcher bundles a complete JRE — **no Java installation is required**.

## Linux / macOS

Choose the launcher that matches your platform:

| Platform | Architecture | Download URL |
|---|---|---|
| Linux | x86_64 (amd64) | `jpm-linux-amd64.run` |
| Linux | aarch64 (ARM) | `jpm-linux-aarch64.run` |
| macOS | x86_64 (Intel) | `jpm-macos-amd64.run` |
| macOS | aarch64 (Apple Silicon) | `jpm-macos-aarch64.run` |

```bash
# Example: Linux x86_64
curl -Lo jpm.run https://github.com/peterkir/jpmcli/releases/download/latest-main/jpm-linux-amd64.run

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
