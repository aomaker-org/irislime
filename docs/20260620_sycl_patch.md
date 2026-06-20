# Intel SYCL Runtime Patch (2026-06-20)

## Issue
Intel `libze_loader` triggers `SIGSEGV` by force-loading `libze_tracing_layer.so.1`.

## Fix
We implemented a dummy library to shadow the problematic tracing layer.
1. `dummy_tracing.c` provides an empty `zelLoaderTracingLayerInit`.
2. Compiled as `libze_tracing_layer.so.1`.
3. Prepend path to `LD_LIBRARY_PATH` to resolve dependency without executing tracing code.
