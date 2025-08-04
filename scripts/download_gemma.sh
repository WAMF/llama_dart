#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Get the project root directory (parent of scripts)
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Download Gemma 3 1B GGUF model
MODEL_DIR="$PROJECT_ROOT/models"
MODEL_URL="https://huggingface.co/lmstudio-community/gemma-3-1b-it-GGUF/resolve/main/gemma-3-1b-it-Q4_K_M.gguf"
MODEL_NAME="gemma-3-1b-it-Q4_K_M.gguf"

echo "Project root: $PROJECT_ROOT"
echo "Creating models directory..."
mkdir -p "$MODEL_DIR"

echo "Downloading Gemma model from Hugging Face..."
echo "This may take a few minutes depending on your connection speed..."

if command -v wget &> /dev/null; then
    wget -O "$MODEL_DIR/$MODEL_NAME" "$MODEL_URL" --show-progress
elif command -v curl &> /dev/null; then
    curl -L -o "$MODEL_DIR/$MODEL_NAME" "$MODEL_URL" --progress-bar
else
    echo "Error: Neither wget nor curl is installed. Please install one of them."
    exit 1
fi

if [ -f "$MODEL_DIR/$MODEL_NAME" ]; then
    echo "Model downloaded successfully to: $MODEL_DIR/$MODEL_NAME"
    echo "File size: $(ls -lh "$MODEL_DIR/$MODEL_NAME" | awk '{print $5}')"
else
    echo "Error: Failed to download the model"
    exit 1
fi