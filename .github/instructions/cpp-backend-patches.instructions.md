---
applyTo: "llama.cpp/ggml/src/ggml-openvino/**,llama.cpp/ggml/src/**/*.cpp,llama.cpp/ggml/src/**/*.h"
description: >-
  IrisLime C++ patch conventions for OpenVINO/SYCL backend files. Applied when editing
  ggml-openvino sources, OpenVINO pass headers, or ggml backend C++ files.
---

# IrisLime C++ Backend Patch Conventions

## Attribution Header

Every patch block must begin with a one-line attribution comment:
```cpp
/* YYYYMMDD <author> | <brief reason> */
```
Example: `/* 20260623 fekerr | OPENVINO_MATCHER_PASS_RTTI compat fallback */`

## const_cast Policy

Use `const_cast<void*>` only when an OpenVINO API requires a non-const pointer and the
pointee is not mutated. Always add an inline comment citing the ov:: method name:
```cpp
// ov::Tensor::copy_from() requires void* — data is read-only source
void* mutable_ptr = const_cast<void*>(src_data);
```

## Macro Guard Pattern

When injecting compatibility macros above an existing macro callsite:
```cpp
/* IrisLime compat patch | <reason> */
#ifndef MACRO_NAME
#define MACRO_NAME(X) FALLBACK_MACRO(X)
#endif
MACRO_NAME(ClassName)  // ← original line unchanged below
```

## Preprocessor Conditional Guards

Always wrap OpenVINO-specific code:
```cpp
#ifdef GGML_USE_OPENVINO
// ... openvino-specific logic
#endif // GGML_USE_OPENVINO
```

## No Speculative Edits

Do not modify lines outside the immediate error context. Limit patches to the smallest
possible diff. Run `grep_search` before editing to confirm the target line is unique.
