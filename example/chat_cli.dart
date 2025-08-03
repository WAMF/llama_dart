import 'dart:io';
import 'package:llama_dart/llama_dart.dart';

void main(List<String> args) async {
  final defaultModelPath = 'models/gemma-3-1b-it-Q4_K_M.gguf';
  
  String modelPath;
  if (args.isEmpty) {
    if (File(defaultModelPath).existsSync()) {
      modelPath = defaultModelPath;
      print('Using default model: $modelPath');
    } else {
      print('Usage: dart chat_cli.dart [model_path] [options]');
      print('Default model not found at: $defaultModelPath');
      print('Run ./download_gemma.sh to download the default model');
      print('Options:');
      print('  --threads <n>      Number of threads (default: 4)');
      print('  --context <n>      Context size (default: 2048)');
      print('  --batch <n>        Batch size (default: 512)');
      print('  --temp <f>         Temperature (default: 0.7)');
      print('  --top-p <f>        Top-p sampling (default: 0.9)');
      print('  --max-tokens <n>   Max tokens to generate (default: 512)');
      exit(1);
    }
  } else {
    modelPath = args[0];
  }
  
  var threads = 4;
  var contextSize = 2048;
  var batchSize = 512;
  var temperature = 0.7;
  var topP = 0.9;
  var maxTokens = 512;

  for (var i = 1; i < args.length; i++) {
    switch (args[i]) {
      case '--threads':
        threads = int.parse(args[++i]);
        break;
      case '--context':
        contextSize = int.parse(args[++i]);
        break;
      case '--batch':
        batchSize = int.parse(args[++i]);
        break;
      case '--temp':
        temperature = double.parse(args[++i]);
        break;
      case '--top-p':
        topP = double.parse(args[++i]);
        break;
      case '--max-tokens':
        maxTokens = int.parse(args[++i]);
        break;
    }
  }

  if (!File(modelPath).existsSync()) {
    print('Error: Model file not found at: $modelPath');
    if (modelPath != defaultModelPath) {
      print('You can also run ./download_gemma.sh to download the default model');
    }
    exit(1);
  }

  print('Initializing LLaMA model...');
  print('Model: $modelPath');
  print('Threads: $threads');
  print('Context: $contextSize');
  print('Temperature: $temperature');
  print('Top-p: $topP');
  print('Max tokens: $maxTokens');
  print('');

  final config = LlamaConfig(
    modelPath: modelPath,
    contextSize: contextSize,
    batchSize: batchSize,
    threads: threads,
  );

  final llama = LlamaChat(config);
  
  try {
    llama.initialize();
    print('Model loaded successfully!');
    print('Type "exit" to quit, "clear" to clear history');
    print('');

    final messages = <ChatMessage>[];
    
    messages.add(ChatMessage(
      role: 'system',
      content: 'You are a helpful AI assistant.',
    ));

    while (true) {
      stdout.write('You: ');
      final input = stdin.readLineSync();
      
      if (input == null || input.trim().isEmpty) continue;
      
      if (input.toLowerCase() == 'exit') {
        break;
      }
      
      if (input.toLowerCase() == 'clear') {
        messages.clear();
        messages.add(ChatMessage(
          role: 'system',
          content: 'You are a helpful AI assistant.',
        ));
        print('Conversation history cleared.');
        continue;
      }

      messages.add(ChatMessage(
        role: 'user',
        content: input,
      ));

      stdout.write('Assistant: ');
      
      final request = ChatRequest(
        messages: messages,
        temperature: temperature,
        topP: topP,
        maxTokens: maxTokens,
      );

      try {
        final response = await llama.chat(request);
        
        print(response.content.trimRight());
        print('');
        print('(Generated ${response.tokensGenerated} tokens in ${response.generationTime.inMilliseconds}ms)');
        print('');

        messages.add(ChatMessage(
          role: 'assistant',
          content: response.content.trimRight(),
        ));
      } catch (e) {
        print('Error: $e');
      }
    }
  } catch (e) {
    print('Error initializing model: $e');
    exit(1);
  } finally {
    llama.dispose();
  }
  
  print('Goodbye!');
}