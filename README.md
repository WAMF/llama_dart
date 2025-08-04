# llama_dart

A Dart package that provides FFI bindings to llama.cpp for running LLaMA models locally.

## Features

- **FFI-based bindings** - Direct integration with llama.cpp for maximum performance
- **Low-level API** - Full control over text generation without opinionated abstractions
- **Streaming support** - Real-time token generation with proper stop sequence handling
- **Stop sequences** - Configurable stop sequences for controlling generation boundaries
- **Configurable parameters** - Fine-tune model behavior with temperature, top-p, and repetition settings
- **Memory efficient** - Support for memory mapping and model locking
- **Cross-platform** - Works on macOS, Linux, and Windows (planned)
- **Type-safe** - Full Dart type safety with proper error handling

## Getting Started

### Prerequisites

1. **Dart SDK** - Version 3.0.0 or higher
2. **C/C++ Compiler** - For building the native wrapper
3. **CMake** - For building llama.cpp

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  llama_dart: ^1.0.0
```

### Building the Native Library

This package requires building native libraries before use. Follow these steps:

```bash
# Clone the repository
git clone https://github.com/leehiggins/llama_dart.git
cd llama_dart

# Build both llama.cpp and the wrapper library
./scripts/build_llama.sh

# The script will:
# 1. Clone/update llama.cpp submodule
# 2. Build llama.cpp as a shared library (libllama.dylib/so/dll)
# 3. Build the wrapper library (libllama_wrapper.dylib/so/dll)

# Optional: Download a test model (Gemma 3 1B)
./scripts/download_gemma.sh
```

#### Manual Build (Advanced)

If you need to rebuild just the wrapper after making changes:

```bash
./scripts/build_wrapper.sh
```

Or build manually:

```bash
# macOS
clang -shared -fPIC -o libllama_wrapper.dylib llama_wrapper.c \
    -I./llama.cpp/include -L. -lllama -std=c11

# Linux
gcc -shared -fPIC -o libllama_wrapper.so llama_wrapper.c \
    -I./llama.cpp/include -L. -lllama -std=c11

# Windows
gcc -shared -o llama_wrapper.dll llama_wrapper.c \
    -I./llama.cpp/include -L. -lllama -std=c11
```

## Usage

### Low-Level Text Generation API (Recommended)

The `LlamaModel` class provides direct access to text generation without any chat-specific formatting:

```dart
import 'package:llama_dart/llama_dart.dart';

void main() async {
  // Create configuration
  final config = LlamaConfig(
    modelPath: 'models/gemma-3-1b-it-Q4_K_M.gguf',
    contextSize: 2048,
    threads: 4,
  );

  // Initialize the model
  final model = LlamaModel(config);
  model.initialize();

  // Create a generation request
  final request = GenerationRequest(
    prompt: 'Once upon a time in a galaxy far, far away',
    temperature: 0.7,
    maxTokens: 256,
  );

  // Generate text
  final response = await model.generate(request);
  print(response.text);

  // Clean up
  model.dispose();
}
```

### Streaming Generation

```dart
// Stream tokens as they are generated
final request = GenerationRequest(
  prompt: 'Write a haiku about programming',
  temperature: 0.8,
  maxTokens: 50,
);

await for (final token in model.generateStream(request)) {
  stdout.write(token);
}
```

### Building Chat Interfaces

Different models expect different chat formats. Use the low-level `LlamaModel` API to implement model-specific formatting:

```dart
// Example: Gemma chat format
String buildGemmaPrompt(List<ChatMessage> messages) {
  final buffer = StringBuffer();
  
  // Gemma requires <bos> token at the beginning
  buffer.write('<bos>');
  
  for (final message in messages) {
    if (message.role == 'user') {
      buffer
        ..writeln('<start_of_turn>user')
        ..writeln(message.content)
        ..writeln('<end_of_turn>');
    } else if (message.role == 'assistant') {
      buffer
        ..writeln('<start_of_turn>model')
        ..writeln(message.content)
        ..writeln('<end_of_turn>');
    }
  }
  
  buffer.write('<start_of_turn>model\n');
  return buffer.toString();
}

// Use with LlamaModel and stop sequences
final prompt = buildGemmaPrompt(messages);
final request = GenerationRequest(
  prompt: prompt,
  stopSequences: ['<end_of_turn>'], // Stop at turn boundaries
);
final response = await model.generate(request);
```

See `example/gemma_chat.dart` for a complete Gemma chat implementation.


## Configuration

### Model Configuration

```dart
final config = LlamaConfig(
  modelPath: 'model.gguf',
  
  // Context and performance
  contextSize: 4096,        // Maximum context window
  batchSize: 2048,         // Batch size for processing
  threads: 8,              // Number of CPU threads
  
  // Memory options
  useMmap: true,           // Memory-map the model
  useMlock: false,         // Lock model in RAM
);

