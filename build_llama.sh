#!/bin/bash

echo "Building llama.cpp library..."

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

# Copy the library to the parent directory
echo "Copying library..."
if [ -f "bin/libllama.dylib" ]; then
    cp bin/libllama.dylib ../../
    echo "Library copied to: ../libllama.dylib"
elif [ -f "libllama.dylib" ]; then
    cp libllama.dylib ../../
    echo "Library copied to: ../libllama.dylib"
elif [ -f "libllama.so" ]; then
    cp libllama.so ../../
    echo "Library copied to: ../libllama.so"
elif [ -f "llama.dll" ]; then
    cp llama.dll ../../
    echo "Library copied to: ../llama.dll"
else
    echo "Error: Could not find built library"
    exit 1
fi

echo "Build complete!"