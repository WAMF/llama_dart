// Data models for llama_dart. These are simple data classes
// with basic documentation where needed.
// ignore_for_file: public_member_api_docs

class LlamaConfig {

  LlamaConfig({
    required this.modelPath,
    this.contextSize = 2048,
    this.batchSize = 2048,
    this.threads = 4,
    this.useMmap = true,
    this.useMlock = false,
  });
  final String modelPath;
  final int contextSize;
  final int batchSize;
  final int threads;
  final bool useMmap;
  final bool useMlock;
}

/// Request for text generation
class GenerationRequest {
  GenerationRequest({
    required this.prompt,
    this.maxTokens = 512,
    this.temperature = 0.7,
    this.topP = 0.9,
    this.topK = 40,
    this.repeatPenalty = 1.1,
    this.repeatLastN = 64,
    this.seed = -1,
    this.stopSequences = const [],
  });

  final String prompt;
  final int maxTokens;
  final double temperature;
  final double topP;
  final int topK;
  final double repeatPenalty;
  final int repeatLastN;
  final int seed;
  final List<String> stopSequences;
}

/// Response from text generation
class GenerationResponse {
  GenerationResponse({
    required this.text,
    required this.promptTokens,
    required this.generatedTokens,
    required this.totalTokens,
    required this.generationTime,
  });

  final String text;
  final int promptTokens;
  final int generatedTokens;
  final int totalTokens;
  final Duration generationTime;
}
