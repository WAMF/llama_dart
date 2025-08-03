import 'dart:ffi';
import 'package:ffi/ffi.dart';

final class LlamaModel extends Opaque {}
final class LlamaContext extends Opaque {}

final class LlamaContextParams extends Struct {
  @Uint32()
  external int seed;
  
  @Uint32()
  external int n_ctx;
  
  @Uint32()
  external int n_batch;
  
  @Uint32()
  external int n_threads;
  
  @Float()
  external double temp;
  
  @Float()
  external double top_p;
  
  @Float()
  external double repeat_penalty;
  
  @Uint32()
  external int repeat_last_n;
  
  @Bool()
  external bool use_mmap;
  
  @Bool()
  external bool use_mlock;
}

final class LlamaToken extends Struct {
  @Int32()
  external int id;
}

typedef LlamaInitBackendNative = Void Function();
typedef LlamaInitBackend = void Function();

typedef LlamaContextDefaultParamsNative = LlamaContextParams Function();
typedef LlamaContextDefaultParams = LlamaContextParams Function();

typedef LlamaLoadModelFromFileNative = Pointer<LlamaModel> Function(
  Pointer<Utf8> path,
  LlamaContextParams params,
);
typedef LlamaLoadModelFromFile = Pointer<LlamaModel> Function(
  Pointer<Utf8> path,
  LlamaContextParams params,
);

typedef LlamaNewContextWithModelNative = Pointer<LlamaContext> Function(
  Pointer<LlamaModel> model,
  LlamaContextParams params,
);
typedef LlamaNewContextWithModel = Pointer<LlamaContext> Function(
  Pointer<LlamaModel> model,
  LlamaContextParams params,
);

typedef LlamaFreeModelNative = Void Function(Pointer<LlamaModel> model);
typedef LlamaFreeModel = void Function(Pointer<LlamaModel> model);

typedef LlamaFreeNative = Void Function(Pointer<LlamaContext> ctx);
typedef LlamaFree = void Function(Pointer<LlamaContext> ctx);

typedef LlamaTokenizeNative = Int32 Function(
  Pointer<LlamaContext> ctx,
  Pointer<Utf8> text,
  Pointer<Int32> tokens,
  Int32 n_max_tokens,
  Bool add_bos,
);
typedef LlamaTokenize = int Function(
  Pointer<LlamaContext> ctx,
  Pointer<Utf8> text,
  Pointer<Int32> tokens,
  int n_max_tokens,
  bool add_bos,
);

typedef LlamaEvalNative = Int32 Function(
  Pointer<LlamaContext> ctx,
  Pointer<Int32> tokens,
  Int32 n_tokens,
  Int32 n_past,
  Int32 n_threads,
);
typedef LlamaEval = int Function(
  Pointer<LlamaContext> ctx,
  Pointer<Int32> tokens,
  int n_tokens,
  int n_past,
  int n_threads,
);

typedef LlamaSampleTopPTopKNative = Int32 Function(
  Pointer<LlamaContext> ctx,
  Pointer<Int32> last_n_tokens,
  Int32 last_n_size,
  Int32 top_k,
  Float top_p,
  Float temp,
  Float repeat_penalty,
);
typedef LlamaSampleTopPTopK = int Function(
  Pointer<LlamaContext> ctx,
  Pointer<Int32> last_n_tokens,
  int last_n_size,
  int top_k,
  double top_p,
  double temp,
  double repeat_penalty,
);

typedef LlamaTokenToStrNative = Pointer<Utf8> Function(
  Pointer<LlamaContext> ctx,
  Int32 token,
);
typedef LlamaTokenToStr = Pointer<Utf8> Function(
  Pointer<LlamaContext> ctx,
  int token,
);

typedef LlamaGetLogitsNative = Pointer<Float> Function(
  Pointer<LlamaContext> ctx,
);
typedef LlamaGetLogits = Pointer<Float> Function(
  Pointer<LlamaContext> ctx,
);

typedef LlamaGetEmbeddingsNative = Pointer<Float> Function(
  Pointer<LlamaContext> ctx,
);
typedef LlamaGetEmbeddings = Pointer<Float> Function(
  Pointer<LlamaContext> ctx,
);

typedef LlamaTokenBosNative = Int32 Function();
typedef LlamaTokenBos = int Function();

