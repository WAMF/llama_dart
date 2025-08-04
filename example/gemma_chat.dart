import 'dart:io';

import 'package:llama_dart/llama_dart.dart';

/// Simple chat message representation for this example.
class ChatMessage {
  ChatMessage({required this.role, required this.content});
  
  final String role; // 'system', 'user', or 'assistant'
  final String content;
}

/// Example of using LlamaModel with Gemma-specific chat formatting.
/// 
/// This demonstrates how to build a chat interface on top of the low-level
/// LlamaModel API using Gemma's expected conversation format.
void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart gemma_chat.dart <model_path> [options]');
    print('Options:');
    print('  --threads <n>      Number of threads (default: 4)');
    print('  --context <n>      Context size (default: 2048)');
    print('  --batch <n>        Batch size (default: 2048)');
    print('  --temp <f>         Temperature (default: 0.7)');
    print('  --max-tokens <n>   Max tokens to generate (default: 512)');
    print('  --stream           Enable streaming output');
    exit(1);
  }

  final modelPath = args[0];
  var threads = 4;
  var contextSize = 2048;
  var batchSize = 2048;
  var temperature = 0.7;
  var maxTokens = 512;
  var enableStreaming = false;

  // Parse arguments
  for (var i = 1; i < args.length; i++) {
    switch (args[i]) {
      case '--threads':
        threads = int.parse(args[++i]);
      case '--context':
        contextSize = int.parse(args[++i]);
      case '--batch':
        batchSize = int.parse(args[++i]);
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
    batchSize: batchSize,
    threads: threads,
  );

  final model = LlamaModel(config);
  
  try {
    print('Loading model from $modelPath...');
    model.initialize();
    print('Model loaded successfully!');
    print('');
    print('Chat with Gemma model. Type "exit" to quit, "clear" to reset.');
    print('');

    final messages = <ChatMessage>[
      ChatMessage(
        role: 'system',
        content: 'You are a helpful AI assistant.',
      ),
    ];

    while (true) {
      stdout.write('You: ');
      final input = stdin.readLineSync();
      
      if (input == null || input.toLowerCase() == 'exit') {
        break;
      }
      
      if (input.toLowerCase() == 'clear') {
        messages
          ..clear()
          ..add(ChatMessage(
            role: 'system',
            content: 'You are a helpful AI assistant.',
          ));
        print('Conversation history cleared.');
        continue;
      }

      // Add user message
      messages.add(ChatMessage(
        role: 'user',
        content: input,
      ));

      // Build Gemma-formatted prompt
      final prompt = _buildGemmaPrompt(messages);
      
      final request = GenerationRequest(
        prompt: prompt,
        temperature: temperature,
        maxTokens: maxTokens,
        stopSequences: ['<end_of_turn>'],
      );

      try {
        if (enableStreaming) {
          stdout.write('Assistant: ');
          final responseBuffer = StringBuffer();
          final startTime = DateTime.now();
          
          await for (final token in model.generateStream(request)) {
            // The token might already be trimmed if it contained a stop sequence
            stdout.write(token);
            responseBuffer.write(token);
          }
          
          final endTime = DateTime.now();
          final duration = endTime.difference(startTime);
          
          print('');
          print('(Streamed response in ${duration.inMilliseconds}ms)');
          print('');

          // The response should already be trimmed by the stream, but double-check
          var responseText = responseBuffer.toString();
          for (final stopSeq in request.stopSequences) {
            final stopIndex = responseText.indexOf(stopSeq);
            if (stopIndex >= 0) {
              responseText = responseText.substring(0, stopIndex);
            }
          }
          
          // Add assistant response to history
          messages.add(ChatMessage(
            role: 'assistant',
            content: responseText.trim(),
          ));
        } else {
          final response = await model.generate(request);
          
          print('Assistant: ${response.text.trim()}');
          print('');
          print(
            '(Generated ${response.generatedTokens} tokens '
            'in ${response.generationTime.inMilliseconds}ms)',
          );
          print('');

          // Add assistant response to history
          messages.add(ChatMessage(
            role: 'assistant',
            content: response.text.trim(),
          ));
        }
      } on Exception catch (e) {
        print('Error: $e');
      }
    }
  } on Exception catch (e) {
    print('Error initializing model: $e');
    exit(1);
  } finally {
    model.dispose();
  }
  
  print('Goodbye!');
}

/// Build a Gemma-formatted prompt from chat messages.
String _buildGemmaPrompt(List<ChatMessage> messages) {
  final buffer = StringBuffer();
  
  // Gemma requires a <bos> token at the beginning
  buffer.write('<bos>');

  // Keep system message if present
  var messagesToUse = messages;
  if (messages.isNotEmpty && messages.first.role == 'system') {
    // Include system message as part of the first user turn
    buffer
      ..writeln('<start_of_turn>user')
      ..writeln(messages.first.content);
    
    if (messagesToUse.length > 1 && messagesToUse[1].role == 'user') {
      buffer.writeln(messagesToUse[1].content);
      messagesToUse = messagesToUse.skip(2).toList();
    } else {
      messagesToUse = messagesToUse.skip(1).toList();
    }
    buffer.writeln('<end_of_turn>');
  }

  // Build conversation history using Gemma format
  for (final message in messagesToUse) {
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

  // Start the model's turn
  buffer.write('<start_of_turn>model\n');
  
  return buffer.toString();
}
