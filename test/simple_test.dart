import 'dart:io';
import 'package:dart_llama/dart_llama.dart';
import 'package:test/test.dart';

void main() {
  test('can load and initialize model', () {
    if (!File('./models/gemma-3-1b-it-Q4_K_M.gguf').existsSync()) {
      print('Test model not found, skipping');
      return;
    }
    
    final config = LlamaConfig(
      modelPath: './models/gemma-3-1b-it-Q4_K_M.gguf',
    );
    
    final model = LlamaModel(config);
    
    // Just test initialization
    expect(() => model.initialize(), returnsNormally);
    
    // Clean up
    model.dispose();
  });
}