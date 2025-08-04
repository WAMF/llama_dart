# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Development Commands

```bash
# Initial setup
./scripts/build_llama.sh          # Build llama.cpp shared library (required)
./scripts/download_gemma.sh       # Download Gemma 3 1B model for testing
dart pub get                      # Install Dart dependencies

# Development workflow
dart run ffigen           # Regenerate FFI bindings after changing llama_wrapper.h
dart analyze              # Run static analysis
dart fix --apply          # Apply automatic fixes
dart format .             # Format code

# Testing
dart test                                    # Run all tests
dart test test/llama_bindings_test.dart     # Unit tests only
dart test test/gemma_integration_test.dart  # Integration tests only

# Run example
dart example/chat_cli.dart  # Interactive chat CLI
```

## Architecture Overview

### FFI Layer Structure
The project uses a three-layer FFI architecture:

1. **C Wrapper** (`llama_wrapper.h/.c`) - Simplifies llama.cpp's C++ API into C-compatible functions
2. **Generated Bindings** (`lib/src/ffi/llama_bindings_generated.dart`) - Auto-generated via ffigen
3. **Dart API** (`lib/src/llama_chat.dart`) - High-level object-oriented interface

### Key Components

- **LlamaChat** - Main class for chat interactions, handles model loading, context management, and generation
- **llama_wrapper** - C wrapper providing simplified access to llama.cpp functions
- **Models** (`lib/src/models.dart`) - Data structures for messages and conversations
- **FFI Bindings** - Both manual (`llama_bindings.dart`) and generated (`llama_bindings_generated.dart`)

### Memory Management Pattern
All classes follow RAII pattern with proper `dispose()` methods:
- Model pointer cleanup: `llama_free_model_wrapper()`
- Context cleanup: `llama_free_wrapper()`
- Sampler cleanup: `llama_sampler_free_wrapper()`
- Batch cleanup: `llama_batch_free_wrapper()`

### Library Loading
The code searches for libraries in this order:
1. `libllama_wrapper.dylib` (primary)
2. `lib/llama.dylib`
3. `build/llama.dylib`
4. `llama.dylib`
5. System library paths

## Important Implementation Details

### Token IDs
Hard-coded in wrapper (may need updating for different models):
- BOS (Beginning of Sequence): 1
- EOS (End of Sequence): 2
- NL (Newline): 13

### FFI Regeneration
When modifying `llama_wrapper.h`:
1. Update the header file
2. Run `dart run ffigen`
3. Check generated bindings in `lib/src/ffi/llama_bindings_generated.dart`

### Testing Requirements
- Integration tests require Gemma model (`./scripts/download_gemma.sh`)
- All tests require built shared library (`./scripts/build_llama.sh`)
- Tests verify tokenization, parameter defaults, and conversation handling