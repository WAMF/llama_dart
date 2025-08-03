import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

import 'ffi/llama_bindings.dart';
import 'models.dart';

class LlamaChat {
  late final LlamaBindings _bindings;
  late final Pointer<LlamaModel> _model;
  late final Pointer<LlamaContext> _context;
  final LlamaConfig config;
  
  bool _initialized = false;

  LlamaChat(this.config);

  void initialize() {
    if (_initialized) return;

    final libraryPath = _getLibraryPath();
    final lib = DynamicLibrary.open(libraryPath);
    _bindings = LlamaBindings(lib);

    _bindings.initBackend();

    final params = _bindings.contextDefaultParams();
    params.n_ctx = config.contextSize;
    params.n_batch = config.batchSize;
    params.n_threads = config.threads;
    params.use_mmap = config.useMmap;
    params.use_mlock = config.useMlock;

    final modelPathPtr = config.modelPath.toNativeUtf8();
    _model = _bindings.loadModelFromFile(modelPathPtr, params);
    calloc.free(modelPathPtr);

    if (_model == nullptr) {
      throw Exception('Failed to load model from ${config.modelPath}');
    }

    _context = _bindings.newContextWithModel(_model, params);
    if (_context == nullptr) {
      _bindings.freeModel(_model);
      throw Exception('Failed to create context');
    }

    _initialized = true;
  }

  Future<ChatResponse> chat(ChatRequest request) async {
    if (!_initialized) {
      throw StateError('LlamaChat not initialized. Call initialize() first.');
    }

    final stopwatch = Stopwatch()..start();
    
    final prompt = _buildPrompt(request.messages);
    final promptPtr = prompt.toNativeUtf8();
    
    final maxTokens = request.maxTokens;
    final tokensPtr = calloc<Int32>(maxTokens);
    
    final nTokens = _bindings.tokenize(
      _context,
      promptPtr,
      tokensPtr,
      maxTokens,
      true,
    );
    
    calloc.free(promptPtr);
    
    if (nTokens < 0) {
      calloc.free(tokensPtr);
      throw Exception('Tokenization failed');
    }

    var nPast = 0;
    final generatedTokens = <int>[];
    final responseBuffer = StringBuffer();
    
    for (var i = 0; i < nTokens; i++) {
      final evalResult = _bindings.eval(
        _context,
        tokensPtr.elementAt(i),
        1,
        nPast,
        config.threads,
      );
      
      if (evalResult != 0) {
        calloc.free(tokensPtr);
        throw Exception('Evaluation failed');
      }
      
      nPast++;
    }
    
    final lastNTokensPtr = calloc<Int32>(request.repeatLastN);
    for (var i = 0; i < min(request.repeatLastN, nTokens); i++) {
      lastNTokensPtr[i] = tokensPtr[max(0, nTokens - request.repeatLastN + i)];
    }
    
    final eosToken = _bindings.tokenEos();
    
    for (var i = 0; i < request.maxTokens; i++) {
      final id = _bindings.sampleTopPTopK(
        _context,
        lastNTokensPtr,
        min(request.repeatLastN, nPast),
        40, 
        request.topP,
        request.temperature,
        request.repeatPenalty,
      );
      
      if (id == eosToken) break;
      
      generatedTokens.add(id);
      
      for (var j = 0; j < request.repeatLastN - 1; j++) {
        lastNTokensPtr[j] = lastNTokensPtr[j + 1];
      }
      lastNTokensPtr[request.repeatLastN - 1] = id;
      
      final tokenIdPtr = calloc<Int32>(1);
      tokenIdPtr[0] = id;
      
      final evalResult = _bindings.eval(
        _context,
        tokenIdPtr,
        1,
        nPast,
        config.threads,
      );
      
      calloc.free(tokenIdPtr);
      
      if (evalResult != 0) {
        calloc.free(tokensPtr);
        calloc.free(lastNTokensPtr);
        throw Exception('Evaluation failed during generation');
      }
      
      nPast++;
      
      final tokenStr = _bindings.tokenToStr(_context, id);
      responseBuffer.write(tokenStr.toDartString());
    }
    
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
    
    for (final message in messages) {
      if (message.role == 'system') {
        buffer.writeln('System: ${message.content}');
      } else if (message.role == 'user') {
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
      path.join(currentDir, 'lib', 'llama$ext'),
      path.join(currentDir, 'build', 'llama$ext'),
      path.join(currentDir, 'llama$ext'),
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

  void dispose() {
    if (_initialized) {
      _bindings.free(_context);
      _bindings.freeModel(_model);
      _initialized = false;
    }
  }
}