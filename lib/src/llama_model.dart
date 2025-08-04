import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:ffi/ffi.dart';
import 'package:dart_llama/src/ffi/llama_bindings_generated.dart';
import 'package:dart_llama/src/models.dart';
import 'package:path/path.dart' as path;

/// Low-level interface for text generation with LLaMA models.
/// 
/// This class provides direct access to the model without any chat-specific
/// formatting or conversation management.
class LlamaModel {
  /// Creates a new LlamaModel instance with the given configuration.
  LlamaModel(this.config);
  
  late final LlamaBindingsGenerated _bindings;
  late final Pointer<llama_model> _model;
  late final Pointer<llama_context> _context;
  late final Pointer<llama_vocab> _vocab;
  Pointer<llama_sampler>? _sampler;

  /// Configuration for the LLaMA model.
  final LlamaConfig config;

  bool _initialized = false;

  /// Initialize the LLaMA model and context.
  void initialize() {
    if (_initialized) return;

    final libraryPath = _getLibraryPath();
    final lib = DynamicLibrary.open(libraryPath);
    _bindings = LlamaBindingsGenerated(lib);

    _bindings.llama_backend_init_wrapper();

    final modelParams = _bindings.llama_model_default_params_wrapper()
      ..n_ctx = config.contextSize
      ..n_batch = config.batchSize
      ..n_threads = config.threads
      ..use_mmap = config.useMmap
      ..use_mlock = config.useMlock;

    final modelPathPtr = config.modelPath.toNativeUtf8();
    _model = _bindings.llama_model_load_from_file_wrapper(
      modelPathPtr.cast<Char>(),
      modelParams,
    );
    calloc.free(modelPathPtr);

    if (_model == nullptr) {
      throw Exception('Failed to load model from ${config.modelPath}');
    }

    final ctxParams = _bindings.llama_context_default_params_wrapper()
      ..n_ctx = config.contextSize
      ..n_batch = config.batchSize
      ..n_threads = config.threads;

    _context = _bindings.llama_init_from_model_wrapper(_model, ctxParams);
    if (_context == nullptr) {
      _bindings.llama_model_free_wrapper(_model);
      throw Exception('Failed to create context');
    }

    final samplerParams =
        _bindings.llama_sampler_chain_default_params_wrapper();
    _sampler = _bindings.llama_sampler_chain_init_wrapper(samplerParams);

    _bindings
      ..llama_sampler_chain_add_wrapper(
          _sampler!, _bindings.llama_sampler_init_top_k_wrapper(40))
      ..llama_sampler_chain_add_wrapper(
          _sampler!, _bindings.llama_sampler_init_top_p_wrapper(0.9, 1))
      ..llama_sampler_chain_add_wrapper(
          _sampler!, _bindings.llama_sampler_init_temp_wrapper(0.7))
      ..llama_sampler_chain_add_wrapper(
          _sampler!,
          _bindings
              .llama_sampler_init_dist_wrapper(Random().nextInt(4294967296)));

    _vocab = _bindings.llama_model_get_vocab_wrapper(_model);
    if (_vocab == nullptr) {
      throw Exception('Failed to get model vocabulary');
    }

    _initialized = true;
  }

