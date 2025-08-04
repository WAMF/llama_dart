# Changelog

## 0.1.0 - 2025-08-04

### Initial Release

- **Core Features**
  - FFI-based Dart bindings for llama.cpp
  - High-level `LlamaChat` API for conversational interactions
  - Support for loading GGUF model files
  - Automatic memory management with RAII pattern

- **API Features**
  - Configurable model parameters (context size, batch size, threads)
  - Temperature, top-p, and repeat penalty sampling controls
  - Message history management
  - Token counting and context size tracking
  - Multi-platform library loading support

- **Developer Experience**
  - Automated FFI binding generation with ffigen
  - Comprehensive example CLI application
  - Unit and integration tests
  - Build scripts for llama.cpp compilation
  - Model download script for testing

- **Platform Support**
  - macOS (ARM64 and x86_64)
  - Linux (x86_64)
  - Windows support planned for future release
