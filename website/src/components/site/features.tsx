"use client";

import {
  Cpu,
  Globe,
  KeyRound,
  Network,
  Smartphone,
  Wallet,
} from "lucide-react";

import { BentoCard, BentoGrid } from "@/components/ui/bento-grid";
import { AnimatedList } from "@/components/ui/animated-list";
import { Marquee } from "@/components/ui/marquee";
import { AnimatedGridPattern } from "@/components/ui/animated-grid-pattern";
import { cn } from "@/lib/utils";

const features = [
  {
    Icon: Smartphone,
    name: "Runs on a phone",
    description:
      "An Android foreground service hosts llama.cpp natively. No laptop, no cable, no Termux hack.",
    href: "/docs/architecture",
    cta: "How it works",
    background: <PhoneBackground />,
    className:
      "col-span-3 lg:col-span-2 lg:row-span-2 lg:[grid-row:span_2_/_span_2]",
  },
  {
    Icon: Globe,
    name: "OpenAI-compatible API",
    description:
      "Talk to your phone with /v1/chat/completions. Postman, curl, LangChain, Continue.dev — all work.",
    href: "/docs/api-and-testing",
    cta: "Read API docs",
    background: <ApiBackground />,
    className: "col-span-3 lg:col-span-1",
  },
  {
    Icon: KeyRound,
    name: "API key + auto-stop",
    description:
      "Bearer-token auth. Battery, thermal, and idle guards stop the server before your phone melts.",
    href: "/docs/security-and-safety",
    cta: "Security guide",
    background: <SecurityBackground />,
    className: "col-span-3 lg:col-span-1",
  },
  {
    Icon: Cpu,
    name: "Curated open models",
    description:
      "Pick from TinyLlama, Qwen2 1.5B, Phi-3 Mini — quantized GGUF, streamed straight to the device.",
    href: "/docs/models-and-downloads",
    cta: "Browse catalog",
    background: <ModelMarqueeBackground />,
    className: "col-span-3 lg:col-span-2",
  },
  {
    Icon: Network,
    name: "LAN, then anywhere",
    description:
      "Default: same Wi-Fi network. Roadmap: Tailscale for private, Cloudflare Tunnel for public — opt-in.",
    href: "/docs/roadmap",
    cta: "Roadmap",
    background: <NetworkBackground />,
    className: "col-span-3 lg:col-span-2",
  },
  {
    Icon: Wallet,
    name: "$0 cloud bill",
    description:
      "Your hardware, your tokens. No subscriptions, no rate limits, no surprise invoices.",
    href: "/docs/product-vision",
    cta: "Product vision",
    background: <WalletBackground />,
    className: "col-span-3 lg:col-span-1",
  },
];

export function Features() {
  return (
    <section
      id="features"
      className="relative mx-auto max-w-7xl px-4 py-24 sm:px-6 lg:px-8"
    >
      <div className="mx-auto max-w-2xl text-center">
        <span className="inline-flex items-center rounded-full border border-white/10 bg-white/[0.03] px-3 py-1 text-xs font-medium uppercase tracking-wider text-muted-foreground">
          Features
        </span>
        <h2 className="mt-4 text-balance text-3xl font-bold tracking-tight sm:text-4xl">
          Everything you need to run AI{" "}
          <span className="text-brand-gradient">from your pocket.</span>
        </h2>
        <p className="mt-4 text-balance text-muted-foreground">
          Buildify is a single Android app, an OpenAI-compatible server, and a
          set of safety guards — so a real LLM on a real phone is no longer a
          hack.
        </p>
      </div>

      <BentoGrid className="mt-12 lg:auto-rows-[18rem]">
        {features.map((feature) => (
          <BentoCard key={feature.name} {...feature} />
        ))}
      </BentoGrid>
    </section>
  );
}

