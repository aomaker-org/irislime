# ==============================================================================
# IrisLime Project Infrastructure Map
# Filename:    tools/runner/matrix_control.py
# Purpose:     Polymorphic build, test, and optimization targets for Pavlov
# Type:        Python 3 Configuration Module (Imported by tools.runner submodules)
# Attribution: fekerr & Gemini (20260706_1122 / Modular Matrix Generation Pass)
# Timestamp:   20260706_1122
# ==============================================================================

import os
import multiprocessing

def get_system_ram_gib():
    """Queries kernel maps dynamically to ascertain true physical capacity."""
    try:
        return round(os.sysconf('SC_PAGE_SIZE') * os.sysconf('SC_PHYS_PAGES') / (1024**3), 2)
    except (AttributeError, ValueError):
        return 4.0  # Safe defensive fallback for bounded environments

# --- DYNAMIC HOST METRIC DISCOVERY ---
TOTAL_PHYSICAL_RAM = get_system_ram_gib()
CPU_CORE_COUNT     = multiprocessing.cpu_count()

# --- THE ZERO-THRASH MATRIX THROTTLE ---
# If the architecture detects that physical memory drops below a strict 4.0 GiB ceiling,
# it automatically overrides compiler parallelization fields to a single thread (-j1).
# This guarantees protection against OOM thrashing on resource-constrained systems.
if TOTAL_PHYSICAL_RAM < 4.0:
    DEFAULT_BUILD_JOBS = 1
else:
    DEFAULT_BUILD_JOBS = max(1, CPU_CORE_COUNT - 1)

# --- GLOBAL ARCHITECTURE DEFINITIONS ---
WORKSPACE_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
ENGINE_SOURCE  = "llama.cpp"  # Monolithic compilation anchor folder

# ==============================================================================
# CORE COMPILATION TARGET TARGET MATRIX
# ==============================================================================
BUILD_MATRIX = {
    "openvino": {
        "enabled": True,
        "source_tree": ENGINE_SOURCE,
        "parallel_jobs": DEFAULT_BUILD_JOBS,
        "profiles": {
            "debug": {
                "dir": "build/openvino_debug",
                "type": "Debug",
                "flags": ["-DGGML_EXCEPTIONS=ON"]
            },
            "release": {
                "dir": "build/openvino_release",
                "type": "Release",
                "flags": ["-DGGML_EXCEPTIONS=ON"]
            },
            "relwithdebinfo": {
                "dir": "build/openvino_relwithdebinfo",
                "type": "RelWithDebInfo",
                "flags": ["-DGGML_EXCEPTIONS=ON"]
            }
        },
        "extra_launcher_flags": [
            "-DCMAKE_C_COMPILER_LAUNCHER=ccache",
            "-DCMAKE_CXX_COMPILER_LAUNCHER=ccache"
        ]
    },
    
    "sycl": {
        "enabled": True,
        "source_tree": ENGINE_SOURCE,
        "parallel_jobs": DEFAULT_BUILD_JOBS,
        "profiles": {
            "debug": {
                "dir": "build/sycl_debug",
                "type": "Debug",
                "flags": ["-DGGML_SYCL=ON"]
            },
            "release": {
                "dir": "build/sycl_release",
                "type": "Release",
                "flags": ["-DGGML_SYCL=ON"]
            }
        },
        # Modern Intel 2026 oneAPI Compatibility Layer:
        # Dynamically sources the active subshell $MKLROOT pointer to inject modern
        # path configuration keys directly into the CMake prefix search arrays.
        "extra_launcher_flags": [
            f"-DCMAKE_PREFIX_PATH={os.environ.get('MKLROOT', '/opt/intel/oneapi/mkl/latest')}/lib/cmake/mkl",
            "-DCMAKE_C_COMPILER_LAUNCHER=ccache",
            "-DCMAKE_CXX_COMPILER_LAUNCHER=ccache"
        ]
    }
}

# ==============================================================================
# AUTOMATED VALIDATION HARNESS TESTING MATRIX
# ==============================================================================
TEST_MATRIX = {
    "openvino": {
        "target_binary": "bin/llama",
        "smoke_phase": {
            "command_args": ["version"],
            "expected_tokens": []
        },
        "inference_phase": {
            "command_args": ["completion", "-p", "Validation Check.", "-n", "16", "--threads", "1", "--ctx-size", "512"],
            "fallback_model": "models/test_baseline.gguf"
        }
    },
    
    "sycl": {
        "target_binary": "bin/llama",
        "smoke_phase": {
            "command_args": ["version"],
            "expected_tokens": []
        },
        "inference_phase": {
            "command_args": ["completion", "-p", "Validation Check.", "-n", "8", "--threads", "1", "--ctx-size", "256"],
            "fallback_model": "models/test_baseline.gguf"
        }
    }
}
