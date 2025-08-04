import 'dart:io';

import 'package:dart_llama/dart_llama.dart';
import 'package:test/test.dart';

const testModelPath = './models/gemma-3-1b-it-Q4_K_M.gguf';

void main() {
  group('Gemma Integration Test', () {
    test('can generate text with gemma model', () async {
      // Skip if model not available
      if (!File(testModelPath).existsSync()) {
        print('Test model not found at $testModelPath');
        print('Run ./scripts/download_gemma.sh to download test model');
        return;
      }

      final config = LlamaConfig(
        modelPath: testModelPath,
      );

      final model = LlamaModel(config)..initialize();

      try {
        // Test simple completion
        final request = GenerationRequest(
          prompt: 'The capital of France is',
          maxTokens: 10,
          temperature: 0.1, // Low temperature for consistent output
        );

        final response = await model.generate(request);

        expect(response.text, isNotEmpty);
        expect(response.promptTokens, greaterThan(0));
        expect(response.generatedTokens, greaterThan(0));
        expect(response.generationTime, isNotNull);

        print('Generated: ${response.text}');
        print('Prompt tokens: ${response.promptTokens}');
        print('Generated tokens: ${response.generatedTokens}');
        print('Time: ${response.generationTime.inMilliseconds}ms');
      } finally {
        model.dispose();
      }
    });

    test('can stream tokens', () async {
      // Skip if model not available
      if (!File(testModelPath).existsSync()) {
        return;
      }

      final config = LlamaConfig(
        modelPath: testModelPath,
      );

      final model = LlamaModel(config);
      model.initialize();

      try {
        final request = GenerationRequest(
          prompt: 'Count from 1 to 5:',
          maxTokens: 20,
          temperature: 0.1,
        );

        final tokens = <String>[];
        await for (final token in model.generateStream(request)) {
          tokens.add(token);
        }

        expect(tokens, isNotEmpty);
        final fullText = tokens.join();
        expect(fullText, isNotEmpty);

        print('Streamed ${tokens.length} tokens: $fullText');
      } finally {
        model.dispose();
      }
    });

    test('can handle gemma chat format', () async {
      // Skip if model not available
      if (!File(testModelPath).existsSync()) {
        return;
      }

      final config = LlamaConfig(
        modelPath: testModelPath,
      );

      final model = LlamaModel(config);
      model.initialize();

      try {
        // Build Gemma chat prompt
        const prompt = '''
<start_of_turn>user
Hello! Can you help me?
<end_of_turn>
<start_of_turn>model
''';

        final request = GenerationRequest(
          prompt: prompt,
          maxTokens: 50,
        );

        final response = await model.generate(request);

        expect(response.text, isNotEmpty);
        print('Chat response: ${response.text}');
      } finally {
        model.dispose();
      }
    });
  });
}
