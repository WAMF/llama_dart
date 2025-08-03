#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <stdint.h>
#include "llama.cpp/include/llama.h"

typedef struct {
    uint32_t seed;
    uint32_t n_ctx;
    uint32_t n_batch;
    uint32_t n_threads;
    bool use_mmap;
    bool use_mlock;
} llama_model_params_wrapper;

typedef struct {
    uint32_t seed;
    uint32_t n_ctx;
    uint32_t n_batch;
    uint32_t n_threads;
    float temp;
    float top_p;
    float repeat_penalty;
    uint32_t repeat_last_n;
    bool use_mmap;
    bool use_mlock;
} llama_context_params_wrapper;

typedef struct {
    int32_t id;
} llama_token_wrapper;

typedef struct {
    bool no_perf;
} llama_sampler_chain_params_wrapper;

typedef struct {
    int32_t n_tokens;
    int32_t* token;
    float* embd;
    int32_t* pos;
    int32_t* n_seq_id;
    int32_t** seq_id;
    int8_t* logits;
} llama_batch_wrapper;

void llama_backend_init_wrapper() {
    llama_backend_init();
}

llama_model_params_wrapper llama_model_default_params_wrapper() {
    struct llama_model_params params = llama_model_default_params();
    llama_model_params_wrapper wrapper_params = {
        .seed = 0,
        .n_ctx = 2048,
        .n_batch = 512,
        .n_threads = 4,
        .use_mmap = true,
        .use_mlock = false
    };
    return wrapper_params;
}

llama_context_params_wrapper llama_context_default_params_wrapper() {
    struct llama_context_params params = llama_context_default_params();
    llama_context_params_wrapper wrapper_params = {
        .seed = 0,
        .n_ctx = params.n_ctx,
        .n_batch = params.n_batch,
        .n_threads = params.n_threads,
        .temp = 0.7f,
        .top_p = 0.9f,
        .repeat_penalty = 1.1f,
        .repeat_last_n = 64,
        .use_mmap = true,
        .use_mlock = false
    };
    return wrapper_params;
}

struct llama_model* llama_model_load_from_file_wrapper(const char* path, llama_model_params_wrapper params) {
    struct llama_model_params real_params = llama_model_default_params();
    real_params.n_gpu_layers = 0;
    return llama_model_load_from_file(path, real_params);
}

struct llama_context* llama_init_from_model_wrapper(struct llama_model* model, llama_context_params_wrapper params) {
    struct llama_context_params real_params = llama_context_default_params();
    real_params.n_ctx = params.n_ctx;
    real_params.n_batch = params.n_batch;
    real_params.n_threads = params.n_threads;
    real_params.n_seq_max = 1;
    return llama_init_from_model(model, real_params);
}

void llama_model_free_wrapper(struct llama_model* model) {
    llama_model_free(model);
}

void llama_free_wrapper(struct llama_context* ctx) {
    llama_free(ctx);
}

void llama_kv_cache_clear_wrapper(struct llama_context* ctx) {
    llama_memory_t mem = llama_get_memory(ctx);
    llama_memory_clear(mem, true);
}

int32_t llama_tokenize_wrapper(const struct llama_vocab* vocab, const char* text, int32_t text_len, int32_t* tokens, int32_t n_tokens_max, bool add_special, bool parse_special) {
    return llama_tokenize(vocab, text, text_len, tokens, n_tokens_max, add_special, parse_special);
}

llama_batch_wrapper llama_batch_get_one_wrapper(int32_t* tokens, int32_t n_tokens) {
    struct llama_batch batch = llama_batch_get_one(tokens, n_tokens);
    llama_batch_wrapper wrapper = {
        .n_tokens = batch.n_tokens,
        .token = batch.token,
        .embd = batch.embd,
        .pos = batch.pos,
        .n_seq_id = batch.n_seq_id,
        .seq_id = batch.seq_id,
        .logits = batch.logits
    };
    return wrapper;
}

int32_t llama_decode_wrapper(struct llama_context* ctx, llama_batch_wrapper batch) {
    struct llama_batch real_batch = {
        .n_tokens = batch.n_tokens,
        .token = batch.token,
        .embd = batch.embd,
        .pos = batch.pos,
        .n_seq_id = batch.n_seq_id,
        .seq_id = batch.seq_id,
        .logits = batch.logits
    };
    return llama_decode(ctx, real_batch);
}

llama_sampler_chain_params_wrapper llama_sampler_chain_default_params_wrapper() {
    struct llama_sampler_chain_params params = llama_sampler_chain_default_params();
    llama_sampler_chain_params_wrapper wrapper = {
        .no_perf = params.no_perf
    };
    return wrapper;
}

struct llama_sampler* llama_sampler_chain_init_wrapper(llama_sampler_chain_params_wrapper params) {
    struct llama_sampler_chain_params real_params = llama_sampler_chain_default_params();
    real_params.no_perf = params.no_perf;
    return llama_sampler_chain_init(real_params);
}

void llama_sampler_chain_add_wrapper(struct llama_sampler* chain, struct llama_sampler* smpl) {
    llama_sampler_chain_add(chain, smpl);
}

struct llama_sampler* llama_sampler_init_top_k_wrapper(int32_t k) {
    return llama_sampler_init_top_k(k);
}

struct llama_sampler* llama_sampler_init_top_p_wrapper(float p, size_t min_keep) {
    return llama_sampler_init_top_p(p, min_keep);
}

struct llama_sampler* llama_sampler_init_temp_wrapper(float t) {
    return llama_sampler_init_temp(t);
}

struct llama_sampler* llama_sampler_init_dist_wrapper(uint32_t seed) {
    return llama_sampler_init_dist(seed);
}

int32_t llama_sampler_sample_wrapper(struct llama_sampler* smpl, struct llama_context* ctx, int32_t idx) {
    return llama_sampler_sample(smpl, ctx, idx);
}

void llama_sampler_free_wrapper(struct llama_sampler* smpl) {
    llama_sampler_free(smpl);
}

void llama_sampler_reset_wrapper(struct llama_sampler* smpl) {
    llama_sampler_reset(smpl);
}

const struct llama_vocab* llama_model_get_vocab_wrapper(const struct llama_model* model) {
    return llama_model_get_vocab(model);
}

int32_t llama_token_to_piece_wrapper(const struct llama_vocab* vocab, int32_t token, char* buf, int32_t length, int32_t lstrip, bool special) {
    return llama_token_to_piece(vocab, token, buf, length, lstrip, special);
}

float* llama_get_logits_wrapper(struct llama_context* ctx) {
    return llama_get_logits(ctx);
}

float* llama_get_embeddings_wrapper(struct llama_context* ctx) {
    return llama_get_embeddings(ctx);
}

int32_t llama_token_bos_wrapper() {
    // Return a default BOS token ID
    return 1;
}

int32_t llama_token_eos_wrapper() {
    // Return a default EOS token ID
    return 2;
}

int32_t llama_token_nl_wrapper() {
    // Return a default newline token ID
    return 13;
}

int32_t llama_n_ctx_wrapper(const struct llama_context* ctx) {
    return llama_n_ctx(ctx);
}

int32_t llama_model_n_embd_wrapper(const struct llama_model* model) {
    return llama_model_n_embd(model);
}