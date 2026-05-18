# Marketing site — deployment & tooling

Guide for **buildify.me** (the Next.js site in `website/`). Covers why we use **pnpm**, why we deploy on **Vercel** instead of **GitHub Pages**, and how **Cloudflare DNS** points your domain at Vercel while you still use Cloudflare for other things (like tunneling the phone server later).

---

## 1. Why pnpm instead of npm?

Both **npm**, **pnpm**, and **yarn** install JavaScript packages. This project’s marketing site uses **pnpm** on purpose.

### What pnpm does differently

| Topic | npm | pnpm |
|-------|-----|------|
| **Disk space** | Each project gets its own full copy of every dependency under `node_modules/`. | Packages are stored once in a global content-addressable store; projects link to them. Cloning or running many Node projects uses far less disk. |
| **Install speed** | Good; re-downloads or copies a lot. | Often faster on repeat installs because most files are hard-linked from the store. |
| **Strictness** | A dependency can “see” packages it didn’t declare (hoisted to the top of `node_modules`). | Stricter layout: only declared dependencies are available unless you explicitly allow otherwise. Fewer “works on my machine” surprises. |
| **Lockfile** | `package-lock.json` | `pnpm-lock.yaml` — same idea: reproducible installs for everyone and for CI. |

### Why that matters for Buildify

- The site pulls in **Next.js**, **shadcn**, **Magic UI**, and markdown tooling — hundreds of packages. pnpm keeps that manageable on a laptop.
- **Vercel** (and most CI) detect `pnpm-lock.yaml` and run `pnpm install` automatically.
- The repo already has `website/pnpm-lock.yaml`. Using npm locally without migrating would create a second lockfile and confuse contributors.

### Can I use npm anyway?

You can, but we don’t recommend it for this folder:

```bash
cd website
npm install   # creates package-lock.json; may diverge from pnpm-lock.yaml
```

If you only use npm, delete `pnpm-lock.yaml` and commit `package-lock.json` instead — pick **one** package manager per project. For Buildify, that choice is **pnpm**.

### Commands (pnpm ↔ npm)

| Task | pnpm | npm |
|------|------|-----|
| Install deps | `pnpm install` | `npm install` |
| Dev server | `pnpm dev` | `npm run dev` |
| Production build | `pnpm build` | `npm run build` |
| Add a package | `pnpm add <name>` | `npm install <name>` |

---

## 2. Why Vercel instead of GitHub Pages?

**GitHub Pages** is excellent for **static** sites: HTML/CSS/JS files, or a static export from a generator (Jekyll, Astro static, etc.).

**This marketing site is not a static-only site.** It is **Next.js 16** with:

| Feature | Needs |
|---------|--------|
| **App Router** | Server components, file-based routing |
| **`/api/waitlist`** | A **server** that accepts `POST` and writes signups (today: file; later: DB/email) |
| **Docs from `../docs/*.md`** | Build-time + server rendering with syntax highlighting |
| **Future** | More API routes, auth, webhooks — all awkward on pure static hosting |

### GitHub Pages limitations (for this project)

1. **No Node server** — Pages serves files from a CDN. There is nowhere to run `POST /api/waitlist` unless you bolt on a separate backend (another host, serverless function elsewhere, etc.).
2. **Next.js on Pages is painful** — You’d need `output: 'export'` (static export), which **disables** API routes, dynamic server features, and many Next.js patterns. You’d split the app into “static site on Pages” + “API somewhere else.”
3. **No zero-config Next** — Vercel created Next.js; deploy is “connect repo → build → done.” GitHub Pages needs custom GitHub Actions workflows to build Next and push `out/`, and you still lose server features unless you add more infrastructure.

### Vercel advantages (for Buildify)

- **Native Next.js** — Builds App Router, API routes, and edge/serverless functions as intended.
- **Free tier** — Fine for a promo site + waitlist at early scale.
- **Preview deployments** — Every PR gets a URL; good for open source.
- **Custom domain** — `buildify.me` in a few clicks.
- **Env vars** — Store Resend/Supabase keys when you replace file-based waitlist.

### When GitHub Pages *would* make sense

- A single `index.html` landing page with no forms and no server logic.
- Docs-only site built to static HTML (e.g. MkDocs, Docusaurus static export).

Buildify’s site is intentionally richer than that, so **Vercel (or Cloudflare Pages with Next adapter)** fits; **GitHub Pages alone does not.**

### Alternative: Cloudflare Pages

You already use **Cloudflare** for DNS (and later for tunneling the **phone AI server**). Cloudflare Pages *can* host Next.js with extra setup (`@cloudflare/next-on-pages`). We still recommend **Vercel for the marketing site** because it’s zero-config for Next; keep Cloudflare for **DNS** and **tunnel/API exposure for the Android server** — different jobs, same registrar account.

