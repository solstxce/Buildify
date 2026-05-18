"use client";

import { useRef, useState } from "react";
import { Loader2, Mail, PartyPopper } from "lucide-react";
import { toast } from "sonner";

import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { BorderBeam } from "@/components/ui/border-beam";
import { Confetti, type ConfettiRef } from "@/components/ui/confetti";

const FUN_FACTS = [
  "Your phone has more RAM than a 1995 datacenter.",
  "TinyLlama at Q4 weighs ~669 MB. Less than 10 photos.",
  "OpenAI charges per token. Your phone charges in watts.",
  "The model is open-source. So is the app. So is the engine.",
];

type Status = "idle" | "loading" | "success" | "error";

export function Waitlist() {
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<Status>("idle");
  const [factIndex, setFactIndex] = useState(0);
  const confettiRef = useRef<ConfettiRef>(null);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (status === "loading") return;
    const trimmed = email.trim();
    if (!/^\S+@\S+\.\S+$/.test(trimmed)) {
      toast.error("That doesn’t look like an email.");
      return;
    }
    setStatus("loading");
    try {
      const res = await fetch("/api/waitlist", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: trimmed }),
      });
      if (!res.ok) {
        const data = (await res.json().catch(() => ({}))) as {
          error?: string;
        };
        throw new Error(data.error ?? "Something went wrong");
      }
      setStatus("success");
      toast.success("You’re on the list. Welcome to Buildify.");
      confettiRef.current?.fire({
        particleCount: 140,
        spread: 90,
        startVelocity: 45,
        origin: { y: 0.6 },
      });
      setFactIndex((i) => (i + 1) % FUN_FACTS.length);
    } catch (err) {
      setStatus("error");
      toast.error(err instanceof Error ? err.message : "Failed to sign up");
    }
  }

  return (
    <section
      id="waitlist"
      className="relative mx-auto max-w-5xl px-4 py-24 sm:px-6 lg:px-8"
    >
      <div className="relative overflow-hidden rounded-3xl border border-white/10 bg-gradient-to-br from-card/80 to-card/20 p-10 backdrop-blur-xl sm:p-14">
        <div
          aria-hidden
          className="absolute -top-32 left-1/2 -z-10 h-64 w-[40rem] -translate-x-1/2 rounded-full bg-[oklch(0.82_0.16_195)] opacity-20 blur-3xl"
        />
        <div
          aria-hidden
          className="absolute -bottom-32 right-1/4 -z-10 h-64 w-[28rem] rounded-full bg-[oklch(0.7_0.2_290)] opacity-15 blur-3xl"
        />

        <Confetti
          ref={confettiRef}
          manualstart
          className="pointer-events-none absolute inset-0 z-20 h-full w-full"
        />

        <div className="relative grid items-center gap-10 lg:grid-cols-2">
          <div>
            <span className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/[0.03] px-3 py-1 text-xs font-medium uppercase tracking-wider text-muted-foreground">
              <PartyPopper className="h-3 w-3" />
              v0.1 — invite-only beta
            </span>
            <h2 className="mt-4 text-balance text-3xl font-bold tracking-tight sm:text-4xl">
              Get the first APK.
              <br />
              <span className="text-brand-gradient">
                Be the first server in your house.
              </span>
            </h2>
            <p className="mt-4 max-w-md text-balance text-muted-foreground">
              Drop your email — we’ll send you the signed APK the moment v0.1
              ships, plus a short note on how to point your laptop at it.
            </p>

            <form
              onSubmit={onSubmit}
              className="mt-6 flex flex-col gap-2 sm:flex-row"
            >
              <div className="relative flex-1">
                <Mail className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                <Input
                  type="email"
                  autoComplete="email"
                  inputMode="email"
                  required
                  placeholder="you@yourdomain.dev"
                  value={email}
                  disabled={status === "loading" || status === "success"}
                  onChange={(e) => setEmail(e.target.value)}
                  className={cn(
                    "h-12 pl-9 text-base",
                    status === "success" &&
                      "border-emerald-500/30 bg-emerald-500/5"
                  )}
                />
              </div>
              <Button
                type="submit"
                size="lg"
                disabled={status === "loading" || status === "success"}
                className="h-12 bg-foreground text-background hover:bg-foreground/90 disabled:opacity-100"
              >
                {status === "loading" ? (
                  <>
                    <Loader2 className="h-4 w-4 animate-spin" /> Saving…
                  </>
                ) : status === "success" ? (
                  <>You’re in ✓</>
                ) : (
                  <>Get early access</>
                )}
              </Button>
            </form>
            <p className="mt-3 text-xs text-muted-foreground">
              No spam. We email twice: once when v0.1 ships, once when v1.0
              ships. Then we go away.
            </p>
          </div>

          <FunFactCard
            highlight={status === "success"}
            text={FUN_FACTS[factIndex]}
          />
        </div>

        <BorderBeam
          size={220}
          duration={14}
          colorFrom="oklch(0.82 0.16 195)"
          colorTo="oklch(0.7 0.2 290)"
        />
      </div>
    </section>
  );
}

function FunFactCard({
  text,
  highlight,
}: {
  text: string;
  highlight: boolean;
}) {
  return (
    <div
      className={cn(
        "relative rounded-2xl border border-white/10 bg-[oklch(0.05_0.01_260)]/80 p-6 font-mono text-sm transition-all",
        highlight && "ring-2 ring-[oklch(0.82_0.16_195)]/40"
      )}
    >
      <div className="mb-3 flex items-center gap-2 text-[10px] uppercase tracking-wider text-muted-foreground">
        <span className="inline-flex h-1.5 w-1.5 animate-pulse rounded-full bg-emerald-400" />
        Did you know
      </div>
      <p className="text-foreground/95">{text}</p>
      <div className="mt-6 grid grid-cols-2 gap-2 text-[10px] text-muted-foreground">
        <Pill label="GGUF" />
        <Pill label="OpenAI-compat" />
        <Pill label="0.0.0.0:8080" />
        <Pill label="MIT" />
      </div>
    </div>
  );
}

function Pill({ label }: { label: string }) {
  return (
    <span className="inline-flex items-center justify-center rounded-md border border-white/10 bg-white/[0.03] px-2 py-1 uppercase tracking-wider">
      {label}
    </span>
  );
}
