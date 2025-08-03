class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: json['role'] as String,
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  @override
  String toString() => '$role: $content';
}

class ChatRequest {
  final List<ChatMessage> messages;
  final double temperature;
  final double topP;
  final int maxTokens;
  final double repeatPenalty;
  final int repeatLastN;
  final int seed;

  ChatRequest({
    required this.messages,
    this.temperature = 0.7,
    this.topP = 0.9,
    this.maxTokens = 512,
    this.repeatPenalty = 1.1,
    this.repeatLastN = 64,
    this.seed = -1,
  });

  Map<String, dynamic> toJson() => {
        'messages': messages.map((m) => m.toJson()).toList(),
        'temperature': temperature,
        'top_p': topP,
        'max_tokens': maxTokens,
        'repeat_penalty': repeatPenalty,
        'repeat_last_n': repeatLastN,
        'seed': seed,
      };

  factory ChatRequest.fromJson(Map<String, dynamic> json) => ChatRequest(
        messages: (json['messages'] as List)
            .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList(),
        temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
        topP: (json['top_p'] as num?)?.toDouble() ?? 0.9,
        maxTokens: json['max_tokens'] as int? ?? 512,
        repeatPenalty: (json['repeat_penalty'] as num?)?.toDouble() ?? 1.1,
        repeatLastN: json['repeat_last_n'] as int? ?? 64,
        seed: json['seed'] as int? ?? -1,
      );
}

class ChatResponse {
  final String content;
  final int tokensGenerated;
  final Duration generationTime;

  ChatResponse({
    required this.content,
    required this.tokensGenerated,
    required this.generationTime,
  });

  Map<String, dynamic> toJson() => {
        'content': content,
        'tokens_generated': tokensGenerated,
        'generation_time_ms': generationTime.inMilliseconds,
      };

  factory ChatResponse.fromJson(Map<String, dynamic> json) => ChatResponse(
        content: json['content'] as String,
        tokensGenerated: json['tokens_generated'] as int,
        generationTime:
            Duration(milliseconds: json['generation_time_ms'] as int),
      );
}

class LlamaConfig {
  final String modelPath;
  final int contextSize;
  final int batchSize;
  final int threads;
  final bool useMmap;
  final bool useMlock;

  LlamaConfig({
    required this.modelPath,
    this.contextSize = 2048,
    this.batchSize = 512,
    this.threads = 4,
    this.useMmap = true,
    this.useMlock = false,
  });
}