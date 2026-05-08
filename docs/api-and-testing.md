# HTTP API and testing

Assume the app shows **local IP** (e.g. `192.168.1.5`) and port **8080** (configurable in UI).

<img width="1066" height="808" alt="image" src="https://github.com/user-attachments/assets/7fc3bf3b-97bb-4232-9b33-c3b80a937ea8" />


**Base URL:** `http://<phone-ip>:8080`

## Health

**GET** `/health`

Expect JSON with status OK when the server is up.

## Chat (OpenAI-compatible)

**POST** `/v1/chat/completions`  
**Headers:** `Content-Type: application/json`

Example body:

```json
{
  "messages": [
    { "role": "user", "content": "Hello in one short sentence." }
  ],
  "max_tokens": 64,
  "temperature": 0.7
}
```

Response shape matches OpenAI-style chat completions (`choices`, `usage`, etc.).  
llama.cpp may also include extra fields such as **`timings`** (prefill vs decode speed).

## Legacy / simple completion

**POST** `/completion`  
(Exact JSON schema depends on llama-server version; often `prompt`, `n_predict`, `temperature`.)

## Postman

1. Create a request: method **GET** or **POST**, URL as above.
2. For POST, Body → **raw** → **JSON**.
3. Ensure phone and PC are on the **same Wi‑Fi**; disable VPN if it blocks LAN.
4. If the request hangs, confirm the app shows **Server Running** and check `adb logcat`.

## Reading `timings` in responses

Example fields:

| Field | Meaning |
|-------|---------|
| `prompt_n` / `prompt_ms` | Input tokens and time to process them |
| `predicted_n` / `predicted_ms` | Generated tokens and generation time |
| `predicted_per_second` | Decode throughput (tokens/sec, approximate) |

Useful for tuning model size and expectations on phones.
