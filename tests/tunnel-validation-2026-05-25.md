# Buildify AI Server — Cloudflare Tunnel Validation Tests

**Date:** 2026-05-25
**Tunnel URL:** `https://publication-pursuit-protected-understand.trycloudflare.com`
**Model:** TinyLlama 1.1B Chat v1.0 Q4_K_M (667MB GGUF)
**Device:** Android phone (ARM, running llama-server on localhost:8080, exposed via cloudflared quick tunnel)

---

## 1. Health Check

**Endpoint:** `GET /health`

```json
{"status": "ok"}
```

**Result:** Passed

---

## 2. Model Listing

**Endpoint:** `GET /v1/models`

```json
{
  "models": [
    {
      "name": "tinyllama-1.1b-chat-v1.0-q4_k_m.gguf",
      "model": "tinyllama-1.1b-chat-v1.0-q4_k_m.gguf",
      "object": "model",
      "created": 1779706243,
      "owned_by": "llamacpp",
      "meta": {
        "vocab_type": 1,
        "n_vocab": 32000,
        "n_ctx_train": 2048,
        "n_embd": 2048,
        "n_params": 1100048384,
        "size": 667078656
      }
    }
  ]
}
```

**Result:** Passed — model correctly listed with metadata

---

## 3. Simple Factual Accuracy

**Endpoint:** `POST /v1/chat/completions`

```json
{
  "messages": [
    {"role": "system", "content": "You are a concise assistant. Answer in exactly 1-2 sentences."},
    {"role": "user", "content": "What is 2+2?"}
  ],
  "max_tokens": 64,
  "temperature": 0.3
}
```

**Response:**

```json
{
  "choices": [
    {
      "finish_reason": "stop",
      "message": {
        "role": "assistant",
        "content": "2 + 2 = 4"
      }
    }
  ],
  "usage": {
    "completion_tokens": 8,
    "prompt_tokens": 49,
    "total_tokens": 57
  },
  "timings": {
    "prompt_n": 39,
    "prompt_ms": 344.461,
    "prompt_per_second": 113.22,
    "predicted_n": 8,
    "predicted_ms": 392.529,
    "predicted_per_second": 20.38
  }
}
```

**Result:** Passed — correct answer, fast response

---

## 4. Conceptual Explanation — TCP vs UDP

**Request:**

```json
{
  "messages": [
    {"role": "system", "content": "You are a helpful, concise assistant. Answer in 2-3 sentences maximum. Be accurate and direct."},
    {"role": "user", "content": "Explain the difference between TCP and UDP."}
  ],
  "max_tokens": 256,
  "temperature": 0.7
}
```

**Response (truncated at 256 tokens):**

```
TCP/IP is the foundation of the internet, which is responsible for establishing a connection
between two or more devices on the internet. TCP/IP uses the Internet Protocol (IP) to route
packets between devices and maintains the connection between them...

TCP/IP is designed to handle a large volume of data, while UDP is more suitable for low-latency,
real-time applications such as real-time games, web browsing, and video streaming.

UDP is a protocol that operates on the Internet Protocol (IP) and uses port numbers to
establish a connection between devices. It is not designed for high...
```

**Timings:**

| Metric | Value |
|--------|-------|
| Prompt tokens | 59 |
| Prompt speed | 121.8 tok/s |
| Generated tokens | 256 |
| Decode speed | 6.9 tok/s |

**Result:** Partial — conceptually correct but verbose, hit max_tokens limit. Failed to stay within 2-3 sentences.

---

## 5. Code Generation — Palindrome Function

**Request:**

```json
{
  "messages": [
    {"role": "system", "content": "You are a helpful assistant. Be accurate and honest. If you are not sure, say so."},
    {"role": "user", "content": "Write a Python function that checks if a string is a palindrome. Keep it short."}
  ],
  "max_tokens": 128,
  "temperature": 0.4
}
```

**Response:**

```python
def is_palindrome(s):
    s = s.lower()  # Convert string to lowercase
    s = ''.join(sorted(s))  # Convert to alphabetical order  ← BUG: should not sort
    return s == s[::-1]  # Check if reversed string is same as original
```

