import 'dart:io';
import 'package:test/test.dart';
import 'package:llama_dart/llama_dart.dart';

void main() {
  group('Gemma 1B Integration Test', () {
    late LlamaChat chat;
    final modelPath = 'models/gemma-3-1b-it-Q4_K_M.gguf';

    setUpAll(() {
      if (!File(modelPath).existsSync()) {
        fail('Model file not found at $modelPath. Run ./download_gemma.sh first.');
      }
      
      // The library will be found via the updated _getLibraryPath method
      
      final config = LlamaConfig(
        modelPath: modelPath,
        contextSize: 2048,
        batchSize: 512,
        threads: 4,
      );
      
      chat = LlamaChat(config);
      chat.initialize();
    });

    tearDownAll(() {
      chat.dispose();
    });

    test('can generate text response', () async {
      final request = ChatRequest(
        messages: [
          ChatMessage(
            role: 'user',
            content: 'What is 2 + 2?',
          ),
        ],
        maxTokens: 100,
        temperature: 0.7,
      );

      final response = await chat.chat(request);
      
      expect(response.content, isNotEmpty);
      expect(response.tokensGenerated, greaterThan(0));
      expect(response.generationTime.inMilliseconds, greaterThan(0));
      
      print('Response: ${response.content}');
      print('Tokens generated: ${response.tokensGenerated}');
      print('Generation time: ${response.generationTime}');
    });

    test('can handle conversation context', () async {
      final messages = [
        ChatMessage(role: 'user', content: 'My name is Alice.'),
        ChatMessage(role: 'assistant', content: 'Nice to meet you, Alice!'),
        ChatMessage(role: 'user', content: 'What is my name?'),
      ];

      final request = ChatRequest(
        messages: messages,
        maxTokens: 50,
        temperature: 0.5,
      );

      final response = await chat.chat(request);
      
      expect(response.content.toLowerCase(), contains('alice'));
      print('Context response: ${response.content}');
    });

    test('can handle system prompts', () async {
      final request = ChatRequest(
        messages: [
          ChatMessage(
            role: 'system',
            content: 'You are a helpful math tutor. Always explain your steps.',
          ),
          ChatMessage(
            role: 'user',
            content: 'What is 15 divided by 3?',
          ),
        ],
        maxTokens: 150,
        temperature: 0.7,
      );

      final response = await chat.chat(request);
      
      expect(response.content, isNotEmpty);
      expect(response.content.toLowerCase(), anyOf(
        contains('5'),
        contains('five'),
      ));
      
      print('Math tutor response: ${response.content}');
    });

    test('respects max tokens limit', () async {
      final request = ChatRequest(
        messages: [
          ChatMessage(
            role: 'user',
            content: 'Tell me a very long story about dragons.',
          ),
        ],
        maxTokens: 20,
        temperature: 0.8,
      );

      final response = await chat.chat(request);
      
      expect(response.tokensGenerated, lessThanOrEqualTo(20));
      print('Limited response: ${response.content}');
      print('Tokens: ${response.tokensGenerated}');
    });
  });
}