# Proposed AI Edge Targets for local inference

Running local AI models efficiently requires targeting architectures that balance low power consumption with capable edge computing potential. Here are some of the most promising and popular edge targets that would complement our current Intel Iris Xe setup:

## 1. Apple Silicon (M-Series / A-Series)
- **Architecture**: ARM64 with Apple GPU and Neural Engine (NPU).
- **Why it matters**: Apple Silicon provides unified memory and exceptional memory bandwidth, making it currently one of the most powerful and efficient architectures for running large models locally.
- **Support**: `llama.cpp` has deep optimization for Apple Silicon via the Metal framework, offering GPU acceleration directly on MacBooks, Mac Minis, and potentially iOS devices.

## 2. Raspberry Pi 5 (and Raspberry Pi 4)
- **Architecture**: ARM Cortex-A76 (ARM64).
- **Why it matters**: The most ubiquitous edge computing device. The Pi 5 brings a significant CPU performance boost over the Pi 4 and supports PCIe, allowing for potential external accelerators.
- **Support**: Readily supported via ARM NEON instructions in `llama.cpp`, allowing smaller models (like 1B-3B parameters at Q4) to run at reasonable tokens/second.

## 3. NVIDIA Jetson Series (Orin Nano, Xavier NX)
- **Architecture**: ARM64 CPU + NVIDIA Ampere/Volta GPU.
- **Why it matters**: Designed explicitly for edge AI. Provides full CUDA support in a low-power envelope.
- **Support**: `llama.cpp` supports CUDA natively, making it trivial to offload matrix multiplications to the Jetson's GPU for massive performance gains over CPU inference.

## 4. Rockchip RK3588 (Orange Pi 5, Radxa Rock 5)
- **Architecture**: Octa-core ARM (Cortex-A76 + A55) + Mali-G610 GPU + 6 TOPS NPU.
- **Why it matters**: Exceptional price-to-performance ratio for edge single-board computers (SBCs). The CPU is surprisingly capable.
- **Support**: CPU inference runs well. Work is ongoing in the community to better support the Mali GPU (via OpenCL/Vulkan) and eventually the Rockchip NPU.

## 5. Qualcomm Snapdragon X Elite / ARM Windows Devices
- **Architecture**: ARM64 + Adreno GPU + Hexagon NPU.
- **Why it matters**: The new wave of ARM-based Windows PCs offers strong CPU performance and dedicated NPUs.
- **Support**: Can be run natively on ARM64 Windows. GPU support can be achieved via Vulkan or OpenCL backends in `llama.cpp`.

## 6. Android/Termux (Smartphones & Tablets)
- **Architecture**: ARM64.
- **Why it matters**: Leverages devices people already own. High-end smartphone SoCs (Snapdragon 8 Gen series, MediaTek Dimensity) have immense compute power and fast memory.
- **Support**: Can be compiled natively for Android using the NDK, or run within Termux.

## 7. RISC-V Edge Boards (e.g., VisionFive 2, Milk-V Pioneer)
- **Architecture**: RISC-V (RV64GC).
- **Why it matters**: The emerging open-standard instruction set architecture.
- **Support**: `llama.cpp` supports generic C++ compilation, making it portable to RISC-V. Optimizations leveraging RISC-V vector extensions (RVV) are actively being developed.
