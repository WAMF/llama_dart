// Data models for llama_dart. These are simple data classes
// with basic documentation where needed.

/// Configuration for initializing a LLaMA model.
/// 
/// This class contains all the parameters needed to load and configure
/// a LLaMA model for inference.
class LlamaConfig {

  /// Creates a configuration for loading a LLaMA model.
  /// 
  /// The [modelPath] parameter is required and should point to a valid GGUF model file.
  /// Other parameters have sensible defaults but can be tuned for performance.
  LlamaConfig({
    required this.modelPath,
    this.contextSize = 2048,
    this.batchSize = 2048,
    this.threads = 4,
    this.useMmap = true,
    this.useMlock = false,
  });
  /// Path to the GGUF model file to load.
  final String modelPath;
  
  /// Maximum context size in tokens.
  /// 
  /// This determines how many tokens the model can process at once.
  /// Larger values allow for longer conversations but use more memory.
  final int contextSize;
  
  /// Batch size for processing tokens.
  /// 
  /// Larger batch sizes can improve performance but use more memory.
  final int batchSize;
  
  /// Number of threads to use for inference.
  /// 
  /// Should typically match the number of CPU cores available.
  final int threads;
  
  /// Whether to use memory-mapped files for model loading.
  /// 
  /// This can significantly reduce memory usage for large models.
  final bool useMmap;
  
  /// Whether to lock the model in memory.
  /// 
  /// This prevents the model from being swapped to disk but requires
  /// sufficient RAM and appropriate system permissions.
  final bool useMlock;
}

/// Request parameters for text generation.
/// 
/// This class encapsulates all the parameters that control how text
/// is generated from a prompt.
class GenerationRequest {
  /// Creates a generation request with the specified parameters.
  /// 
  /// Only [prompt] is required. All other parameters have sensible defaults
  /// that work well for most use cases.
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

  /// The input prompt to generate text from.
  final String prompt;
  
  /// Maximum number of tokens to generate.
  /// 
  /// Generation will stop when this limit is reached or when an
  /// end-of-sequence token is generated.
  final int maxTokens;
  
  /// Temperature for sampling.
  /// 
  /// Higher values (e.g., 1.0) make the output more random and creative,
  /// lower values (e.g., 0.1) make it more deterministic and focused.
  final double temperature;
  
  /// Top-p (nucleus) sampling parameter.
  /// 
  /// Limits token selection to those whose cumulative probability
  /// is below this threshold. Values between 0.9-0.95 work well.
  final double topP;
  
  /// Top-k sampling parameter.
  /// 
  /// Limits token selection to the k most likely tokens.
  /// Typical values are between 10-100.
  final int topK;
  
  /// Penalty for repeating tokens.
  /// 
  /// Values > 1.0 discourage repetition, values < 1.0 encourage it.
  /// A value of 1.1 works well for most use cases.
  final double repeatPenalty;
  
  /// Number of recent tokens to consider for repeat penalty.
  /// 
  /// The repeat penalty is applied to the last N tokens in the context.
  final int repeatLastN;
  
  /// Random seed for reproducible generation.
  /// 
  /// Use -1 for non-deterministic generation, or any positive integer
  /// for reproducible results.
  final int seed;
  
  /// List of sequences that will stop generation when encountered.
  /// 
  /// Generation will stop as soon as any of these sequences appear
  /// in the output. Common stop sequences include "\n\n" or "END".
  final List<String> stopSequences;
}

/// Response from text generation.
/// 
/// This class contains the generated text and metadata about the generation process,
/// including token counts and timing information.
class GenerationResponse {
  /// Creates a generation response with the specified values.
  /// 
  /// All parameters are required and represent the outcome of a text generation request.
  GenerationResponse({
    required this.text,
    required this.promptTokens,
    required this.generatedTokens,
    required this.totalTokens,
    required this.generationTime,
  });

  /// The generated text output.
  final String text;
  
  /// Number of tokens in the input prompt.
  final int promptTokens;
  
  /// Number of tokens generated in the response.
  final int generatedTokens;
  
  /// Total number of tokens processed (prompt + generated).
  final int totalTokens;
  
  /// Time taken to generate the response.
  final Duration generationTime;
}
