# Getting Started with IrisLime

**IrisLime** is a research-focused environment designed to facilitate local, small-scale Large Language Model (LLM) inference on Intel Iris Xe integrated graphics, leveraging WSL2 and the Intel oneAPI toolkit.

## 1. Prerequisites
- **Windows 11** with WSL2 enabled.
- [Intel oneAPI Base Toolkit](https://www.intel.com/content/www/us/en/developer/tools/oneapi/base-toolkit.html) installed (v2026 recommended).
- Ensure Windows host GPU drivers are current.

## 2. System Configuration (Manual)
To bridge your Windows GPU to the WSL2 environment:
1. **Enable the vgem bridge:** Run `sudo modprobe vgem` to enable the virtual graphics module.
2. **Verification:** Check for the render node: `ls -l /dev/dri/renderD128`.
   *(If not present, ensure you have initialized your WSL2 instance after driver updates).*

## 3. Environment Setup
1. **Clone the repository:**
   ```bash
   git clone <your-repo-url>
   cd irislime
