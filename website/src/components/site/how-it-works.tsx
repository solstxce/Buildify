"use client";

import { forwardRef, useRef } from "react";
import { Smartphone, Download, Server, Laptop } from "lucide-react";

import { cn } from "@/lib/utils";
import { AnimatedBeam } from "@/components/ui/animated-beam";

const Circle = forwardRef<
  HTMLDivElement,
  {
    className?: string;
    children?: React.ReactNode;
    label?: string;
    sublabel?: string;
  }
>(({ className, children, label, sublabel }, ref) => (
  <div className="flex flex-col items-center gap-2">
    <div
      ref={ref}
      className={cn(
        "z-10 flex h-14 w-14 items-center justify-center rounded-full border border-white/10 bg-card shadow-[0_0_0_1px_oklch(0.82_0.16_195/0.15),0_0_30px_oklch(0.82_0.16_195/0.15)]",
        className,
      )}
    >
      {children}
    </div>
    <div className="text-center">
      <div className="text-xs font-semibold text-foreground">{label}</div>
      {sublabel ? (
        <div className="text-[10px] uppercase tracking-wider text-muted-foreground">
          {sublabel}
        </div>
      ) : null}
    </div>
  </div>
));
Circle.displayName = "Circle";

export function HowItWorks() {
  const containerRef = useRef<HTMLDivElement>(null);
  const phoneRef = useRef<HTMLDivElement>(null);
  const modelRef = useRef<HTMLDivElement>(null);
  const serverRef = useRef<HTMLDivElement>(null);
  const laptopRef = useRef<HTMLDivElement>(null);

  return (
    <section
      id="how-it-works"
      className="relative mx-auto max-w-7xl px-4 py-24 sm:px-6 lg:px-8"
    >
      <div className="mx-auto max-w-2xl text-center">
        <span className="inline-flex items-center rounded-full border border-white/10 bg-white/[0.03] px-3 py-1 text-xs font-medium uppercase tracking-wider text-muted-foreground">
          How it works
        </span>
        <h2 className="mt-4 text-balance text-3xl font-bold tracking-tight sm:text-4xl">
          From install to first response in{" "}
          <span className="text-brand-gradient">under 5 minutes.</span>
        </h2>
        <p className="mt-4 text-balance text-muted-foreground">
          No Docker, no Python, no cloud account. Install the app, download a
          model, hit start. Other devices on your Wi-Fi can now POST to your
          phone.
        </p>
      </div>

      <div
        ref={containerRef}
        className="relative mx-auto mt-16 flex h-[320px] w-full max-w-3xl items-center justify-between rounded-2xl border border-white/10 bg-card/40 p-10 backdrop-blur-sm sm:h-[260px]"
      >
        <Circle ref={phoneRef} label="Buildify" sublabel="Android app">
          <Smartphone className="h-6 w-6 text-foreground" />
        </Circle>

        <Circle ref={modelRef} label="GGUF" sublabel="downloaded">
          <Download className="h-6 w-6 text-[oklch(0.85_0.18_145)]" />
        </Circle>

        <Circle ref={serverRef} label="llama-server" sublabel=":8080">
          <Server className="h-6 w-6 text-[oklch(0.82_0.16_195)]" />
        </Circle>

        <Circle ref={laptopRef} label="Your laptop" sublabel="curl, postman, …">
          <Laptop className="h-6 w-6 text-[oklch(0.7_0.2_290)]" />
        </Circle>

        <AnimatedBeam
          containerRef={containerRef}
          fromRef={phoneRef}
          toRef={modelRef}
          gradientStartColor="oklch(0.82 0.16 195)"
          gradientStopColor="oklch(0.85 0.18 145)"
        />
        <AnimatedBeam
          containerRef={containerRef}
          fromRef={modelRef}
          toRef={serverRef}
          gradientStartColor="oklch(0.85 0.18 145)"
          gradientStopColor="oklch(0.82 0.16 195)"
          delay={0.4}
        />
        <AnimatedBeam
          containerRef={containerRef}
          fromRef={serverRef}
          toRef={laptopRef}
          gradientStartColor="oklch(0.82 0.16 195)"
          gradientStopColor="oklch(0.7 0.2 290)"
          delay={0.8}
        />
      </div>

      <ol className="mx-auto mt-10 grid max-w-4xl gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {steps.map((step, i) => (
          <li
            key={step.title}
            className="relative rounded-xl border border-white/10 bg-card/40 p-5 backdrop-blur-sm"
          >
            <span className="inline-flex h-7 w-7 items-center justify-center rounded-full bg-white/[0.06] font-mono text-xs text-muted-foreground">
              {String(i + 1).padStart(2, "0")}
            </span>
            <h3 className="mt-3 text-sm font-semibold text-foreground">
              {step.title}
            </h3>
            <p className="mt-1 text-sm text-muted-foreground">{step.body}</p>
          </li>
        ))}
      </ol>
    </section>
  );
}

const steps = [
  {
    title: "Install the app",
    body: "Sideload the APK. Phone stays yours — no account needed.",
  },
  {
    title: "Download a model",
    body: "Pick TinyLlama, Qwen2, or Phi-3. Streamed straight to app storage.",
  },
  {
    title: "Start AI Server",
    body: "Foreground service binds llama-server to your Wi-Fi IP at :8080.",
  },
  {
    title: "Call from anywhere",
    body: "OpenAI-style endpoints. Postman, curl, LangChain, your code.",
  },
];
