# Aggressive Telemetry Build Runner Report

Generated at: 2026-07-16 06:18:16

## 1. Build Verification Results Ledger

| Backend | Profile | Elapsed (s) | Status |
|---|---|---|---|
| OPENVINO | Debug | 8.3s | ✅ SUCCESS |
| OPENVINO | RelWithDebInfo | 7.3s | ✅ SUCCESS |
| OPENVINO | Release | 8.38s | ✅ SUCCESS |
| SYCL | Debug | 1.3s | ❌ FAILED |
| SYCL | RelWithDebInfo | 1.25s | ❌ FAILED |
| SYCL | Release | 1.23s | ❌ FAILED |
| VULKAN | Debug | 11.31s | ❌ FAILED |
| VULKAN | Release | 7.91s | ❌ FAILED |
| LITERT | Debug | 0.2s | ❌ FAILED |
| LITERT | Release | 0.23s | ❌ FAILED |
| BASE | Release | 677.49s | ✅ SUCCESS |

## 2. Resource Telemetry Peak Performance Bounds

* **Peak Global CPU Utilization**: 100.0%
* **Peak Memory Allocation**: 3046.22 MB
* **Peak Swap space usage**: 103.94 MB
* **Peak Core Thermal Level**: 0.0°C
* **Average Thermal Level**: 0.0°C

> [!NOTE]
> All sensor queries were harvested dynamically from local filesystem descriptors `/proc` and `/sys` to keep WSL performance penalties negligible.

## 3. CPU Utilization Throttling Log (0 Events)

*No CPU throttling triggers were encountered (utilization remained below 50.0% boundary).* 