typedef LlamaTokenEosNative = Int32 Function();
typedef LlamaTokenEos = int Function();

typedef LlamaTokenNlNative = Int32 Function();
typedef LlamaTokenNl = int Function();

typedef LlamaNVocabNative = Int32 Function(Pointer<LlamaContext> ctx);
typedef LlamaNVocab = int Function(Pointer<LlamaContext> ctx);

typedef LlamaNCtxNative = Int32 Function(Pointer<LlamaContext> ctx);
typedef LlamaNCtx = int Function(Pointer<LlamaContext> ctx);

typedef LlamaNEmbdNative = Int32 Function(Pointer<LlamaContext> ctx);
typedef LlamaNEmbd = int Function(Pointer<LlamaContext> ctx);

class LlamaBindings {
  final DynamicLibrary _lib;
  
  late final LlamaInitBackend initBackend;
  late final LlamaContextDefaultParams contextDefaultParams;
  late final LlamaLoadModelFromFile loadModelFromFile;
  late final LlamaNewContextWithModel newContextWithModel;
  late final LlamaFreeModel freeModel;
  late final LlamaFree free;
  late final LlamaTokenize tokenize;
  late final LlamaEval eval;
  late final LlamaSampleTopPTopK sampleTopPTopK;
  late final LlamaTokenToStr tokenToStr;
  late final LlamaGetLogits getLogits;
  late final LlamaGetEmbeddings getEmbeddings;
  late final LlamaTokenBos tokenBos;
  late final LlamaTokenEos tokenEos;
  late final LlamaTokenNl tokenNl;
  late final LlamaNVocab nVocab;
  late final LlamaNCtx nCtx;
  late final LlamaNEmbd nEmbd;
  
  LlamaBindings(this._lib) {
    initBackend = _lib.lookupFunction<LlamaInitBackendNative, LlamaInitBackend>(
      'llama_init_backend',
    );
    
    contextDefaultParams = _lib.lookupFunction<
        LlamaContextDefaultParamsNative,
        LlamaContextDefaultParams>('llama_context_default_params');
    
    loadModelFromFile = _lib.lookupFunction<
        LlamaLoadModelFromFileNative,
        LlamaLoadModelFromFile>('llama_load_model_from_file');
    
    newContextWithModel = _lib.lookupFunction<
        LlamaNewContextWithModelNative,
        LlamaNewContextWithModel>('llama_new_context_with_model');
    
    freeModel = _lib.lookupFunction<LlamaFreeModelNative, LlamaFreeModel>(
      'llama_free_model',
    );
    
    free = _lib.lookupFunction<LlamaFreeNative, LlamaFree>('llama_free');
    
    tokenize = _lib.lookupFunction<LlamaTokenizeNative, LlamaTokenize>(
      'llama_tokenize',
    );
    
    eval = _lib.lookupFunction<LlamaEvalNative, LlamaEval>('llama_eval');
    
    sampleTopPTopK = _lib.lookupFunction<
        LlamaSampleTopPTopKNative,
        LlamaSampleTopPTopK>('llama_sample_top_p_top_k');
    
    tokenToStr = _lib.lookupFunction<LlamaTokenToStrNative, LlamaTokenToStr>(
      'llama_token_to_str',
    );
    
    getLogits = _lib.lookupFunction<LlamaGetLogitsNative, LlamaGetLogits>(
      'llama_get_logits',
    );
    
    getEmbeddings = _lib.lookupFunction<
        LlamaGetEmbeddingsNative,
        LlamaGetEmbeddings>('llama_get_embeddings');
    
    tokenBos = _lib.lookupFunction<LlamaTokenBosNative, LlamaTokenBos>(
      'llama_token_bos',
    );
    
    tokenEos = _lib.lookupFunction<LlamaTokenEosNative, LlamaTokenEos>(
      'llama_token_eos',
    );
    
    tokenNl = _lib.lookupFunction<LlamaTokenNlNative, LlamaTokenNl>(
      'llama_token_nl',
    );
    
    nVocab = _lib.lookupFunction<LlamaNVocabNative, LlamaNVocab>(
      'llama_n_vocab',
    );
    
    nCtx = _lib.lookupFunction<LlamaNCtxNative, LlamaNCtx>('llama_n_ctx');
    
    nEmbd = _lib.lookupFunction<LlamaNEmbdNative, LlamaNEmbd>('llama_n_embd');
  }
}