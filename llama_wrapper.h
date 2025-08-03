#ifndef LLAMA_WRAPPER_H
#define LLAMA_WRAPPER_H

#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Forward declarations
struct llama_model;
struct llama_context;
struct llama_vocab;
struct llama_sampler;

// Wrapper structures
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

// Backend initialization
void llama_backend_init_wrapper(void);

// Default parameters
llama_model_params_wrapper llama_model_default_params_wrapper(void);
llama_context_params_wrapper llama_context_default_params_wrapper(void);
llama_sampler_chain_params_wrapper llama_sampler_chain_default_params_wrapper(void);

// Model operations
struct llama_model* llama_model_load_from_file_wrapper(const char* path, llama_model_params_wrapper params);
void llama_model_free_wrapper(struct llama_model* model);

// Context operations
struct llama_context* llama_init_from_model_wrapper(struct llama_model* model, llama_context_params_wrapper params);
void llama_free_wrapper(struct llama_context* ctx);
void llama_kv_cache_clear_wrapper(struct llama_context* ctx);

// Tokenization
int32_t llama_tokenize_wrapper(const struct llama_vocab* vocab, const char* text, int32_t text_len, int32_t* tokens, int32_t n_tokens_max, bool add_special, bool parse_special);

// Batch operations
llama_batch_wrapper llama_batch_get_one_wrapper(int32_t* tokens, int32_t n_tokens);
int32_t llama_decode_wrapper(struct llama_context* ctx, llama_batch_wrapper batch);

// Sampling
struct llama_sampler* llama_sampler_chain_init_wrapper(llama_sampler_chain_params_wrapper params);
void llama_sampler_chain_add_wrapper(struct llama_sampler* chain, struct llama_sampler* smpl);
struct llama_sampler* llama_sampler_init_top_k_wrapper(int32_t k);
struct llama_sampler* llama_sampler_init_top_p_wrapper(float p, size_t min_keep);
struct llama_sampler* llama_sampler_init_temp_wrapper(float t);
struct llama_sampler* llama_sampler_init_dist_wrapper(uint32_t seed);
int32_t llama_sampler_sample_wrapper(struct llama_sampler* smpl, struct llama_context* ctx, int32_t idx);
void llama_sampler_free_wrapper(struct llama_sampler* smpl);
void llama_sampler_reset_wrapper(struct llama_sampler* smpl);

// Vocabulary operations
const struct llama_vocab* llama_model_get_vocab_wrapper(const struct llama_model* model);
int32_t llama_token_to_piece_wrapper(const struct llama_vocab* vocab, int32_t token, char* buf, int32_t length, int32_t lstrip, bool special);

// Token IDs
int32_t llama_token_bos_wrapper(void);
int32_t llama_token_eos_wrapper(void);
int32_t llama_token_nl_wrapper(void);

// Model information
int32_t llama_n_ctx_wrapper(const struct llama_context* ctx);
int32_t llama_model_n_embd_wrapper(const struct llama_model* model);

// Logits and embeddings
float* llama_get_logits_wrapper(struct llama_context* ctx);
float* llama_get_embeddings_wrapper(struct llama_context* ctx);

#ifdef __cplusplus
}
#endif

#endif // LLAMA_WRAPPER_H