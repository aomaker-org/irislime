# IrisLime Quick Start Deployment Recipe

This guide is the friction-free installation sequence for bringing up the IrisLime development environment on a newly cloned machine. Follow these exact terminal steps to link your trees, arm the environment, and execute your first hardware validation test.

## Step 1: Establish Sibling Tree Structure
The workspace requires your custom `llama.cpp` engine fork to sit as a direct sibling to the `irislime` project directory. 

Execute this block to verify your pathing and establish the required development symlinks:

```bash
# Navigate to your central development directory
cd ~/src

# Clone the custom engine fork if it is not already present on this machine
git clone git@github.com:aomaker-org/llama.cpp.git

# Enter your active project workspace
cd ~/src/irislime

# Link the sibling engine fork into the workspace
ln -sf ../llama.cpp llama.cpp

# Create a centralized local storage directory for model binaries and link it
mkdir -p ~/src/ai_models
ln -sf ~/src/ai_models models