  /// Generate text from a prompt.
  /// 
  /// Returns a [GenerationResponse] with the generated text and statistics.
  /// If [onToken] is provided, it will be called for each generated token.
  Future<GenerationResponse> generate(
    GenerationRequest request, {
    void Function(String)? onToken,
  }) async {
    if (!_initialized) {
      throw StateError('LlamaModel not initialized. Call initialize() first.');
    }

    final stopwatch = Stopwatch()..start();
    
    // Always reset sampler for fresh generation
    if (_sampler != null) {
      _bindings.llama_sampler_reset_wrapper(_sampler!);
    }

    // Tokenize the prompt
    final promptPtr = request.prompt.toNativeUtf8();
    final promptLength = request.prompt.length;
    final maxPromptTokens = config.contextSize;
    final tokensPtr = calloc<Int32>(maxPromptTokens);

    final nTokens = _bindings.llama_tokenize_wrapper(
      _vocab,
      promptPtr.cast<Char>(),
      promptLength,
      tokensPtr,
      maxPromptTokens,
      true,
      false,
    );

    if (nTokens < 0) {
      calloc
        ..free(promptPtr)
        ..free(tokensPtr);
      throw Exception(
          'Tokenization failed. Prompt length: $promptLength, max tokens: $maxPromptTokens, result: $nTokens');
    }

    if (nTokens > config.batchSize) {
      calloc
        ..free(promptPtr)
        ..free(tokensPtr);
      throw Exception(
          'Prompt too long: $nTokens tokens exceeds batch size of ${config.batchSize}');
    }

    // Process the prompt
    final batch = _bindings.llama_batch_get_one_wrapper(tokensPtr, nTokens);
    final decodeResult = _bindings.llama_decode_wrapper(_context, batch);

    if (decodeResult != 0) {
      calloc
        ..free(promptPtr)
        ..free(tokensPtr);
      throw Exception('Decode failed');
    }

    // Prepare for generation
    final lastNTokensPtr = calloc<Int32>(request.repeatLastN);
    for (var i = 0; i < min(request.repeatLastN, nTokens); i++) {
      lastNTokensPtr[i] = tokensPtr[max(0, nTokens - request.repeatLastN + i)];
    }

    // Configure sampler with request parameters
    if (_sampler != null) {
      _bindings.llama_sampler_free_wrapper(_sampler!);
    }
    
    final samplerParams = _bindings.llama_sampler_chain_default_params_wrapper();
    _sampler = _bindings.llama_sampler_chain_init_wrapper(samplerParams);
    
    _bindings
      ..llama_sampler_chain_add_wrapper(
          _sampler!, _bindings.llama_sampler_init_top_k_wrapper(request.topK))
      ..llama_sampler_chain_add_wrapper(
          _sampler!, _bindings.llama_sampler_init_top_p_wrapper(request.topP, 1))
      ..llama_sampler_chain_add_wrapper(
          _sampler!, _bindings.llama_sampler_init_temp_wrapper(request.temperature))
      ..llama_sampler_chain_add_wrapper(
          _sampler!,
          _bindings.llama_sampler_init_dist_wrapper(
              request.seed == -1 ? Random().nextInt(4294967296) : request.seed));

    // Generate tokens
    final generatedTokens = <int>[];
    final responseBuffer = StringBuffer();

    try {
      await for (final (
        token: token,
        id: id,
        shouldStop: shouldStop
      ) in _generateTokens(request, lastNTokensPtr)) {
        if (shouldStop) break;
        
        generatedTokens.add(id);
        responseBuffer.write(token);
        onToken?.call(token);
      }
    } finally {
      calloc
        ..free(promptPtr)
        ..free(tokensPtr)
        ..free(lastNTokensPtr);
    }

    stopwatch.stop();

    // Trim any stop sequences from the response
    var finalText = responseBuffer.toString();
    for (final stopSeq in request.stopSequences) {
      // Check if the text contains the stop sequence
      final stopIndex = finalText.indexOf(stopSeq);
      if (stopIndex >= 0) {
        // Trim everything from the stop sequence onwards
        finalText = finalText.substring(0, stopIndex);
      }
    }

    return GenerationResponse(
      text: finalText,
      promptTokens: nTokens,
      generatedTokens: generatedTokens.length,
      totalTokens: nTokens + generatedTokens.length,
      generationTime: stopwatch.elapsed,
    );
  }

