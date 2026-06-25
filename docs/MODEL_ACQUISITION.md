# Model Acquisition Guide for IrisLime

## Standard Download Method

IrisLime uses the **HuggingFace Hub CLI (`hf`)** for model downloads. This is the standardized approach for reproducible, forensic-aware model management.

### Prerequisites

Ensure the HuggingFace CLI is installed:
```bash
pip install huggingface-hub
```

Verify installation:
```bash
hf --version
```

## TinyLlama-1.1B-Chat (GGUF)

### Model Details
- **Repository:** `TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF`
- **Filename:** `TinyLlama-1.1B-Chat-v1.0.Q4_K_M.gguf`
- **Size:** ~650 MB
- **Format:** GGUF (quantized to Q4_K_M - 4-bit)
- **BF16 Support:** ✅ None (pure F16 operations - fully compatible with Iris Xe SYCL)

### Direct Download via HF CLI

```bash
source config_env
hf download TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF \
  TinyLlama-1.1B-Chat-v1.0.Q4_K_M.gguf \
  --local-dir models/
```

### Via Python Model Manager

Create a Python script to download:
```python
from tools.model_manager import download_model

download_model(
    "TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF",
    "TinyLlama-1.1B-Chat-v1.0.Q4_K_M.gguf"
)
```

## Why GGUF + Q4_K_M?

| Format | Size | Speed | Quality | Notes |
|--------|------|-------|---------|-------|
| **Q4_K_M (GGUF)** | 650 MB | Fast | Good | **Recommended** - balances size & quality |
| Q3_K_M (GGUF) | 450 MB | Fast | Fair | Too aggressive quantization |
| Q5_K_M (GGUF) | 900 MB | Medium | Better | Larger, minimal improvement |
| F16 (original) | 2.2 GB | Slow | Excellent | Too large for edge devices |

## Why Not BF16?

BF16 (bfloat16) reduces model size but sacrifices precision. Intel Iris Xe's SYCL backend has **no native BF16 support**, causing fallback operations to fail silently or crash. Always choose **F16 or quantized F16-based formats (Q4_K_M, Q5_K_M)**.

## Model Storage

All models are stored via symlink at `models/` → `~/src/ai_models/` to:
- Prevent Git bloat (binary files excluded)
- Enable central management across projects
- Maintain forensic auditability

## Verification

After download, verify the model:
```bash
ls -lh models/TinyLlama-1.1B-Chat-v1.0.Q4_K_M.gguf
file models/TinyLlama-1.1B-Chat-v1.0.Q4_K_M.gguf
```

Expected output:
```
-rw-r--r-- 1 user user 662M ... models/TinyLlama-1.1B-Chat-v1.0.Q4_K_M.gguf
models/TinyLlama-1.1B-Chat-v1.0.Q4_K_M.gguf: data
```

## Forensic Metadata

Track model provenance in `build_meta.json`:
```json
{
  "model": {
    "name": "TinyLlama-1.1B-Chat-v1.0",
    "source": "TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF",
    "filename": "TinyLlama-1.1B-Chat-v1.0.Q4_K_M.gguf",
    "size_mb": 662,
    "format": "GGUF Q4_K_M",
    "acquired_date": "2026-06-22"
  }
}
```

---

## Alternative Models (Future Reference)

If you need to switch models later:

### Llama-2-7B (Better Quality, Larger)
```bash
hf download TheBloke/Llama-2-7b-Chat-GGUF \
  Llama-2-7b-chat.Q4_K_M.gguf --local-dir models/
```
Size: ~4.2 GB

### Mistral-7B (High Efficiency)
```bash
hf download TheBloke/Mistral-7B-Instruct-v0.1-GGUF \
  mistral-7b-instruct-v0.1.Q4_K_M.gguf --local-dir models/
```
Size: ~4.7 GB

---

## Troubleshooting

**Q: `hf download` command not found?**
A: Install huggingface-hub: `pip install huggingface-hub`

**Q: Network timeout during download?**
A: Use `--resume-download` flag: `hf download <repo> <file> --local-dir models/ --resume-download`

**Q: Model file corrupted?**
A: Delete and re-download: `rm models/<filename> && hf download <repo> <file> --local-dir models/`