**Timings:**

| Metric | Value |
|--------|-------|
| Prompt tokens | 67 |
| Prompt speed | 28.0 tok/s |
| Decode speed | 13.3 tok/s |

**Result:** Failed — the function sorts the string before comparing, which is wrong logic. Classic small-model hallucination. A correct implementation would be `s == s[::-1]` without sorting.

---

## 6. Reasoning — Trick Question

**Request:**

```json
{
  "messages": [
    {"role": "system", "content": "You are a helpful, accurate assistant. Think step by step."},
    {"role": "user", "content": "A farmer has 17 sheep. All but 9 run away. How many sheep does the farmer have left?"}
  ],
  "max_tokens": 128,
  "temperature": 0.3
}
```

**Response:**

```
The farm owner has 17 sheep, and all but 9 sheep run away. Therefore, the farm owner has 18 sheep left.
```

**Timings:**

| Metric | Value |
|--------|-------|
| Prompt tokens | 65 |
| Prompt speed | 104.1 tok/s |
| Decode speed | 8.7 tok/s |

**Result:** Failed — answered 18 instead of 9. Misunderstood "all but 9" (which means 9 remain).

---

## 7. Concurrency vs Parallelism — Technical Explanation

**Request:**

```json
{
  "messages": [
    {"role": "system", "content": "You are a senior software engineer. Give brief, technically precise answers. Use code examples when relevant."},
    {"role": "user", "content": "What is the difference between concurrency and parallelism? Give a short example in Python."}
  ],
  "max_tokens": 256,
  "temperature": 0.5
}
```

**Response (truncated):**

```
In Python, concurrency and paralleism are two terms used interchangeably...

Here's a short example:

import time

def f(n):
    for I in range(n):       ← BUG: should be lowercase 'i'
        time.sleep(1)
        print("Thread #{}: {}".format(i + 1, n))  ← BUG: 'i' undefined, should be 'I'
...

threads = []                     ← Missing: import threading
```

**Timings:**

| Metric | Value |
|--------|-------|
| Prompt tokens | 71 |
| Prompt speed | 109.8 tok/s |
| Decode speed | 13.8 tok/s |

**Result:** Partial — conceptual explanation is roughly correct but the Python code has multiple bugs: missing `import threading`, uppercase `I` in `range()` but lowercase `i` in the body, and no `if __name__` guard.

---

## Performance Summary

| Metric | Range | Notes |
|--------|-------|-------|
| Prompt processing | 28–122 tok/s | KV cache hits boost speed significantly |
| Token generation | 7–24 tok/s | Depends on context length and temperature |
| Cold prompt (no cache) | ~28–110 tok/s | First request slower |
| Warm prompt (cached) | ~104–122 tok/s | Subsequent calls faster |
| End-to-end latency via tunnel | 2–40s | Depends on output length + network |

## Accuracy Summary

| Test | Result | Notes |
|------|--------|-------|
| Health check | Passed | `{"status":"ok"}` |
| Model listing | Passed | Model metadata returned correctly |
| Simple fact (2+2) | Passed | Correct, concise |
| TCP vs UDP | Partial | Correct concepts but violated 2-3 sentence constraint |
| Palindrome code | Failed | Logic error (sorts string) |
| Reasoning (sheep) | Failed | Answered 18 instead of 9 |
| Concurrency/Parallelism | Partial | Roughly correct explanation, buggy Python code |

## Recommendations

- **TinyLlama 1.1B Q4** is suitable for simple factual queries and basic chat. It struggles with reasoning, code generation, and instruction-following constraints.
- **Qwen2 1.5B Q4** (~986MB) would offer better multilingual and balanced quality at a similar size.
- **Phi-3 Mini 4K Q4** (~2.4GB) would significantly improve reasoning and code generation, but requires 6GB+ RAM.
- The Cloudflare tunnel adds negligible overhead — all latency is dominated by on-device inference speed.