  /// Generate text as a stream of tokens.
  Stream<String> generateStream(GenerationRequest request) async* {
    if (!_initialized) {
      throw StateError('LlamaModel not initialized. Call initialize() first.');
    }

    // Always reset sampler for fresh generation
    if (_sampler != null) {
      _bindings.llama_sampler_reset_wrapper(_sampler!);
    }

    // Tokenize the prompt
    final promptPtr = request.prompt.toNativeUtf8();
    final promptLength = request.prompt.length;
    final maxPromptTokens = config.contextSize;
    final tokensPtr = calloc<Int32>(maxPromptTokens);

    final nTokens = _bindings.llama_tokenize_wrapper(
      _vocab,
      promptPtr.cast<Char>(),
      promptLength,
      tokensPtr,
      maxPromptTokens,
      true,
      false,
    );

    if (nTokens < 0) {
      calloc
        ..free(promptPtr)
        ..free(tokensPtr);
      throw Exception(
          'Tokenization failed. Prompt length: $promptLength, max tokens: $maxPromptTokens, result: $nTokens');
    }

    if (nTokens > config.batchSize) {
      calloc
        ..free(promptPtr)
        ..free(tokensPtr);
      throw Exception(
          'Prompt too long: $nTokens tokens exceeds batch size of ${config.batchSize}');
    }

    // Process the prompt
    final batch = _bindings.llama_batch_get_one_wrapper(tokensPtr, nTokens);
    final decodeResult = _bindings.llama_decode_wrapper(_context, batch);

    if (decodeResult != 0) {
      calloc
        ..free(promptPtr)
        ..free(tokensPtr);
      throw Exception('Decode failed');
    }

    // Prepare for generation
    final lastNTokensPtr = calloc<Int32>(request.repeatLastN);
    for (var i = 0; i < min(request.repeatLastN, nTokens); i++) {
      lastNTokensPtr[i] = tokensPtr[max(0, nTokens - request.repeatLastN + i)];
    }

    // Configure sampler with request parameters
    if (_sampler != null) {
      _bindings.llama_sampler_free_wrapper(_sampler!);
    }
    
    final samplerParams = _bindings.llama_sampler_chain_default_params_wrapper();
    _sampler = _bindings.llama_sampler_chain_init_wrapper(samplerParams);
    
    _bindings
      ..llama_sampler_chain_add_wrapper(
          _sampler!, _bindings.llama_sampler_init_top_k_wrapper(request.topK))
      ..llama_sampler_chain_add_wrapper(
          _sampler!, _bindings.llama_sampler_init_top_p_wrapper(request.topP, 1))
      ..llama_sampler_chain_add_wrapper(
          _sampler!, _bindings.llama_sampler_init_temp_wrapper(request.temperature))
      ..llama_sampler_chain_add_wrapper(
          _sampler!,
          _bindings.llama_sampler_init_dist_wrapper(
              request.seed == -1 ? Random().nextInt(4294967296) : request.seed));

    try {
      await for (final (
        token: token,
        id: _,
        shouldStop: shouldStop
      ) in _generateTokens(request, lastNTokensPtr)) {
        if (shouldStop) break;
        yield token;
      }
    } finally {
      calloc
        ..free(promptPtr)
        ..free(tokensPtr)
        ..free(lastNTokensPtr);
    }
  }

