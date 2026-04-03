#!/usr/bin/env bash
# create-sfx-unix.sh — Produces a self-extracting jpm launcher for Unix
#
# Usage:
#   create-sfx-unix.sh <jar-file> <jre-dir> <output-file>
#
# Arguments:
#   jar-file    Path to biz.aQute.jpm.run-*.jar (fat JAR from Maven)
#   jre-dir     Path to the jlink-generated JRE image directory
#   output-file Destination path for the generated .run file
#
# Example (run from project root after mvn package and jlink):
#   ./packaging/oomph-sfx/create-sfx-unix.sh \
#       target/biz.aQute.jpm.run-4.0.0-SNAPSHOT.jar \
#       target/jre-image \
#       target/jpm-linux-amd64.run
#
# The output file is a self-contained executable.  Copy it anywhere and run it
# directly — no Java installation required on the target machine.
#
# How it works (Oomph-inspired pattern):
#   1. Copy jar + jre into a staging directory.
#   2. Create a gzipped tar of the staging directory.
#   3. Concatenate the stub (sfx-launcher.sh) and raw tarball payload.
#   5. Mark the result executable.
#
# The resulting file is a valid shell script whose tail is a raw binary
# payload.tar.gz. The stub locates the __PAYLOAD__ line at runtime, extracts
# the payload to a temp dir, and exec-s java -jar jpm.jar.

set -euo pipefail

JAR_FILE="${1:?Usage: $0 <jar-file> <jre-dir> <output-file>}"
JRE_DIR="${2:?Usage: $0 <jar-file> <jre-dir> <output-file>}"
OUTPUT_FILE="${3:?Usage: $0 <jar-file> <jre-dir> <output-file>}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STUB_FILE="$SCRIPT_DIR/sfx-launcher.sh"

# ── Validate inputs ────────────────────────────────────────────────────────
[ -f "$JAR_FILE" ]  || { echo "ERROR: JAR not found: $JAR_FILE" >&2; exit 1; }
[ -d "$JRE_DIR" ]   || { echo "ERROR: JRE dir not found: $JRE_DIR" >&2; exit 1; }
[ -f "$STUB_FILE" ] || { echo "ERROR: Stub not found: $STUB_FILE" >&2; exit 1; }

# ── Build payload tarball ──────────────────────────────────────────────────
STAGING=$(mktemp -d)
trap 'rm -rf "$STAGING"' EXIT

echo "==> Staging payload …"
cp "$JAR_FILE" "$STAGING/jpm.jar"
cp -r "$JRE_DIR" "$STAGING/jre"

echo "==> Creating tarball …"
TARBALL="$STAGING/payload.tar.gz"
# Use relative paths so the tarball extracts as jpm.jar and jre/ (no leading ./)
tar -czf "$TARBALL" -C "$STAGING" jpm.jar jre

PAYLOAD_SIZE=$(du -sh "$TARBALL" | cut -f1)
echo "    Payload size: $PAYLOAD_SIZE (compressed)"

# ── Assemble the SFX file ──────────────────────────────────────────────────
echo "==> Writing $OUTPUT_FILE …"

# Write the stub (everything up to and including __PAYLOAD__).
# The stub already ends with the __PAYLOAD__ marker line.
cp "$STUB_FILE" "$OUTPUT_FILE"

# Append the raw payload tarball after the marker.
# This mirrors the native Oomph concatenation style and avoids base64 overhead.
cat "$TARBALL" >> "$OUTPUT_FILE"

chmod +x "$OUTPUT_FILE"

TOTAL_SIZE=$(du -sh "$OUTPUT_FILE" | cut -f1)
echo "==> Done: $OUTPUT_FILE ($TOTAL_SIZE)"
