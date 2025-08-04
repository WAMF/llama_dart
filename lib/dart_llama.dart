
/// A Dart FFI wrapper for llama.cpp, providing high-performance local LLM inference.
/// 
/// This library provides a simple interface for running LLaMA models locally
/// in Dart applications without requiring external API calls or internet connectivity.
/// 
/// ## Features
/// 
/// - Load and run LLaMA models locally
/// - Streaming and non-streaming text generation
/// - Configurable generation parameters (temperature, top-k, top-p, etc.)
/// - Memory-efficient processing with batch support
/// - Cross-platform support (macOS, Linux, Windows)
/// 
/// ## Getting Started
/// 
/// 1. Build the native library:
/// ```bash
/// ./scripts/build_llama.sh
/// ```
/// 
/// 2. Download a model:
/// ```bash
/// ./scripts/download_gemma.sh
/// ```
/// 
/// 3. Use the library:
/// ```dart
/// import 'package:dart_llama/dart_llama.dart';
/// 
/// final config = LlamaConfig(
///   modelPath: 'path/to/model.gguf',
///   contextSize: 2048,
/// );
/// 
/// final model = LlamaModel(config);
/// model.initialize();
/// 
/// final request = GenerationRequest(
///   prompt: 'Hello, world!',
///   maxTokens: 100,
/// );
/// 
/// final response = await model.generate(request);
/// print(response.text);
/// 
/// model.dispose();
/// ```
library dart_llama;

export 'src/llama_model.dart';
export 'src/models.dart';
