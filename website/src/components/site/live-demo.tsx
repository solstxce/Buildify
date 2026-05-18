"use client";

import {
  AnimatedSpan,
  Terminal,
  TypingAnimation,
} from "@/components/ui/terminal";
import { BorderBeam } from "@/components/ui/border-beam";

export function LiveDemo() {
  return (
    <section
      id="demo"
      className="relative mx-auto max-w-7xl px-4 py-24 sm:px-6 lg:px-8"
    >
      <div className="mx-auto max-w-2xl text-center">
        <span className="inline-flex items-center rounded-full border border-white/10 bg-white/[0.03] px-3 py-1 text-xs font-medium uppercase tracking-wider text-muted-foreground">
          Live API
        </span>
        <h2 className="mt-4 text-balance text-3xl font-bold tracking-tight sm:text-4xl">
          One curl from your laptop.{" "}
          <span className="text-brand-gradient">One answer from your pocket.</span>
        </h2>
        <p className="mt-4 text-balance text-muted-foreground">
          This is a real Buildify response, formatted exactly the way you&apos;d
          see it in Postman. No mock, no cloud.
        </p>
      </div>

      <div className="mx-auto mt-12 grid max-w-6xl gap-6 lg:grid-cols-5">
        <div className="lg:col-span-3">
          <div className="relative overflow-hidden rounded-2xl border border-white/10 bg-card/40 backdrop-blur-sm">
            <Terminal className="!bg-transparent !text-foreground !rounded-none !border-0 !p-6 max-h-[28rem] min-h-[24rem] overflow-hidden">
              <TypingAnimation duration={20}>
                {"$ curl http://192.168.1.5:8080/v1/chat/completions \\"}
              </TypingAnimation>
              <TypingAnimation duration={15}>
                {"    -H 'Authorization: Bearer bk_•••' \\"}
              </TypingAnimation>
              <TypingAnimation duration={15}>
                {"    -H 'Content-Type: application/json' \\"}
              </TypingAnimation>
              <TypingAnimation duration={15}>
                {"    -d '{\"messages\":[{\"role\":\"user\",\"content\":\"Hello in one short sentence.\"}]}'"}
              </TypingAnimation>

              <AnimatedSpan
                delay={500}
                className="text-[oklch(0.65_0.02_240)]"
              >
                <span>{"→ HTTP/1.1 200 OK"}</span>
              </AnimatedSpan>

              <AnimatedSpan
                delay={500}
                className="text-[oklch(0.82_0.16_195)]"
              >
                <span>{"{"}</span>
                <span>
                  {"  \"model\": \"tinyllama-1.1b-chat-v1.0-q4_k_m.gguf\","}
                </span>
                <span>{"  \"object\": \"chat.completion\","}</span>
                <span>{"  \"choices\": ["}</span>
                <span>{"    {"}</span>
                <span>{"      \"index\": 0,"}</span>
                <span>{"      \"message\": {"}</span>
                <span>{"        \"role\": \"assistant\","}</span>
                <span>
                  {
                    "        \"content\": \"Hello! How can I help you today?\""
                  }
                </span>
                <span>{"      },"}</span>
                <span>{"      \"finish_reason\": \"stop\""}</span>
                <span>{"    }"}</span>
                <span>{"  ],"}</span>
                <span>{"  \"usage\": {"}</span>
                <span>{"    \"prompt_tokens\": 23,"}</span>
                <span>{"    \"completion_tokens\": 12,"}</span>
                <span>{"    \"total_tokens\": 35"}</span>
                <span>{"  },"}</span>
                <span>{"  \"timings\": {"}</span>
                <span>{"    \"predicted_per_second\": 15.27"}</span>
                <span>{"  }"}</span>
                <span>{"}"}</span>
              </AnimatedSpan>

              <AnimatedSpan
                delay={400}
                className="text-[oklch(0.85_0.18_145)]"
              >
                <span>✓ 318 ms prompt · 4191 ms decode · 15 tok/s</span>
              </AnimatedSpan>
            </Terminal>
            <BorderBeam
              size={140}
              duration={10}
              colorFrom="oklch(0.82 0.16 195)"
              colorTo="oklch(0.85 0.18 145)"
            />
          </div>
        </div>

        <div className="space-y-4 lg:col-span-2">
          <DemoRow
            kpi="LAN"
            label="No public IP. No SSL needed."
            sub="Bind to 0.0.0.0; reach by Wi-Fi IP."
          />
          <DemoRow
            kpi="OpenAI"
            label="Same JSON your tools already speak."
            sub="/v1/chat/completions + Authorization header."
          />
          <DemoRow
            kpi="Free"
            label="Tokens run on your battery, not Vercel's."
            sub="No cloud billing, no rate limits, no retries."
          />
          <DemoRow
            kpi="Open"
            label="MIT-licensed. Hack it on GitHub."
            sub="One Flutter file, one Kotlin service, one binary."
          />
        </div>
      </div>
    </section>
  );
}

function DemoRow({
  kpi,
  label,
  sub,
}: {
  kpi: string;
  label: string;
  sub: string;
}) {
  return (
    <div className="rounded-xl border border-white/10 bg-card/40 p-5 backdrop-blur-sm transition-colors hover:bg-card/60">
      <div className="flex items-center gap-3">
        <span className="rounded-md border border-white/10 bg-white/[0.04] px-2 py-0.5 font-mono text-[10px] uppercase tracking-wider text-[oklch(0.82_0.16_195)]">
          {kpi}
        </span>
        <p className="text-sm font-medium text-foreground">{label}</p>
      </div>
      <p className="mt-1 pl-1 text-xs text-muted-foreground">{sub}</p>
    </div>
  );
}
