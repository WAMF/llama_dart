import 'dart:ffi';
import 'dart:io';

import 'package:llama_dart/src/ffi/llama_bindings_generated.dart';
import 'package:test/test.dart';

void main() {
  group('LlamaBindings', () {
    late LlamaBindingsGenerated bindings;
    late DynamicLibrary lib;

    setUpAll(() {
      final libPath = Platform.isMacOS
          ? './libllama_wrapper.dylib'
          : Platform.isLinux
              ? './libllama_wrapper.so'
              : './llama_wrapper.dll';
      
      lib = DynamicLibrary.open(libPath);
      bindings = LlamaBindingsGenerated(lib);
    });

    test('can initialize backend', () {
      expect(() => bindings.llama_backend_init_wrapper(), returnsNormally);
    });

    test('can get default model params', () {
      final params = bindings.llama_model_default_params_wrapper();
      expect(params.n_ctx, equals(2048));
      expect(params.n_batch, equals(512));
      expect(params.n_threads, equals(4));
      expect(params.use_mmap, equals(true));
      expect(params.use_mlock, equals(false));
    });

    test('can get default context params', () {
      final params = bindings.llama_context_default_params_wrapper();
      expect(params.n_ctx, greaterThan(0));
      expect(params.n_batch, greaterThan(0));
      expect(params.n_threads, greaterThan(0));
      expect(params.temp, closeTo(0.7, 0.01));
      expect(params.top_p, closeTo(0.9, 0.01));
      expect(params.repeat_penalty, closeTo(1.1, 0.01));
      expect(params.repeat_last_n, equals(64));
    });

    test('can get token IDs', () {
      final bosToken = bindings.llama_token_bos_wrapper();
      final eosToken = bindings.llama_token_eos_wrapper();
      final nlToken = bindings.llama_token_nl_wrapper();
      
      expect(bosToken, isA<int>());
      expect(eosToken, isA<int>());
      expect(nlToken, isA<int>());
    });

    test('can get default sampler chain params', () {
      final params = bindings.llama_sampler_chain_default_params_wrapper();
      expect(params.no_perf, isA<bool>());
    });
  });
}
