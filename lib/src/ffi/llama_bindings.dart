// Manual FFI bindings for llama.cpp wrapper functions.
// These are hand-written bindings for custom wrapper functions.
// Non-constant names match the C function naming conventions.
// Public APIs are documented but internal typedefs and fields are self-explanatory.
// ignore_for_file: non_constant_identifier_names, public_member_api_docs, lines_longer_than_80_chars

import 'dart:ffi';
import 'package:ffi/ffi.dart';

final class LlamaModel extends Opaque {}
final class LlamaContext extends Opaque {}
final class LlamaVocab extends Opaque {}

final class LlamaModelParams extends Struct {
  @Uint32()
  external int seed;
  
  @Uint32()
  external int n_ctx;
  
  @Uint32()
  external int n_batch;
  
  @Uint32()
  external int n_threads;
  
  @Bool()
  external bool use_mmap;
  
  @Bool()
  external bool use_mlock;
}

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

final class LlamaSampler extends Opaque {}

final class LlamaSamplerChainParams extends Struct {
  @Bool()
  external bool no_perf;
}

typedef LlamaBackendInitNative = Void Function();
typedef LlamaBackendInit = void Function();

typedef LlamaModelDefaultParamsNative = LlamaModelParams Function();
typedef LlamaModelDefaultParams = LlamaModelParams Function();

typedef LlamaContextDefaultParamsNative = LlamaContextParams Function();
typedef LlamaContextDefaultParams = LlamaContextParams Function();

typedef LlamaModelLoadFromFileNative = Pointer<LlamaModel> Function(
  Pointer<Utf8> path,
  LlamaModelParams params,
);
typedef LlamaModelLoadFromFile = Pointer<LlamaModel> Function(
  Pointer<Utf8> path,
  LlamaModelParams params,
);

typedef LlamaInitFromModelNative = Pointer<LlamaContext> Function(
  Pointer<LlamaModel> model,
  LlamaContextParams params,
);
typedef LlamaInitFromModel = Pointer<LlamaContext> Function(
  Pointer<LlamaModel> model,
  LlamaContextParams params,
);

typedef LlamaFreeModelNative = Void Function(Pointer<LlamaModel> model);
typedef LlamaFreeModel = void Function(Pointer<LlamaModel> model);

typedef LlamaFreeNative = Void Function(Pointer<LlamaContext> ctx);
typedef LlamaFree = void Function(Pointer<LlamaContext> ctx);

typedef LlamaTokenizeNative = Int32 Function(
  Pointer<LlamaVocab> vocab,
  Pointer<Utf8> text,
  Int32 text_len,
  Pointer<Int32> tokens,
  Int32 n_tokens_max,
  Bool add_special,
  Bool parse_special,
);
typedef LlamaTokenize = int Function(
  Pointer<LlamaVocab> vocab,
  Pointer<Utf8> text,
  int text_len,
  Pointer<Int32> tokens,
  int n_tokens_max,
  bool add_special,
  bool parse_special,
);

final class LlamaBatch extends Struct {
  @Int32()
  external int n_tokens;
  
  external Pointer<Int32> token;
  external Pointer<Float> embd;
  external Pointer<Int32> pos;
  external Pointer<Int32> n_seq_id;
  external Pointer<Pointer<Int32>> seq_id;
  external Pointer<Int8> logits;
}

typedef LlamaDecodeNative = Int32 Function(
  Pointer<LlamaContext> ctx,
  LlamaBatch batch,
);
typedef LlamaDecode = int Function(
  Pointer<LlamaContext> ctx,
  LlamaBatch batch,
);

typedef LlamaBatchGetOneNative = LlamaBatch Function(
  Pointer<Int32> tokens,
  Int32 n_tokens,
);
typedef LlamaBatchGetOne = LlamaBatch Function(
  Pointer<Int32> tokens,
  int n_tokens,
);

typedef LlamaSamplerChainDefaultParamsNative = LlamaSamplerChainParams Function();
typedef LlamaSamplerChainDefaultParams = LlamaSamplerChainParams Function();

typedef LlamaSamplerChainInitNative = Pointer<LlamaSampler> Function(
  LlamaSamplerChainParams params,
);
typedef LlamaSamplerChainInit = Pointer<LlamaSampler> Function(
  LlamaSamplerChainParams params,
);

typedef LlamaSamplerChainAddNative = Void Function(
  Pointer<LlamaSampler> chain,
  Pointer<LlamaSampler> smpl,
);
typedef LlamaSamplerChainAdd = void Function(
  Pointer<LlamaSampler> chain,
  Pointer<LlamaSampler> smpl,
);

