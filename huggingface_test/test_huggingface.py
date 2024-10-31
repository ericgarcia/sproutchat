from transformers import AutoModelForCausalLM, AutoTokenizer, pipeline
import torch

# Load model and tokenizer
model_name = "internlm/internlm2_5-7b-chat"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForCausalLM.from_pretrained(model_name, torch_dtype=torch.float16).to("cuda")

# Set up the chat pipeline
chat = pipeline("text-generation", model=model, tokenizer=tokenizer, device=0)

# Example usage
response = chat("Hello! How can I assist you today?", max_length=50)
print(response[0]['generated_text'])
