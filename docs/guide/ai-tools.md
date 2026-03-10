# 🤖 AI Developer Tools

A modern developer workstation is incomplete without intelligent assistance. We have integrated **Ollama**, allowing you to run state-of-the-art AI models **100% locally** on your hardware. 

No cloud, no API keys, and no data leaves your machine.

---

## The Models

Our setup defaults to providing three carefully curated models that target specific developer workflows:

### 1. `qwen3:30b-a3b` (The flagship reasoner)
* **Architecture**: Mixture of Experts (MoE)
* **Parameters**: 30 Billion total (only ~3 Billion active during inference).
* **RAM Requirement**: 16 GB minimum, 32 GB recommended.
* **Disk Space**: ~18 GB.
* **Use Case**: This is your flagship model. Because it uses MoE architecture, it produces reasoning quality comparable to a dense 30B model (like GPT-4 class logic), but generates tokens at the blistering speed of a 7B model. Perfect for architectural debates, strategy, and deep reasoning.

### 2. `deepseek-r1:7b` (Chain-of-thought engine)
* **Architecture**: Dense
* **Parameters**: 7 Billion
* **RAM Requirement**: 8 GB minimum
* **Disk Space**: ~5 GB
* **Use Case**: DeepSeek-R1 forces itself to output "chain-of-thought" logic before answering. Excellent for highly complex, multi-step math or logical puzzles where you need to see the AI's "work" before its conclusion.

### 3. `qwen2.5-coder:7b` (The syntax generator)
* **Architecture**: Dense
* **Parameters**: 7 Billion
* **RAM Requirement**: 8 GB minimum
* **Disk Space**: ~5 GB
* **Use Case**: Hardwired directly into the `nexus doctor` AI-tuner. This model is exceptionally good at reading raw CLI outputs (like `top` or `vmstat`) and writing shell scripts, Python, or SQL. It is fast, lightweight, and focused purely on code.

---

## How to Access

You have three primary methods to interact with these models:

### 1. The Nexus Dashboard
Press `Super+X` to launch Nexus.
You'll see options like:
* `󰧑 AI Chat — Reasoning (qwen3)`
* `󰧑 AI Chat — Logic (deepseek)`
Choosing any of these instantly drops you into a floating terminal session interacting with the model.

### 2. The AI Auto-Tuner (`nexus doctor`)
Also accessible via Nexus, this tool runs background telemetry, feeds the raw data silently to `qwen2.5-coder:7b` via local cURL requests to the Ollama API port `11434`, and presents optimization advice.

### 3. Terminal Interface
Just type normal Ollama commands anywhere:
```bash
ollama run qwen3:30b-a3b
ollama run qwen2.5-coder:7b
```

---

## Editor Integration (Antigravity)

Module 07 installs **Antigravity**, an AI-powered code editor (see [antigravity.google](https://antigravity.google) for official docs).
If Antigravity is not available on Arch Linux via AUR, the installer will attempt to extract it from the official Debian package or fall back to **Cursor** (`cursor-bin` from AUR) as an alternative AI-powered editor.

Both editors support AI-assisted coding features. For local model integration, start Ollama separately and configure the editor to connect to `http://localhost:11434`.