typedef LlamaSamplerInitTopKNative = Pointer<LlamaSampler> Function(Int32 k);
typedef LlamaSamplerInitTopK = Pointer<LlamaSampler> Function(int k);

typedef LlamaSamplerInitTopPNative = Pointer<LlamaSampler> Function(Float p, Size min_keep);
typedef LlamaSamplerInitTopP = Pointer<LlamaSampler> Function(double p, int min_keep);

typedef LlamaSamplerInitTempNative = Pointer<LlamaSampler> Function(Float t);
typedef LlamaSamplerInitTemp = Pointer<LlamaSampler> Function(double t);

typedef LlamaSamplerInitDistNative = Pointer<LlamaSampler> Function(Uint32 seed);
typedef LlamaSamplerInitDist = Pointer<LlamaSampler> Function(int seed);

typedef LlamaSamplerSampleNative = Int32 Function(
  Pointer<LlamaSampler> smpl,
  Pointer<LlamaContext> ctx,
  Int32 idx,
);
typedef LlamaSamplerSample = int Function(
  Pointer<LlamaSampler> smpl,
  Pointer<LlamaContext> ctx,
  int idx,
);

typedef LlamaSamplerFreeNative = Void Function(Pointer<LlamaSampler> smpl);
typedef LlamaSamplerFree = void Function(Pointer<LlamaSampler> smpl);

typedef LlamaModelGetVocabNative = Pointer<LlamaVocab> Function(
  Pointer<LlamaModel> model,
);
typedef LlamaModelGetVocab = Pointer<LlamaVocab> Function(
  Pointer<LlamaModel> model,
);

