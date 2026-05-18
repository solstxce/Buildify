# Buildify · marketing site

Promotional site for **Buildify AI Server** — `https://buildify.me`.

Built with Next.js 16 (App Router) + Tailwind 4 + shadcn/ui + Magic UI components.

## Quick start

We use **pnpm** (not npm) for this folder — see [why pnpm?](../docs/marketing-site-deployment.md#1-why-pnpm-instead-of-npm) in the deployment guide.

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

## Deployment & tooling (read this before going live)

Full explanations (pnpm vs npm, Vercel vs GitHub Pages, Cloudflare DNS + Vercel):

**[docs/marketing-site-deployment.md](../docs/marketing-site-deployment.md)**

Summary:

| Question | Short answer |
|----------|----------------|
| Why **pnpm**? | Faster, less disk, stricter deps; lockfile is `pnpm-lock.yaml`. |
| Why **Vercel**, not GitHub Pages? | Next.js + `/api/waitlist` needs a server; Pages is static-only. |
| Why **Cloudflare DNS** + Vercel? | Cloudflare keeps your domain/DNS (and future phone tunnel); Vercel runs the website. |

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

## Deploying to Vercel (quick)

```bash
cd website
pnpm dlx vercel link
pnpm dlx vercel --prod
```

In **Cloudflare DNS** (values from Vercel → Domains, not guesswork):

```text
A      @    →  (IP shown by Vercel, often 76.76.21.21)
CNAME  www  →  cname.vercel-dns.com
```

See [marketing-site-deployment.md](../docs/marketing-site-deployment.md#3-cloudflare-dns--vercel--how-it-fits-together) for the full picture.
