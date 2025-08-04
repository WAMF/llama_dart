#!/bin/bash
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Get the project root directory (parent of scripts)
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "Building llama.cpp library..."
echo "Project root: $PROJECT_ROOT"

# Change to project root
cd "$PROJECT_ROOT"

# Clone llama.cpp if it doesn't exist
if [ ! -d "llama.cpp" ]; then
    echo "Cloning llama.cpp..."
    git clone https://github.com/ggerganov/llama.cpp.git
fi

cd llama.cpp

# Update to latest
echo "Updating llama.cpp..."
git pull

# Build the shared library
echo "Building shared library..."
mkdir -p build
cd build
cmake .. -DBUILD_SHARED_LIBS=ON -DLLAMA_METAL=OFF
make -j8

# Copy the library to the project root
echo "Copying library to project root..."
if [ -f "bin/libllama.dylib" ]; then
    cp bin/libllama.dylib "$PROJECT_ROOT/"
    echo "Library copied to: $PROJECT_ROOT/libllama.dylib"
elif [ -f "libllama.dylib" ]; then
    cp libllama.dylib "$PROJECT_ROOT/"
    echo "Library copied to: $PROJECT_ROOT/libllama.dylib"
elif [ -f "libllama.so" ]; then
    cp libllama.so "$PROJECT_ROOT/"
    echo "Library copied to: $PROJECT_ROOT/libllama.so"
elif [ -f "llama.dll" ]; then
    cp llama.dll "$PROJECT_ROOT/"
    echo "Library copied to: $PROJECT_ROOT/llama.dll"
else
    echo "Error: Could not find built library"
    exit 1
fi

echo "llama.cpp build complete!"

# Build the wrapper library using the dedicated script
echo ""
echo "Building llama_wrapper library..."
cd "$PROJECT_ROOT"
"$SCRIPT_DIR/build_wrapper.sh"

echo ""
echo "Build complete!"