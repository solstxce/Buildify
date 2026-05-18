"use client";

import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion";

const faqs = [
  {
    q: "Does this work on iPhone?",
    a: "Not yet. Buildify is Android-only because iOS doesn’t allow running native binaries like llama-server from user apps. Android lets us load native libs from jniLibs. iOS support would require an in-process JNI/Swift port — on the roadmap, not in scope for v0.1.",
  },
  {
    q: "Which phones can handle this?",
    a: "Any modern arm64-v8a Android phone. TinyLlama 1.1B and Qwen2 1.5B run on phones with 4 GB RAM. Phi-3 Mini 3.8B is comfortable on 6 GB+. Expect 10–25 tokens/sec on a Snapdragon 8 Gen 1 or newer.",
  },
  {
    q: "Is it really free?",
    a: "Yes. The app is MIT, the engine (llama.cpp) is MIT, the models are open weights. The only thing you pay is electricity. There is no cloud account.",
  },
  {
    q: "Can other people on the internet hit my phone?",
    a: "By default, no — Buildify binds to your local Wi-Fi network. Public access via Cloudflare Tunnel or Tailscale is on the roadmap, behind an explicit opt-in. We also ship API key auth and auto-stop so the LAN endpoint isn’t wide open.",
  },
  {
    q: "Will it kill my battery?",
    a: "Sustained inference is hot work. Buildify has three auto-stop guards out of the box: idle timeout, low-battery cutoff, and thermal severity. You can tune each from the Home screen.",
  },
  {
    q: "How is this different from running llama.cpp in Termux?",
    a: "Termux is amazing for hackers; it is not for normal people. Buildify is a single APK — install, tap, done. It also handles the Android-specific bits (foreground service, notification, native lib loading, autostop) that Termux scripts can’t cleanly do.",
  },
  {
    q: "Is the code open?",
    a: "Yes. Buildify lives on GitHub and is MIT-licensed. PRs welcome — read docs/ before opening.",
  },
];

export function Faq() {
  return (
    <section
      id="faq"
      className="relative mx-auto max-w-3xl px-4 py-24 sm:px-6 lg:px-8"
    >
      <div className="mx-auto max-w-2xl text-center">
        <span className="inline-flex items-center rounded-full border border-white/10 bg-white/[0.03] px-3 py-1 text-xs font-medium uppercase tracking-wider text-muted-foreground">
          FAQ
        </span>
        <h2 className="mt-4 text-balance text-3xl font-bold tracking-tight sm:text-4xl">
          Frequently asked questions
        </h2>
      </div>

      <Accordion className="mt-12 w-full">
        {faqs.map((faq, i) => (
          <AccordionItem
            key={i}
            value={`item-${i}`}
            className="border-white/5"
          >
            <AccordionTrigger className="text-left text-base font-medium text-foreground hover:no-underline">
              {faq.q}
            </AccordionTrigger>
            <AccordionContent className="text-muted-foreground">
              {faq.a}
            </AccordionContent>
          </AccordionItem>
        ))}
      </Accordion>
    </section>
  );
}
