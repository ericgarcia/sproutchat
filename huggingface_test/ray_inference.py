# Import necessary libraries
from transformers import AutoModelForCausalLM, AutoTokenizer, pipeline
import torch
import ray

# Initialize Ray
ray.init()

# Load model and tokenizer
model_name = "internlm/internlm2_5-7b-chat"
tokenizer = AutoTokenizer.from_pretrained(model_name, trust_remote_code=True)
model = AutoModelForCausalLM.from_pretrained(model_name, torch_dtype=torch.float16).to("cuda")

# Set up the chat pipeline
chat = pipeline("text-generation", model=model, tokenizer=tokenizer, device=0)

# Define the inference function
@ray.remote
def generate_response(prompt, max_length=50):
    response = chat(prompt, max_length=max_length)
    return response[0]['generated_text']

# Example usage
prompt = "Hello! How can I assist you today?"
future = generate_response.remote(prompt)
response = ray.get(future)
print(response)