#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Get the project root directory (parent of scripts)
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "Building llama_wrapper library..."
echo "Project root: $PROJECT_ROOT"

# Change to project root
cd "$PROJECT_ROOT"

# Check if llama library exists
if [ ! -f "libllama.dylib" ] && [ ! -f "libllama.so" ] && [ ! -f "llama.dll" ]; then
    echo "Error: llama library not found. Please run build_llama.sh first."
    exit 1
fi

# Compile the wrapper library
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    echo "Building for macOS..."
    clang -shared -fPIC -o libllama_wrapper.dylib llama_wrapper.c \
        -I./llama.cpp/include -I./llama.cpp/ggml/include -L. -lllama -std=c11 \
        -Wl,-rpath,@loader_path
    if [ -f "libllama_wrapper.dylib" ]; then
        echo "Wrapper library built: libllama_wrapper.dylib"
    else
        echo "Error: Failed to build wrapper library"
        exit 1
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    echo "Building for Linux..."
    gcc -shared -fPIC -o libllama_wrapper.so llama_wrapper.c \
        -I./llama.cpp/include -I./llama.cpp/ggml/include -L. -lllama -std=c11
    if [ -f "libllama_wrapper.so" ]; then
        echo "Wrapper library built: libllama_wrapper.so"
    else
        echo "Error: Failed to build wrapper library"
        exit 1
    fi
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    # Windows
    echo "Building for Windows..."
    gcc -shared -o llama_wrapper.dll llama_wrapper.c \
        -I./llama.cpp/include -I./llama.cpp/ggml/include -L. -lllama -std=c11
    if [ -f "llama_wrapper.dll" ]; then
        echo "Wrapper library built: llama_wrapper.dll"
    else
        echo "Error: Failed to build wrapper library"
        exit 1
    fi
else
    echo "Error: Unsupported operating system"
    exit 1
fi

echo "Build complete!"