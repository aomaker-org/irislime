--- BEGIN FILE: AI_next.md | Size: TODO bytes | SHA256: TODO ---
# IrisLime Next Session Action Item: OpenVINO Build Resolution
# Filename:    AI_next.md
# Location:    Repository Root (/)
# Timestamp:   20260630_1100
# Attribution: fekerr & Gemini (20260630_1100 / flash 3.5 extended)
# Purpose:     Active state handover payload for Task Block 1 execution

## 1. Target Context & Blockade Snapshot
* **Current State:** The out-of-tree OpenVINO build matrix (`make build-openvino`) is failing during CMake initialization because Ubuntu 24.04 LTS (Noble) does not include `libopenvino-dev` in its default system channels.
* **Hardware Constraints:** Intel Core i7-1255U (Hypervisor pass-through via WSL2 to Ubuntu). Guest memory is strictly limited to **7 GB RAM**, forcing a `NUM_BUILD_JOBS=1` requirement to prevent system OOM errors.

## 2. Step-by-Step Execution Remediation Plan

### Step A: Inject Intel's Official OpenVINO APT Key & Channel
Execute the following commands within the WSL2 guest environment to authorize and add the official 2024 architecture channel:
```bash
wget [https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB](https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB) -O- | \
sudo gpg --dearmor -o /usr/share/keyrings/intel-sw-products.gpg

echo "deb [signed-by=/usr/share/keyrings/intel-sw-products.gpg] [https://apt.repos.intel.com/openvino/2024](https://apt.repos.intel.com/openvino/2024) ubuntu24 main" | \
sudo tee /etc/apt/sources.list.d/intel-openvino.list

sudo apt-get update
