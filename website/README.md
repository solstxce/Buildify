# Buildify · marketing site

Promotional site for **Buildify AI Server** — `https://buildify.me`.

Built with Next.js 16 (App Router) + Tailwind 4 + shadcn/ui + Magic UI components.

## Quick start

```bash
cd website
pnpm install
pnpm dev
```

Open http://localhost:3000.

## What's in here

| Route | Purpose |
|-------|---------|
| `/` | Landing: hero, features, how-it-works, live demo, FAQ, waitlist |
| `/docs` | Index of guides — auto-built from the repo's `docs/*.md` |
| `/docs/[slug]` | Markdown renderer for each doc file |
| `/api/waitlist` | `POST { email }` — append to `.data/waitlist.json` (local) |

## Building

```bash
pnpm build
pnpm start
```

The site is a normal Next.js app and works on:

- **Vercel** (recommended) — push to GitHub, import in Vercel, point `buildify.me` at it via CNAME.
- **Cloudflare Pages** — use `@cloudflare/next-on-pages` for App Router compatibility.
- Any Node-hosting that supports Next.js 16.

## Waitlist storage

For the beta, signups are appended to `website/.data/waitlist.json` (gitignored).

When you have a real DB or email tool:

1. Replace the file-write in `src/app/api/waitlist/route.ts` with a Supabase / Resend / Loops call.
2. Add the secrets in your deploy platform.

Recommended next-up integrations:

- **Resend** — confirmation email + transactional sends.
- **Supabase / PlanetScale** — persistent storage if you grow past 100 signups.
- **Loops.so** — onboarding + drip emails if Buildify becomes a product line.

## Customising

- Brand colors live in `src/app/globals.css` (`:root` and `.dark`). They use OKLCH so gradients stay vibrant.
- Components: `src/components/site/*` are page-level, `src/components/ui/*` are shadcn + Magic UI primitives.
- Docs source: `../docs/*.md` (the repo's existing docs are pulled at build time).

## Deploying to Vercel

```bash
vercel link
vercel --prod
```

DNS:

```text
A      buildify.me            76.76.21.21
CNAME  www.buildify.me        cname.vercel-dns.com
```

(Use Vercel's UI prompts — these are illustrative.)
