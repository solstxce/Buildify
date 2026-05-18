import Link from "next/link";
import { ArrowRight, BookOpen } from "lucide-react";
import type { Metadata } from "next";

import { listDocs, docHref } from "@/lib/docs";

export const metadata: Metadata = {
  title: "Documentation",
  description:
    "Architecture, models, API, security, troubleshooting — everything you need to ship Buildify.",
};

export default async function DocsIndexPage() {
  const docs = await listDocs();

  return (
    <div className="mx-auto max-w-5xl px-4 py-16 sm:px-6 lg:px-8">
      <div className="mb-12">
        <span className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/[0.03] px-3 py-1 text-xs font-medium uppercase tracking-wider text-muted-foreground">
          <BookOpen className="h-3 w-3" />
          Docs
        </span>
        <h1 className="mt-4 text-4xl font-bold tracking-tight">
          Buildify documentation
        </h1>
        <p className="mt-3 max-w-2xl text-muted-foreground">
          Everything Buildify knows about itself. Read the architecture before
          you read the code, then jump to the specific guide you need.
        </p>
      </div>

      <div className="grid gap-3 sm:grid-cols-2">
        {docs.map((doc) => (
          <Link
            key={doc.slug}
            href={docHref(doc.slug)}
            className="group relative rounded-xl border border-white/10 bg-card/40 p-5 transition-all hover:border-white/20 hover:bg-card/70"
          >
            <h2 className="flex items-center justify-between text-base font-semibold text-foreground">
              {doc.title}
              <ArrowRight className="h-4 w-4 text-muted-foreground transition-transform group-hover:translate-x-0.5 group-hover:text-foreground" />
            </h2>
            {doc.description ? (
              <p className="mt-1 text-sm text-muted-foreground">
                {doc.description}
              </p>
            ) : null}
            <span className="mt-3 inline-block font-mono text-[10px] uppercase tracking-wider text-muted-foreground/60">
              docs/{doc.slug}.md
            </span>
          </Link>
        ))}
      </div>
    </div>
  );
}
