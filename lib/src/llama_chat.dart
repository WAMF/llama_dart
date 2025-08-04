import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

import 'ffi/llama_bindings_generated.dart';
import 'models.dart';

class LlamaChat {
  late final LlamaBindingsGenerated _bindings;
  late final Pointer<llama_model> _model;
  late final Pointer<llama_context> _context;
  late final Pointer<llama_vocab> _vocab;
  late final Pointer<llama_sampler> _sampler;
  final LlamaConfig config;
  
  bool _initialized = false;

  LlamaChat(this.config);

  void initialize() {
    if (_initialized) return;

    final libraryPath = _getLibraryPath();
    final lib = DynamicLibrary.open(libraryPath);
    _bindings = LlamaBindingsGenerated(lib);

    _bindings.llama_backend_init_wrapper();

    final modelParams = _bindings.llama_model_default_params_wrapper();
    modelParams.n_ctx = config.contextSize;
    modelParams.n_batch = config.batchSize;
    modelParams.n_threads = config.threads;
    modelParams.use_mmap = config.useMmap;
    modelParams.use_mlock = config.useMlock;

    final modelPathPtr = config.modelPath.toNativeUtf8();
    _model = _bindings.llama_model_load_from_file_wrapper(modelPathPtr.cast<Char>(), modelParams);
    calloc.free(modelPathPtr);

    if (_model == nullptr) {
      throw Exception('Failed to load model from ${config.modelPath}');
    }

    final ctxParams = _bindings.llama_context_default_params_wrapper();
    ctxParams.n_ctx = config.contextSize;
    ctxParams.n_batch = config.batchSize;
    ctxParams.n_threads = config.threads;
    
    _context = _bindings.llama_init_from_model_wrapper(_model, ctxParams);
    if (_context == nullptr) {
      _bindings.llama_model_free_wrapper(_model);
      throw Exception('Failed to create context');
    }

    final samplerParams = _bindings.llama_sampler_chain_default_params_wrapper();
    _sampler = _bindings.llama_sampler_chain_init_wrapper(samplerParams);
    
    _bindings.llama_sampler_chain_add_wrapper(_sampler, _bindings.llama_sampler_init_top_k_wrapper(40));
    _bindings.llama_sampler_chain_add_wrapper(_sampler, _bindings.llama_sampler_init_top_p_wrapper(0.9, 1));
    _bindings.llama_sampler_chain_add_wrapper(_sampler, _bindings.llama_sampler_init_temp_wrapper(0.7));
    _bindings.llama_sampler_chain_add_wrapper(_sampler, _bindings.llama_sampler_init_dist_wrapper(Random().nextInt(4294967296)));
    
    _vocab = _bindings.llama_model_get_vocab_wrapper(_model);
    if (_vocab == nullptr) {
      throw Exception('Failed to get model vocabulary');
    }
    
    _initialized = true;
  }

  Future<ChatResponse> chat(ChatRequest request, {void Function(String)? onToken}) async {
    if (!_initialized) {
      throw StateError('LlamaChat not initialized. Call initialize() first.');
    }

    final stopwatch = Stopwatch()..start();
    
    // Always reset sampler for fresh generation
    _bindings.llama_sampler_reset_wrapper(_sampler);
    
    final prompt = _buildPrompt(request.messages);
    final promptPtr = prompt.toNativeUtf8();
    
    final promptLength = prompt.length;
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
      calloc.free(promptPtr);
      calloc.free(tokensPtr);
      throw Exception('Tokenization failed. Prompt length: $promptLength, max tokens: $maxPromptTokens, result: $nTokens');
    }
    
    if (nTokens > config.batchSize) {
      calloc.free(promptPtr);
      calloc.free(tokensPtr);
      throw Exception('Prompt too long: $nTokens tokens exceeds batch size of ${config.batchSize}');
    }

    final generatedTokens = <int>[];
    final responseBuffer = StringBuffer();
    
    final batch = _bindings.llama_batch_get_one_wrapper(tokensPtr, nTokens);
    final decodeResult = _bindings.llama_decode_wrapper(_context, batch);
    
    if (decodeResult != 0) {
      calloc.free(promptPtr);
      calloc.free(tokensPtr);
      throw Exception('Decode failed');
    }
    
    final lastNTokensPtr = calloc<Int32>(request.repeatLastN);
    for (var i = 0; i < min(request.repeatLastN, nTokens); i++) {
      lastNTokensPtr[i] = tokensPtr[max(0, nTokens - request.repeatLastN + i)];
    }
    
    final eosToken = _bindings.llama_token_eos_wrapper();
    
    for (var i = 0; i < request.maxTokens; i++) {
      final id = _bindings.llama_sampler_sample_wrapper(_sampler, _context, -1);
      
      if (id == eosToken) break;
      
      generatedTokens.add(id);
      
      for (var j = 0; j < request.repeatLastN - 1; j++) {
        lastNTokensPtr[j] = lastNTokensPtr[j + 1];
      }
      lastNTokensPtr[request.repeatLastN - 1] = id;
      
      final tokenIdPtr = calloc<Int32>(1);
      tokenIdPtr[0] = id;
      
      final batch = _bindings.llama_batch_get_one_wrapper(tokenIdPtr, 1);
      final decodeResult = _bindings.llama_decode_wrapper(_context, batch);
      
      calloc.free(tokenIdPtr);
      
      if (decodeResult != 0) {
        calloc.free(promptPtr);
        calloc.free(tokensPtr);
        calloc.free(lastNTokensPtr);
        throw Exception('Decode failed during generation');
      }
      
      final bufferSize = 32;
      final buffer = calloc<Uint8>(bufferSize);
      final bufferUtf8 = buffer.cast<Utf8>();
      final length = _bindings.llama_token_to_piece_wrapper(_vocab, id, bufferUtf8.cast<Char>(), bufferSize, 0, false);
      
      if (length > 0) {
        final token = bufferUtf8.toDartString(length: length);
        responseBuffer.write(token);
        onToken?.call(token);
      }
      
      calloc.free(buffer);
    }
    
