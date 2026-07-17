#!/bin/bash
set -euo pipefail
SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIRECTORY="$(cd "$SCRIPT_DIRECTORY/.." && pwd)"
find "$PROJECT_DIRECTORY/Sources" -name '*.swift' -print0 | xargs -0 swiftc -frontend -parse
if [[ "$(uname -s)" == "Darwin" ]]; then
    cd "$PROJECT_DIRECTORY"
    swift build
fi
