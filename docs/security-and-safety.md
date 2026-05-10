# Security & Safety

Buildify exposes a real HTTP server on your Wi‑Fi. Two features keep that safe by default:

1. **API key** — only callers with the right key can hit your model.
2. **Auto‑stop** — the server stops itself when the phone gets low/hot/idle.

Both live on the **Home → Security & Safety** card. Settings are persisted in the Android Keystore via `flutter_secure_storage` and survive app restarts.

---

## 1. API key

### What it does

When **Require API key** is on, Buildify passes `--api-key <key>` to `llama-server`. After that, every request must include:

```
Authorization: Bearer <your-key>
```

Requests without (or with a wrong) key get rejected by the server with `401`.

### Generating / rotating

- The first launch generates a random 32‑char key automatically (`bk_…`).
- Tap **Regenerate key** any time to rotate. You must **stop and start the server** for the new key to apply.
- Tap **Show** to reveal, **Copy** to put it on the clipboard, then paste it into Postman / your laptop client.

### Calling from Postman / curl

```bash
curl http://192.168.1.5:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer bk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" \
  -d '{"messages":[{"role":"user","content":"hi"}]}'
```

In Postman: **Authorization** tab → **Type: Bearer Token** → paste the key.

### In‑app self‑test

The **Self test** tab automatically attaches the `Authorization` header when API key requirement is on, so it keeps working.

### Why this matters

Anyone on the same Wi‑Fi can reach `http://<phone-ip>:8080` if they know it. Without a key, that means free inference on *your* battery from the next room. The key turns Buildify from "open relay" into "private endpoint".

---

## 2. Auto‑stop rules

Three independent guards. Each fires once and shuts the server down cleanly.

| Rule | Default | What it watches | Triggers when |
|------|---------|-----------------|---------------|
| **Idle timeout** | Off | Last request timestamp (parsed from `llama-server` log) | No request received within `N` minutes |
| **Stop below battery** | Off | `BatteryManager.EXTRA_LEVEL`, charger state | Battery ≤ `N%` and not charging |
| **Stop on thermal** | On | `PowerManager.OnThermalStatusChangedListener` (API 29+) | Status ≥ `THERMAL_STATUS_SEVERE` |

When an auto‑stop fires:

1. Native side kills the `llama-server` process.
2. The notification updates to `Auto-stop: <reason>`.
3. Flutter detects the status flip on the next poll and surfaces the reason in the **Logs** panel as a warning.

You can change limits live; **idle/battery/thermal are read at server start**, so adjust before you press **Start AI Server** for them to apply this run. (We restart‑gate to keep the loop simple.)

### Recommended starting points

- **Idle:** `15 min` — reasonable for "server is on while I'm working at the laptop".
- **Battery:** `20%` — keeps a usable phone reserve.
- **Thermal:** **on** — the phone otherwise gets uncomfortably hot under sustained inference.

---

## Privacy notes

- The API key is stored encrypted (Android Keystore, `EncryptedSharedPreferences`).
- We never log the raw key. The Kotlin side only keeps a short hash for status reporting.
- Stop reasons (`battery 18%`, `idle 16 min`, `thermal status 3`) are written to in‑app logs only — they never leave the device.

---

## Limitations / future work

- API key matches `llama-server`'s built‑in `--api-key` (single shared secret). For per‑client keys we'd need a tiny proxy in Kotlin. Not in scope yet.
- Idle detection currently parses the `llama-server` stdout. If a future version of the binary changes its log format, idle won't fire. Tracked in `docs/roadmap.md`.
- Thermal listener is API 29+ (Android 10). On older devices the toggle is a no‑op.
