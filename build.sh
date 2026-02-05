#!/bin/sh
set -e

# Usage:
#   ./build.sh wasm     # build only Wasm module against WASI
#   ./build.sh atym     # build for Wasm and push to Atym
#
MODE="${1:-both}"

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

build_wasm() {
    echo "=== Building WASM/WASI module ==="
    BUILD_DIR="${ROOT_DIR}/build"
    mkdir -p "${BUILD_DIR}"
    cd "${BUILD_DIR}"

    cmake .. \
        -DBUILD_WASM=ON \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE=/opt/wasi-sdk/share/cmake/wasi-sdk-p1.cmake

    cmake --build . -- -j

    echo
    echo "WASM build outputs:"
    ls -al *.wasm

    # inspect the module a bit
    if command -v wasm-objdump >/dev/null 2>&1; then
        wasm-objdump -x *.wasm | grep -A1 'Memory\[' || true
        wasm-objdump -x *.wasm | grep 'global\[0\]' || true
    else
        echo "wasm-objdump not found in PATH; skipping WASM inspection"
    fi

    echo "Building standalone classifier (WASM) OK"
    echo "=== WASM build done ==="
    echo
}

clean() {
    echo "=== Cleaning build directories ==="
    rm -rf "${ROOT_DIR}/build"
    echo "=== Clean done ==="
    echo
}

build_atym() {
    echo "=== Building for ATYM ==="
    ASSETS_CONT_DIR="${ROOT_DIR}/container-assets"
    
    cd "${ASSETS_CONT_DIR}"
    atym build
    atym push ei-assets -a aot.yaml

    echo

    DATA_CONT_DIR="${ROOT_DIR}/container-data"
    
    cd "${DATA_CONT_DIR}"
    atym build
    atym push ei-data -a aot.yaml

    echo

    CLASS_CONT_DIR="${ROOT_DIR}/container-classifier"
    cd "${CLASS_CONT_DIR}"
    atym build
    atym push ei-classifier -a aot.yaml

    echo
    echo "=== ATYM build done ==="
    echo
}

case "${MODE}" in
    clean)
        clean
        ;;
    wasm)
        build_wasm
        ;;
    atym)
        build_wasm
        build_atym
        ;;
    *)
        echo "Unknown mode: ${MODE}"
        echo "Usage: $0 [clean|wasm|atym]"
        exit 1
        ;;
esac
