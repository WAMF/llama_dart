# llama_dart

A Dart package that provides FFI bindings to llama.cpp for running LLaMA models with a simple chat API.

## Features

- Direct FFI bindings to llama.cpp
- Simple chat-based API
- Configurable model parameters
- Example CLI application for testing

## Prerequisites

Before using this package, you need to build llama.cpp as a shared library:

```bash
# Clone llama.cpp
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp

# Build the shared library
mkdir build
cd build
cmake .. -DBUILD_SHARED_LIBS=ON
make

# Copy the library to your project
cp libllama.so /path/to/llama_dart/  # Linux
cp libllama.dylib /path/to/llama_dart/  # macOS
cp llama.dll /path/to/llama_dart/  # Windows
```

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  llama_dart:
    path: /path/to/llama_dart
```

## Usage

```dart
import 'package:llama_dart/llama_dart.dart';

void main() async {
  // Configure the model
  final config = LlamaConfig(
    modelPath: 'path/to/your/model.gguf',
    contextSize: 2048,
    threads: 4,
  );

  // Initialize the chat
  final llama = LlamaChat(config);
  llama.initialize();

  // Create a chat request
  final request = ChatRequest(
    messages: [
      ChatMessage(role: 'system', content: 'You are a helpful assistant.'),
      ChatMessage(role: 'user', content: 'Hello, how are you?'),
    ],
    temperature: 0.7,
    maxTokens: 512,
  );

  // Get the response
  final response = await llama.chat(request);
  print('Assistant: ${response.content}');
  print('Generated ${response.tokensGenerated} tokens in ${response.generationTime}');

  // Clean up
  llama.dispose();
}
```

## Running the Example CLI

```bash
# Get a LLaMA model in GGUF format
# You can download models from https://huggingface.co/TheBloke

# Run the example
dart example/chat_cli.dart path/to/model.gguf --threads 4 --temp 0.7

# Available options:
# --threads <n>      Number of threads (default: 4)
# --context <n>      Context size (default: 2048)
# --batch <n>        Batch size (default: 512)
# --temp <f>         Temperature (default: 0.7)
# --top-p <f>        Top-p sampling (default: 0.9)
# --max-tokens <n>   Max tokens to generate (default: 512)
```

## API Reference

### LlamaConfig

Configuration for the LLaMA model:

- `modelPath`: Path to the GGUF model file
- `contextSize`: Maximum context size (default: 2048)
- `batchSize`: Batch size for processing (default: 512)
- `threads`: Number of threads to use (default: 4)
- `useMmap`: Use memory mapping (default: true)
- `useMlock`: Lock model in memory (default: false)

### ChatMessage

Represents a message in the conversation:

- `role`: Either 'system', 'user', or 'assistant'
- `content`: The message content
- `timestamp`: When the message was created

### ChatRequest

Parameters for a chat completion:

- `messages`: List of messages in the conversation
- `temperature`: Sampling temperature (default: 0.7)
- `topP`: Top-p sampling parameter (default: 0.9)
- `maxTokens`: Maximum tokens to generate (default: 512)
- `repeatPenalty`: Penalty for repetition (default: 1.1)
- `repeatLastN`: Number of tokens to consider for repetition (default: 64)
- `seed`: Random seed (-1 for random)

### ChatResponse

The response from the model:

- `content`: Generated text
- `tokensGenerated`: Number of tokens generated
- `generationTime`: Time taken to generate the response

## Troubleshooting

### Library not found

Make sure the llama.cpp shared library is in one of these locations:
- `./lib/llama.so` (or .dylib/.dll)
- `./build/llama.so`
- `./llama.so`
- System library path

### Model loading fails

- Ensure the model file exists and is in GGUF format
- Check that you have enough RAM for the model
- Verify the model is compatible with your version of llama.cpp

## License

This package is provided as-is for educational and research purposes.