function PhoneBackground() {
  return (
    <div
      className={cn(
        "absolute inset-0 [mask-image:linear-gradient(to_top,transparent_30%,#000_100%)]",
        "[mask-image:linear-gradient(to_top,transparent_40%,#000_100%)]"
      )}
    >
      <AnimatedGridPattern
        numSquares={36}
        maxOpacity={0.4}
        duration={3}
        repeatDelay={1}
        className={cn(
          "[mask-image:radial-gradient(500px_circle_at_center,white,transparent)]",
          "inset-x-0 inset-y-[-30%] h-[200%] skew-y-12"
        )}
      />
      <div className="absolute inset-x-0 bottom-0 flex items-end justify-center">
        <div className="relative h-[15rem] w-[7.5rem] -mb-12 rounded-[1.4rem] border border-white/10 bg-gradient-to-b from-card to-background p-1 shadow-2xl">
          <div className="absolute inset-x-0 top-1.5 mx-auto h-1.5 w-12 rounded-full bg-black" />
          <div className="flex h-full w-full flex-col justify-end overflow-hidden rounded-[1.1rem] bg-background p-2 text-[7px]">
            <div className="mb-1 rounded-md bg-emerald-500/10 px-1.5 py-1 text-emerald-400">
              Server Running
            </div>
            <div className="mb-1 rounded-md bg-white/[0.03] px-1.5 py-1 text-muted-foreground">
              192.168.1.5:8080
            </div>
            <div className="rounded-md bg-[oklch(0.82_0.16_195)]/15 px-1.5 py-1 text-[oklch(0.82_0.16_195)]">
              POST /v1/chat 200
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function ApiBackground() {
  return (
    <div className="absolute inset-0 flex items-start justify-center p-4 opacity-80 [mask-image:linear-gradient(to_bottom,#000_30%,transparent_100%)]">
      <pre className="overflow-hidden font-mono text-[10px] leading-snug text-muted-foreground">
        {`POST /v1/chat/completions
Host: 192.168.1.5:8080
Authorization: Bearer bk_•••

{
  "messages":[{
    "role":"user",
    "content":"hi"
  }],
  "max_tokens": 64
}

→ 200 OK
choices[0].message.content
  → "Hello!"`}
      </pre>
    </div>
  );
}

function SecurityBackground() {
  const items = [
    { label: "Bearer auth", color: "oklch(0.82 0.16 195)" },
    { label: "Idle 15 min → stop", color: "oklch(0.85 0.18 145)" },
    { label: "Battery 20% → stop", color: "oklch(0.78 0.18 60)" },
    { label: "Thermal severe → stop", color: "oklch(0.65 0.22 25)" },
  ];
  return (
    <div className="absolute inset-0 flex items-start justify-center p-4 [mask-image:linear-gradient(to_bottom,#000_30%,transparent_100%)]">
      <AnimatedList delay={1600} className="w-full">
        {items.map((i, idx) => (
          <div
            key={idx}
            className="flex items-center justify-between rounded-md border border-white/5 bg-white/[0.02] px-3 py-2 text-xs"
          >
            <span className="text-muted-foreground">{i.label}</span>
            <span
              className="inline-flex h-2 w-2 rounded-full"
              style={{ backgroundColor: i.color }}
            />
          </div>
        ))}
      </AnimatedList>
    </div>
  );
}

function ModelMarqueeBackground() {
  const models = [
    "TinyLlama 1.1B",
    "Qwen2 1.5B",
    "Phi-3 Mini 4K",
    "Llama 3.2 1B",
    "Gemma 2 2B",
    "SmolLM 1.7B",
    "Q4_K_M",
    "GGUF",
  ];
  return (
    <Marquee
      pauseOnHover
      className="absolute inset-x-0 top-2 [--duration:30s] [mask-image:linear-gradient(to_bottom,#000_20%,transparent_100%)]"
    >
      {models.map((m, i) => (
        <div
          key={i}
          className="mx-2 inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/[0.03] px-3 py-1 text-xs text-muted-foreground"
        >
          <span className="inline-flex h-1.5 w-1.5 rounded-full bg-[oklch(0.82_0.16_195)]" />
          {m}
        </div>
      ))}
    </Marquee>
  );
}

function NetworkBackground() {
  return (
    <div className="absolute inset-0 flex items-center justify-center [mask-image:linear-gradient(to_bottom,#000_20%,transparent_100%)]">
      <div className="flex items-center gap-4 opacity-70">
        <NodeBubble label="laptop" />
        <Dots />
        <NodeBubble label="phone" highlight />
        <Dots />
        <NodeBubble label="📡 anywhere" muted />
      </div>
    </div>
  );
}

function NodeBubble({
  label,
  highlight,
  muted,
}: {
  label: string;
  highlight?: boolean;
  muted?: boolean;
}) {
  return (
    <span
      className={cn(
        "inline-flex h-10 items-center rounded-full border px-3 text-xs font-medium",
        highlight
          ? "border-[oklch(0.82_0.16_195)]/50 bg-[oklch(0.82_0.16_195)]/10 text-foreground"
          : muted
            ? "border-dashed border-white/15 bg-white/[0.02] text-muted-foreground/70"
            : "border-white/10 bg-white/[0.03] text-muted-foreground"
      )}
    >
      {label}
    </span>
  );
}

function Dots() {
  return (
    <div className="flex items-center gap-1">
      {Array.from({ length: 3 }).map((_, i) => (
        <span
          key={i}
          className="h-1.5 w-1.5 rounded-full bg-[oklch(0.82_0.16_195)]/40 animate-pulse-soft"
          style={{ animationDelay: `${i * 0.2}s` }}
        />
      ))}
    </div>
  );
}

function WalletBackground() {
  return (
    <div className="absolute inset-0 flex items-center justify-center [mask-image:linear-gradient(to_bottom,#000_30%,transparent_100%)]">
      <div className="space-y-2">
        <div className="flex items-center gap-2 text-xs">
          <span className="line-through text-muted-foreground/60">
            $0.0020 / 1k tokens
          </span>
          <span className="text-muted-foreground/40">→</span>
          <span className="font-mono text-2xl font-bold text-[oklch(0.85_0.18_145)]">
            $0.00
          </span>
        </div>
        <div className="text-xs text-muted-foreground/80">
          Your hardware. Your watts. No middleman.
        </div>
      </div>
    </div>
  );
}