final model = LlamaModel(config);
```

### Generation Parameters

```dart
final request = GenerationRequest(
  prompt: 'Your prompt here',
  
  // Sampling parameters
  temperature: 0.7,        // Creativity level (0.0-1.0)
  topP: 0.9,              // Nucleus sampling threshold
  topK: 40,               // Top-k sampling
  
  // Generation control
  maxTokens: 512,          // Maximum tokens to generate
  repeatPenalty: 1.1,      // Repetition penalty
  repeatLastN: 64,         // Context for repetition check
  seed: -1,               // Random seed (-1 for random)
);
```

## Examples

### Text Completion
```bash
# Simple completion
dart example/completion.dart model.gguf "Once upon a time"

# With streaming
dart example/completion.dart model.gguf "Write a poem about" --stream
```

### Gemma Chat
```bash
# Interactive Gemma chat
dart example/gemma_chat.dart models/gemma-3-1b-it-Q4_K_M.gguf

# With custom settings
dart example/gemma_chat.dart model.gguf \
  --threads 8 \
  --context 4096 \
  --temp 0.8 \
  --max-tokens 1024 \
  --stream
```


## API Documentation

### LlamaModel

Low-level interface for text generation:

- `LlamaModel(config)` - Create a new model instance
- `initialize()` - Initialize the model and context
- `generate(request, {onToken})` - Generate text with optional token callback
- `generateStream(request)` - Generate text as a stream of tokens
- `dispose()` - Clean up resources

### LlamaConfig

Configuration for the LLaMA model:

```dart
LlamaConfig({
  required String modelPath,   // Path to GGUF model file
  int contextSize = 2048,      // Maximum context window
  int batchSize = 2048,        // Batch size for processing
  int threads = 4,             // Number of CPU threads
  bool useMmap = true,         // Memory-map the model
  bool useMlock = false,       // Lock model in RAM
})
```

### GenerationRequest

Parameters for text generation:

```dart
GenerationRequest({
  required String prompt,               // Input text prompt
  int maxTokens = 512,                 // Maximum tokens to generate
  double temperature = 0.7,             // Creativity (0.0-1.0)
  double topP = 0.9,                   // Nucleus sampling threshold
  int topK = 40,                       // Top-k sampling
  double repeatPenalty = 1.1,          // Repetition penalty
  int repeatLastN = 64,                // Context for repetition check
  int seed = -1,                       // Random seed (-1 for random)
  List<String> stopSequences = const [],// Stop generation at these sequences
})
```

### GenerationResponse

Response from text generation:

```dart
GenerationResponse({
  String text,                         // Generated text
  int promptTokens,                    // Number of prompt tokens
  int generatedTokens,                 // Number of generated tokens
  int totalTokens,                     // Total tokens processed
  Duration generationTime,             // Time taken to generate
})
```



## Platform Support

| Platform | Status | Architecture |
|----------|--------|--------------|
| macOS    | ✅ Supported | arm64, x86_64 |
| Linux    | ✅ Supported | x86_64 |
| Windows  | 🚧 Planned | x86_64 |

## Troubleshooting

### Library Not Found

If you get a library loading error:

1. Ensure you've run `./scripts/build_llama.sh` to build both libraries
2. Check that both libraries exist in the project root:
   - `libllama.dylib` (or `.so` on Linux, `.dll` on Windows)
   - `libllama_wrapper.dylib` (or `.so` on Linux, `.dll` on Windows)
3. On Linux, you may need to set `LD_LIBRARY_PATH`:
   ```bash
   export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.
   ```

### Model Loading Issues

- Verify the model is in GGUF format
- Ensure you have enough RAM (model size + overhead)
- Check model compatibility with your llama.cpp version

### Performance Tips

- Use more threads for faster generation
- Enable `useMmap` for faster model loading
- Adjust `batchSize` based on your hardware
- Use quantized models for better performance

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Run tests: `dart test`
4. Run analysis: `dart analyze`
5. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Acknowledgments

- [llama.cpp](https://github.com/ggerganov/llama.cpp) - The underlying inference engine
- The Dart FFI team for excellent documentation
- The open-source AI community