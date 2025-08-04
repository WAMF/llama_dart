# Changelog

## 0.1.1 - 2025-08-04

### Documentation

- Added comprehensive documentation comments to all public API elements
- Added library-level documentation with examples and getting started guide
- Documented all `GenerationRequest` parameters with usage guidance
- Documented all `LlamaConfig` parameters with recommendations
- Improved overall API documentation coverage from 26.5% to 100%

## 0.1.0 - 2025-08-04

### Initial Release

- **Core Features**
  - FFI-based Dart bindings for llama.cpp
  - Low-level `LlamaModel` API for direct text generation control
  - Support for loading GGUF model files
  - Automatic memory management with proper cleanup
  - Real-time streaming support with token-by-token generation
  - Configurable stop sequences for controlling generation boundaries

- **API Features**
  - `LlamaModel` - Main class for model initialization and text generation
  - `GenerationRequest` - Configurable generation parameters
  - `GenerationResponse` - Detailed generation results with token counts
  - Streaming and non-streaming generation modes
  - Temperature, top-p, top-k, and repeat penalty sampling controls
  - Random seed support for reproducible generation
  - Token counting and generation time tracking

- **Stop Sequence Support**
  - Configurable stop sequences in `GenerationRequest`
  - Proper handling of stop sequences split across multiple tokens
  - Automatic trimming of stop sequences from output
  - Works correctly in both streaming and non-streaming modes

- **Memory Management**
  - Fixed double-free error in sampler disposal
  - Proper lifecycle management for all native resources
  - RAII pattern with reliable `dispose()` methods

- **Examples**
  - `example/completion.dart` - Simple text completion with streaming support
  - `example/gemma_chat.dart` - Full Gemma chat implementation with proper formatting

- **Developer Experience**
  - Automated FFI binding generation with ffigen
  - Comprehensive build scripts for llama.cpp compilation
  - Model download script for testing (Gemma 3 1B)
  - Unit and integration tests
  - Code quality enforcement with very_good_analysis

- **Platform Support**
  - macOS (ARM64 and x86_64) with Metal acceleration
  - Linux (x86_64)
  - Windows support planned for future release