---

## 3. Cloudflare DNS + Vercel — how it fits together

You bought **buildify.me**. Nameservers can stay at **Cloudflare** (recommended). You do **not** move the whole domain to Vercel — you only tell Cloudflare **where to send web traffic** for the website.

Think of it in layers:

```text
User types buildify.me
        │
        ▼
┌───────────────────┐
│  Cloudflare DNS   │  “What IP/host is buildify.me?”
│  (you control)    │
└─────────┬─────────┘
          │  A / CNAME records point to Vercel
          ▼
┌───────────────────┐
│  Vercel           │  Builds & serves the Next.js site
│  (hosts website)  │  (HTML, JS, /api/waitlist, /docs/…)
└───────────────────┘
```

Later, **tunneling your phone’s LLM server** is a **separate** Cloudflare product (Tunnel / Zero Trust). That exposes `llama-server` on the internet — not the marketing site. Same Cloudflare account, different records and products.

### Records explained

After you add `buildify.me` in the Vercel dashboard, Vercel shows the exact records to create. Typical setup:

| Type | Name | Value | Purpose |
|------|------|--------|---------|
| **A** | `@` (apex) | `76.76.21.21` | Send `buildify.me` (no `www`) to Vercel’s anycast IP. Vercel may give you a different IP — **always use the value Vercel shows you.** |
| **CNAME** | `www` | `cname.vercel-dns.com` | Send `www.buildify.me` to Vercel; they issue TLS and route to your project. |

- **`@`** = apex / root domain → `https://buildify.me`
- **`www`** = subdomain → `https://www.buildify.me` (Vercel can redirect www → apex or the reverse; pick one canonical URL in Vercel settings)

`76.76.21.21` is Vercel’s commonly documented apex IP; **confirm in your Vercel project → Domains** before saving DNS.

### Step-by-step (Cloudflare dashboard)

1. **Vercel:** Import the GitHub repo, set root directory to `website`, build command `pnpm build`, install `pnpm install`.
2. **Vercel → Settings → Domains:** Add `buildify.me` and `www.buildify.me`. Copy the DNS records Vercel displays.
3. **Cloudflare → DNS → Records** for `buildify.me`:
   - Add the **A** record for `@` (proxy status: **DNS only** / grey cloud is often recommended for apex on Vercel until you know you need orange-cloud features; Vercel’s docs describe both — if unsure, start with **DNS only** for the apex A record).
   - Add the **CNAME** for `www` → `cname.vercel-dns.com` (often **DNS only** for simplest SSL handoff with Vercel).
4. Wait for propagation (minutes to a few hours). Vercel will provision HTTPS automatically once DNS is correct.
5. In Vercel, set **primary domain** (e.g. redirect `www` → `buildify.me` or vice versa).

### What stays on Cloudflare vs what runs on Vercel

| Piece | Where it lives |
|-------|----------------|
| Domain registration / DNS | Cloudflare (or registrar → Cloudflare nameservers) |
| Marketing site (Next.js, waitlist API, docs pages) | **Vercel** |
| Android app, `llama-server`, LAN API | **On the phone** (not on Vercel) |
| Future: expose phone server to internet | **Cloudflare Tunnel** (or Tailscale, etc.) — **not** the same as hosting the website |

So: **Cloudflare = traffic director + (later) secure tunnel for the phone.** **Vercel = runs the buildify.me website code.**

### Common confusion

- **“I use Cloudflare for my server — why not host the site there too?”** You can (Cloudflare Pages), but Next.js + API routes is smoother on Vercel today. DNS can still be Cloudflare.
- **“Does the A record point my AI server to Vercel?”** No. The A/CNAME records above only affect the **website**. Your phone’s IP is private on Wi‑Fi unless you set up tunnel/DNS separately for that product.
- **Orange cloud (proxied) vs grey cloud (DNS only):** Proxied traffic goes through Cloudflare’s CDN/WAF; DNS-only passes the hostname straight to Vercel. For a simple marketing site, many teams use **DNS only** on the Vercel records to avoid double-proxy SSL quirks; you can enable proxy later for DDoS/caching if needed.

---

## Quick deploy checklist

- [ ] `cd website && pnpm install && pnpm build` passes locally
- [ ] Repo pushed to GitHub
- [ ] Vercel project: root = `website`, install = `pnpm install`, build = `pnpm build`
- [ ] Domain added in Vercel; DNS records added in Cloudflare (values from Vercel UI)
- [ ] HTTPS shows “Valid” in Vercel Domains
- [ ] Test `POST /api/waitlist` on production (or plan to swap storage before launch)

More detail for developers working only in the `website/` folder: [website/README.md](../website/README.md).
