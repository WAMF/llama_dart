# llama_dart

A Dart package that provides FFI bindings to llama.cpp for running LLaMA models with a simple chat API.

## Features

- **FFI-based bindings** - Direct integration with llama.cpp for maximum performance
- **Simple chat API** - High-level interface for conversational AI
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

### Basic Example

```dart
import 'package:llama_dart/llama_dart.dart';

void main() async {
  // Initialize the chat with a model
  final chat = LlamaChat(
    modelPath: 'models/gemma-3-1b-it-Q4_K_M.gguf',
    contextSize: 2048,
    threads: 4,
  );

  // Send a message
  final response = await chat.generateResponse(
    'Tell me a short story about a robot.',
    temperature: 0.7,
    maxTokens: 256,
  );

  print(response);

  // Clean up
  chat.dispose();
}
```

### Conversation Example

```dart
final chat = LlamaChat(
  modelPath: 'path/to/model.gguf',
  contextSize: 4096,
);

// Add system prompt
chat.addMessage(ChatMessage(
  role: 'system',
  content: 'You are a helpful coding assistant.',
));

// Have a conversation
chat.addMessage(ChatMessage(
  role: 'user',
  content: 'How do I read a file in Dart?',
));

final response = await chat.generateResponse();
print(response);

// Continue the conversation
chat.addMessage(ChatMessage(
  role: 'user',
  content: 'Can you show me an async example?',
));

final followUp = await chat.generateResponse();
print(followUp);
```

### Streaming Example

```dart
final chat = LlamaChat(
  modelPath: 'path/to/model.gguf',
  contextSize: 2048,
);

// Stream tokens as they are generated
final request = ChatRequest(
  messages: [
    ChatMessage(role: 'user', content: 'Write a haiku about programming'),
  ],
);

await for (final token in chat.chatStream(request)) {
  stdout.write(token);
}

// Or use callback-based streaming
await chat.chat(
  request,
  onToken: (token) {
    stdout.write(token);
  },
);
```

## Configuration

### Model Parameters

```dart
final chat = LlamaChat(
  modelPath: 'model.gguf',
  
  // Context and performance
  contextSize: 4096,        // Maximum context window
  batchSize: 512,          // Batch size for processing
  threads: 8,              // Number of CPU threads
  
  // Memory options
  useMmap: true,           // Memory-map the model
  useMlock: false,         // Lock model in RAM
  
  // Generation defaults
  temperature: 0.7,        // Creativity level (0.0-1.0)
  topP: 0.9,              // Nucleus sampling threshold
  repeatPenalty: 1.1,      // Repetition penalty
  seed: -1,               // -1 for random seed
);
```

## Example CLI

Try the included CLI example:

```bash
# Basic usage
dart example/chat_cli.dart models/gemma-3-1b-it-Q4_K_M.gguf

# With custom settings
dart example/chat_cli.dart model.gguf \
  --threads 8 \
  --context 4096 \
  --temp 0.8 \
  --max-tokens 1024 \
  --stream
```

## API Documentation

### LlamaChat

The main class for interacting with models:

- `LlamaChat()` - Create a new chat instance
- `chat()` - Generate a response with optional streaming callback
- `chatStream()` - Generate a response as a stream of tokens
- `dispose()` - Clean up resources

Methods:
- `chat(request, {onToken})` - Generate response with optional token callback
- `chatStream(request)` - Returns a Stream<String> of generated tokens

### ChatMessage

Represents a message in the conversation:

```dart
ChatMessage({
  required String role,      // 'system', 'user', or 'assistant'
  required String content,   // Message text
  DateTime? timestamp,       // Optional timestamp
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