    calloc.free(promptPtr);
    calloc.free(tokensPtr);
    calloc.free(lastNTokensPtr);
    
    stopwatch.stop();
    
    return ChatResponse(
      content: responseBuffer.toString(),
      tokensGenerated: generatedTokens.length,
      generationTime: stopwatch.elapsed,
    );
  }

  String _buildPrompt(List<ChatMessage> messages) {
    final buffer = StringBuffer();
    
    // Keep system message if present
    var messagesToUse = messages;
    if (messages.isNotEmpty && messages.first.role == 'system') {
      buffer.writeln('System: ${messages.first.content}');
      messagesToUse = messages.skip(1).toList();
    }
    
    // Include only recent messages to avoid exceeding context
    // Keep last 10 exchanges (20 messages)
    const maxMessages = 20;
    if (messagesToUse.length > maxMessages) {
      messagesToUse = messagesToUse.sublist(messagesToUse.length - maxMessages);
    }
    
    for (final message in messagesToUse) {
      if (message.role == 'user') {
        buffer.writeln('User: ${message.content}');
      } else if (message.role == 'assistant') {
        buffer.writeln('Assistant: ${message.content}');
      }
    }
    
    buffer.write('Assistant: ');
    
    return buffer.toString();
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

  Stream<String> chatStream(ChatRequest request) async* {
    if (!_initialized) {
      throw StateError('LlamaChat not initialized. Call initialize() first.');
    }

    // Always reset sampler for fresh generation
    _bindings.llama_sampler_reset_wrapper(_sampler);
    
    final prompt = _buildPrompt(request.messages);
    final promptPtr = prompt.toNativeUtf8();
    
    final promptLength = prompt.length;
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
      calloc.free(promptPtr);
      calloc.free(tokensPtr);
      throw Exception('Tokenization failed. Prompt length: $promptLength, max tokens: $maxPromptTokens, result: $nTokens');
    }
    
    if (nTokens > config.batchSize) {
      calloc.free(promptPtr);
      calloc.free(tokensPtr);
      throw Exception('Prompt too long: $nTokens tokens exceeds batch size of ${config.batchSize}');
    }
    
    final batch = _bindings.llama_batch_get_one_wrapper(tokensPtr, nTokens);
    final decodeResult = _bindings.llama_decode_wrapper(_context, batch);
    
    if (decodeResult != 0) {
      calloc.free(promptPtr);
      calloc.free(tokensPtr);
      throw Exception('Decode failed');
    }
    
    final lastNTokensPtr = calloc<Int32>(request.repeatLastN);
    for (var i = 0; i < min(request.repeatLastN, nTokens); i++) {
      lastNTokensPtr[i] = tokensPtr[max(0, nTokens - request.repeatLastN + i)];
    }
    
    final eosToken = _bindings.llama_token_eos_wrapper();
    
    for (var i = 0; i < request.maxTokens; i++) {
      final id = _bindings.llama_sampler_sample_wrapper(_sampler, _context, -1);
      
      if (id == eosToken) break;
      
      for (var j = 0; j < request.repeatLastN - 1; j++) {
        lastNTokensPtr[j] = lastNTokensPtr[j + 1];
      }
      lastNTokensPtr[request.repeatLastN - 1] = id;
      
      final tokenIdPtr = calloc<Int32>(1);
      tokenIdPtr[0] = id;
      
      final batch = _bindings.llama_batch_get_one_wrapper(tokenIdPtr, 1);
      final decodeResult = _bindings.llama_decode_wrapper(_context, batch);
      
      calloc.free(tokenIdPtr);
      
      if (decodeResult != 0) {
        calloc.free(promptPtr);
        calloc.free(tokensPtr);
        calloc.free(lastNTokensPtr);
        throw Exception('Decode failed during generation');
      }
      
      final bufferSize = 32;
      final buffer = calloc<Uint8>(bufferSize);
      final bufferUtf8 = buffer.cast<Utf8>();
      final length = _bindings.llama_token_to_piece_wrapper(_vocab, id, bufferUtf8.cast<Char>(), bufferSize, 0, false);
      
      if (length > 0) {
        final token = bufferUtf8.toDartString(length: length);
        yield token;
      }
      
      calloc.free(buffer);
    }
    
    calloc.free(promptPtr);
    calloc.free(tokensPtr);
    calloc.free(lastNTokensPtr);
  }

  void dispose() {
    if (_initialized) {
      _bindings.llama_free_wrapper(_context);
      _bindings.llama_model_free_wrapper(_model);
      _bindings.llama_sampler_free_wrapper(_sampler);
      _initialized = false;
    }
  }
}