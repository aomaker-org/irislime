import requests

# Local model endpoints (e.g., llama.cpp server instances running on different ports)
MODELS = {
    "variant_alpha": "http://localhost:8081/v1/chat/completions",
    "variant_bravo": "http://localhost:8082/v1/chat/completions",
    "variant_charlie": "http://localhost:8083/v1/chat/completions"
}

def ask_model_about_file(endpoint: str, file_packet: dict) -> str:
    """Queries a specific model variant to classify or explain a file's purpose."""
    prompt = f"""
    Analyze this file metadata and sample content. Determine what kind of data it holds, its potential importance to a developer/engineer, and a 1-sentence summary.
    
    File Path: {file_packet['path']}
    Mime Type: {file_packet['mime_type']}
    Size: {file_packet['size_bytes']} bytes
    
    Content Sample (First 1KB):
    ---
    {file_packet['content_sample']}
    ---
    
    Return your analysis as a direct string.
    """
    
    payload = {
        "model": "local",
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.1  # Keeping it deterministic to compare raw analytical capacity
    }
    
    try:
        response = requests.post(endpoint, json=payload, timeout=10)
        return response.json()['choices'][0]['message']['content'].strip()
    except Exception as e:
        return f"Inference Error: {str(e)}"