typedef LlamaTokenToPieceNative = Int32 Function(
  Pointer<LlamaVocab> vocab,
  Int32 token,
  Pointer<Utf8> buf,
  Int32 length,
  Int32 lstrip,
  Bool special,
);
typedef LlamaTokenToPiece = int Function(
  Pointer<LlamaVocab> vocab,
  int token,
  Pointer<Utf8> buf,
  int length,
  int lstrip,
  bool special,
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

typedef LlamaNVocabNative = Int32 Function(Pointer<LlamaModel> model);
typedef LlamaNVocab = int Function(Pointer<LlamaModel> model);

typedef LlamaNCtxNative = Int32 Function(Pointer<LlamaContext> ctx);
typedef LlamaNCtx = int Function(Pointer<LlamaContext> ctx);

typedef LlamaNEmbdNative = Int32 Function(Pointer<LlamaModel> model);
typedef LlamaNEmbd = int Function(Pointer<LlamaModel> model);

class LlamaBindings {
  
  LlamaBindings(this._lib) {
    backendInit = _lib.lookupFunction<LlamaBackendInitNative, LlamaBackendInit>(
      'llama_backend_init_wrapper',
    );
    
    contextDefaultParams = _lib.lookupFunction<
        LlamaContextDefaultParamsNative,
        LlamaContextDefaultParams>('llama_context_default_params_wrapper');
    
    modelDefaultParams = _lib.lookupFunction<
        LlamaModelDefaultParamsNative,
        LlamaModelDefaultParams>('llama_model_default_params_wrapper');
    
    modelLoadFromFile = _lib.lookupFunction<
        LlamaModelLoadFromFileNative,
        LlamaModelLoadFromFile>('llama_model_load_from_file_wrapper');
    
    initFromModel = _lib.lookupFunction<
        LlamaInitFromModelNative,
        LlamaInitFromModel>('llama_init_from_model_wrapper');
    
    freeModel = _lib.lookupFunction<LlamaFreeModelNative, LlamaFreeModel>(
      'llama_model_free_wrapper',
    );
    
    free = _lib.lookupFunction<LlamaFreeNative, LlamaFree>('llama_free_wrapper');
    
    tokenize = _lib.lookupFunction<LlamaTokenizeNative, LlamaTokenize>(
      'llama_tokenize_wrapper',
    );
    
    decode = _lib.lookupFunction<LlamaDecodeNative, LlamaDecode>('llama_decode_wrapper');
    
    batchGetOne = _lib.lookupFunction<LlamaBatchGetOneNative, LlamaBatchGetOne>(
      'llama_batch_get_one_wrapper',
    );
    
    samplerChainDefaultParams = _lib.lookupFunction<
        LlamaSamplerChainDefaultParamsNative,
        LlamaSamplerChainDefaultParams>('llama_sampler_chain_default_params_wrapper');
    
    samplerChainInit = _lib.lookupFunction<
        LlamaSamplerChainInitNative,
        LlamaSamplerChainInit>('llama_sampler_chain_init_wrapper');
    
    samplerChainAdd = _lib.lookupFunction<
        LlamaSamplerChainAddNative,
        LlamaSamplerChainAdd>('llama_sampler_chain_add_wrapper');
    
    samplerInitTopK = _lib.lookupFunction<
        LlamaSamplerInitTopKNative,
        LlamaSamplerInitTopK>('llama_sampler_init_top_k_wrapper');
    
    samplerInitTopP = _lib.lookupFunction<
        LlamaSamplerInitTopPNative,
        LlamaSamplerInitTopP>('llama_sampler_init_top_p_wrapper');
    
    samplerInitTemp = _lib.lookupFunction<
        LlamaSamplerInitTempNative,
        LlamaSamplerInitTemp>('llama_sampler_init_temp_wrapper');
    
    samplerInitDist = _lib.lookupFunction<
        LlamaSamplerInitDistNative,
        LlamaSamplerInitDist>('llama_sampler_init_dist_wrapper');
    
    samplerSample = _lib.lookupFunction<
        LlamaSamplerSampleNative,
        LlamaSamplerSample>('llama_sampler_sample_wrapper');
    
    samplerFree = _lib.lookupFunction<
        LlamaSamplerFreeNative,
        LlamaSamplerFree>('llama_sampler_free_wrapper');
    
    modelGetVocab = _lib.lookupFunction<LlamaModelGetVocabNative, LlamaModelGetVocab>(
      'llama_model_get_vocab_wrapper',
    );
    
    tokenToPiece = _lib.lookupFunction<LlamaTokenToPieceNative, LlamaTokenToPiece>(
      'llama_token_to_piece_wrapper',
    );
    
    getLogits = _lib.lookupFunction<LlamaGetLogitsNative, LlamaGetLogits>(
      'llama_get_logits_wrapper',
    );
    
    getEmbeddings = _lib.lookupFunction<
        LlamaGetEmbeddingsNative,
        LlamaGetEmbeddings>('llama_get_embeddings_wrapper');
    
    tokenBos = _lib.lookupFunction<LlamaTokenBosNative, LlamaTokenBos>(
      'llama_token_bos_wrapper',
    );
    
    tokenEos = _lib.lookupFunction<LlamaTokenEosNative, LlamaTokenEos>(
      'llama_token_eos_wrapper',
    );
    
    tokenNl = _lib.lookupFunction<LlamaTokenNlNative, LlamaTokenNl>(
      'llama_token_nl_wrapper',
    );
    
    // nVocab = _lib.lookupFunction<LlamaNVocabNative, LlamaNVocab>(
    //   'llama_model_n_vocab',
    // );
    
    nCtx = _lib.lookupFunction<LlamaNCtxNative, LlamaNCtx>('llama_n_ctx_wrapper');
    
    nEmbd = _lib.lookupFunction<LlamaNEmbdNative, LlamaNEmbd>('llama_model_n_embd_wrapper');
  }
  final DynamicLibrary _lib;
  
  late final LlamaBackendInit backendInit;
  late final LlamaModelDefaultParams modelDefaultParams;
  late final LlamaContextDefaultParams contextDefaultParams;
  late final LlamaModelLoadFromFile modelLoadFromFile;
  late final LlamaInitFromModel initFromModel;
  late final LlamaFreeModel freeModel;
  late final LlamaFree free;
  late final LlamaTokenize tokenize;
  late final LlamaDecode decode;
  late final LlamaBatchGetOne batchGetOne;
  late final LlamaSamplerChainDefaultParams samplerChainDefaultParams;
  late final LlamaSamplerChainInit samplerChainInit;
  late final LlamaSamplerChainAdd samplerChainAdd;
  late final LlamaSamplerInitTopK samplerInitTopK;
  late final LlamaSamplerInitTopP samplerInitTopP;
  late final LlamaSamplerInitTemp samplerInitTemp;
  late final LlamaSamplerInitDist samplerInitDist;
  late final LlamaSamplerSample samplerSample;
  late final LlamaSamplerFree samplerFree;
  late final LlamaModelGetVocab modelGetVocab;
  late final LlamaTokenToPiece tokenToPiece;
  late final LlamaGetLogits getLogits;
  late final LlamaGetEmbeddings getEmbeddings;
  late final LlamaTokenBos tokenBos;
  late final LlamaTokenEos tokenEos;
  late final LlamaTokenNl tokenNl;
  // late final LlamaNVocab nVocab;
  late final LlamaNCtx nCtx;
  late final LlamaNEmbd nEmbd;
}