  /// Generate tokens for a request.
  Stream<({String token, int id, bool shouldStop})> _generateTokens(
    GenerationRequest request,
    Pointer<Int32> lastNTokensPtr,
  ) async* {
    final eosToken = _bindings.llama_token_eos_wrapper();
    final generatedTextBuffer = StringBuffer();
    final pendingTokens = <({String token, int id})>[];

    for (var i = 0; i < request.maxTokens; i++) {
      final id = _bindings.llama_sampler_sample_wrapper(_sampler!, _context, -1);

      if (id == eosToken) {
        // Flush any pending tokens before stopping
        for (final pending in pendingTokens) {
          yield (token: pending.token, id: pending.id, shouldStop: false);
        }
        yield (token: '', id: id, shouldStop: true);
        return;
      }

      // Update last N tokens for repeat penalty
      for (var j = 0; j < request.repeatLastN - 1; j++) {
        lastNTokensPtr[j] = lastNTokensPtr[j + 1];
      }
      lastNTokensPtr[request.repeatLastN - 1] = id;

      final tokenIdPtr = calloc<Int32>();
      tokenIdPtr[0] = id;

      final batch = _bindings.llama_batch_get_one_wrapper(tokenIdPtr, 1);
      final decodeResult = _bindings.llama_decode_wrapper(_context, batch);

      calloc.free(tokenIdPtr);

      if (decodeResult != 0) {
        throw Exception('Decode failed during generation');
      }

      const bufferSize = 32;
      final buffer = calloc<Uint8>(bufferSize);
      final bufferUtf8 = buffer.cast<Utf8>();
      final length = _bindings.llama_token_to_piece_wrapper(
          _vocab, id, bufferUtf8.cast<Char>(), bufferSize, 0, false);

      var token = '';
      if (length > 0) {
        token = bufferUtf8.toDartString(length: length);
      }

      calloc.free(buffer);
      
      // Add token to pending list
      pendingTokens.add((token: token, id: id));
      
      // Build the full text including pending tokens
      final fullText = generatedTextBuffer.toString() + 
          pendingTokens.map((p) => p.token).join();
      
      // Check if we have a complete stop sequence
      for (final stopSeq in request.stopSequences) {
        final stopIndex = fullText.indexOf(stopSeq);
        if (stopIndex >= 0) {
          // Found a stop sequence - yield tokens up to the stop sequence
          final textBeforeStop = fullText.substring(0, stopIndex);
          final alreadyYielded = generatedTextBuffer.length;
          
          if (textBeforeStop.length > alreadyYielded) {
            // We need to yield some pending tokens
            var remainingToYield = textBeforeStop.substring(alreadyYielded);
            for (final pending in pendingTokens) {
              if (remainingToYield.isEmpty) break;
              
              if (remainingToYield.startsWith(pending.token)) {
                yield (token: pending.token, id: pending.id, shouldStop: false);
                remainingToYield = remainingToYield.substring(pending.token.length);
              } else if (pending.token.startsWith(remainingToYield)) {
                yield (token: remainingToYield, id: pending.id, shouldStop: false);
                break;
              }
            }
          }
          
          yield (token: '', id: id, shouldStop: true);
          return;
        }
      }
      
      // Check if we might be building a stop sequence
      var mightBeStop = false;
      for (final stopSeq in request.stopSequences) {
        // Check all possible prefixes of stop sequences
        for (var len = 1; len < stopSeq.length && len <= fullText.length; len++) {
          if (fullText.endsWith(stopSeq.substring(0, len))) {
            mightBeStop = true;
            break;
          }
        }
        if (mightBeStop) break;
      }
      
      if (!mightBeStop) {
        // Safe to yield all pending tokens
        for (final pending in pendingTokens) {
          yield (token: pending.token, id: pending.id, shouldStop: false);
          generatedTextBuffer.write(pending.token);
        }
        pendingTokens.clear();
      }
    }
    
    // Yield any remaining pending tokens
    for (final pending in pendingTokens) {
      yield (token: pending.token, id: pending.id, shouldStop: false);
    }
  }

  String _getLibraryPath() {
    final ext = Platform.isWindows
        ? '.dll'
        : Platform.isMacOS
            ? '.dylib'
            : '.so';

    final currentDir = Directory.current.path;
    final possiblePaths = [
      path.join(currentDir, 'libllama_wrapper$ext'),
      path.join(currentDir, 'lib', 'llama$ext'),
      path.join(currentDir, 'build', 'llama$ext'),
      path.join(currentDir, 'llama$ext'),
      'libllama_wrapper$ext',
      'llama$ext',
    ];

    for (final libPath in possiblePaths) {
      if (File(libPath).existsSync()) {
        return libPath;
      }
    }

    throw Exception(
      'Could not find llama library. Searched: ${possiblePaths.join(', ')}',
    );
  }

  /// Clean up resources and free memory.
  void dispose() {
    if (_initialized) {
      if (_sampler != null) {
        _bindings.llama_sampler_free_wrapper(_sampler!);
        _sampler = null;
      }
      _bindings
        ..llama_free_wrapper(_context)
        ..llama_model_free_wrapper(_model);
      _initialized = false;
    }
  }
}
