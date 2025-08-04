import 'dart:io';

import 'package:llama_dart/llama_dart.dart';

/// Simple text completion example using the low-level LlamaModel API.
void main(List<String> args) async {
  if (args.length < 2) {
    print('Usage: dart completion.dart <model_path> <prompt> [options]');
    print('Options:');
    print('  --threads <n>      Number of threads (default: 4)');
    print('  --context <n>      Context size (default: 2048)');
    print('  --temp <f>         Temperature (default: 0.7)');
    print('  --max-tokens <n>   Max tokens to generate (default: 100)');
    print('  --stream           Enable streaming output');
    exit(1);
  }

  final modelPath = args[0];
  final prompt = args[1];
  
  var threads = 4;
  var contextSize = 2048;
  var temperature = 0.7;
  var maxTokens = 100;
  var enableStreaming = false;

  // Parse optional arguments
  for (var i = 2; i < args.length; i++) {
    switch (args[i]) {
      case '--threads':
        threads = int.parse(args[++i]);
      case '--context':
        contextSize = int.parse(args[++i]);
      case '--temp':
        temperature = double.parse(args[++i]);
      case '--max-tokens':
        maxTokens = int.parse(args[++i]);
      case '--stream':
        enableStreaming = true;
    }
  }

  // Initialize model
  final config = LlamaConfig(
    modelPath: modelPath,
    contextSize: contextSize,
    threads: threads,
  );

  final model = LlamaModel(config);
  
  try {
    print('Loading model...');
    model.initialize();
    
    final request = GenerationRequest(
      prompt: prompt,
      temperature: temperature,
      maxTokens: maxTokens,
    );

    print('\nPrompt: $prompt');
    print('\nCompletion:');
    
    if (enableStreaming) {
      // Stream tokens as they are generated
      await for (final token in model.generateStream(request)) {
        stdout.write(token);
      }
      print(''); // Final newline
    } else {
      // Generate all at once
      final response = await model.generate(request);
      print(response.text);
      print('\n---');
      print('Prompt tokens: ${response.promptTokens}');
      print('Generated tokens: ${response.generatedTokens}');
      print('Total tokens: ${response.totalTokens}');
      print('Time: ${response.generationTime.inMilliseconds}ms');
    }
  } on Exception catch (e) {
    print('Error: $e');
    exit(1);
  } finally {
    model.dispose();
  }
}
