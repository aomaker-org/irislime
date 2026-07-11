# Download and install the standalone uv binary
curl -fsSL https://astral.sh/uv/install.sh | sh

# Source the fresh path alignment into your active shell session
source $HOME/.local/bin/env

uv sync 
source .venv/bin/activate
