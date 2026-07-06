# Matrix Control Reference Manual

This file serves as the authoritative user-facing documentation for the configuration parameters available inside `matrix_control.json`. This JSON manifest governs the global orchestration layer, compilation options, and hyperparameter testing sweeps for the IrisLime multi-backend validation pipeline.

## 1. Global Settings
The `global_settings` dictionary establishes baseline guardrails enforced across all compilation targets and host discovery layers.

* `min_required_disk_space_gb` *(float)*: Minimum free storage threshold verified before launching any build passes to prevent unexpected disk allocation failures.
* `test_model` *(string)*: Relative or absolute path targeting the default GGUF or model weights file used during standard evaluation passes.
* `hardware_db_path` *(string)*: Filesystem target where the idempotent hardware prober caches host instruction capabilities to enable fast compiler bypass passes.

## 2. Backend Overrides
Each key within `backend_overrides` matches an explicit compilation module (`openvino`, `sycl`, `vulkan`, `litert`, `base`) and accepts the following validation parameters:

* `enabled` *(boolean)*: Toggles whether the build runner processes this specific framework target during automated global sweeps.
* `parallel_jobs` *(integer)*: Maps the maximum core count thread pool size (`-j`) passed to the underlying compilation engine.
* `inactivity_timeout_seconds` *(integer)*: Configures the absolute silence budget allocated to the watchdog thread before interpreting a build stall.
* `fail_fast` *(boolean)*: Governs whether a node failure within a backend sweep instantly aborts the remaining execution branches.

### 2.1 Profile Layout Arrays
The `ordered_profiles` key defines an array of structural configurations built in sequential sequence. Each profile block requires:
* `name` *(string)*: The native compiler target definition mapping directly to `CMAKE_BUILD_TYPE` (`Debug`, `Release`, `RelWithDebInfo`).
* `suffix` *(string)*: The isolated subdirectory name inside the `build/` folder used to keep object files separated and prevent cross-optimization pollution.
* `track_telemetry` *(boolean)*: Toggles whether the evaluation manager parses and logs this profile's output numbers to the cumulative CSV database.

### 2.2 Hyperparameter Testing Matrices
The `test_matrix_parameters` block configures the combinatorial sweep array evaluated during evaluation steps:
* `context_sizes` *(array of integers)*: Evaluates token generation limits passed to the inference pipeline via the `-p` parameter flag.
* `batch_sizes` *(array of integers)*: Sets physical sequence chunk dimensions passed via the `-b` parameter flag.
* `gpu_layers_offload` *(array of integers)*: Drives layers streaming directly into processing cores (`-1` for total offload, `0` for raw host CPU fallback verification).
