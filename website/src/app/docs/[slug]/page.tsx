import Link from "next/link";
import { notFound } from "next/navigation";
import { ArrowLeft, ArrowRight } from "lucide-react";
import type { Metadata } from "next";

import { getDoc, listDocs, docHref } from "@/lib/docs";
import { renderMarkdown } from "@/lib/markdown";
import { Markdown } from "@/components/docs/markdown";

export async function generateStaticParams() {
  const docs = await listDocs();
  return docs.map((d) => ({ slug: d.slug }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const doc = await getDoc(slug);
  if (!doc) return { title: "Not found" };
  return {
    title: doc.title,
    description: doc.description ?? undefined,
  };
}

export default async function DocPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const [doc, all] = await Promise.all([getDoc(slug), listDocs()]);
  if (!doc) notFound();

  const html = await renderMarkdown(doc.content);
  const idx = all.findIndex((d) => d.slug === doc.slug);
  const prev = idx > 0 ? all[idx - 1] : null;
  const next = idx >= 0 && idx < all.length - 1 ? all[idx + 1] : null;

  return (
    <div className="mx-auto max-w-7xl px-4 py-12 sm:px-6 lg:px-8">
      <div className="grid gap-10 lg:grid-cols-[14rem_minmax(0,1fr)]">
        <aside className="hidden lg:block">
          <div className="sticky top-24">
            <Link
              href="/docs"
              className="mb-3 inline-flex items-center gap-1.5 text-xs uppercase tracking-wider text-muted-foreground hover:text-foreground"
            >
              <ArrowLeft className="h-3 w-3" />
              All docs
            </Link>
            <nav className="space-y-0.5">
              {all.map((d) => (
                <Link
                  key={d.slug}
                  href={docHref(d.slug)}
                  className={
                    d.slug === doc.slug
                      ? "block rounded-md border border-white/10 bg-white/[0.04] px-3 py-1.5 text-sm font-medium text-foreground"
                      : "block rounded-md px-3 py-1.5 text-sm text-muted-foreground hover:bg-white/5 hover:text-foreground"
                  }
                >
                  {d.title}
                </Link>
              ))}
            </nav>
          </div>
        </aside>

        <div>
          <div className="mb-8">
            <span className="inline-flex items-center rounded-full border border-white/10 bg-white/[0.03] px-3 py-1 text-xs font-medium uppercase tracking-wider text-muted-foreground">
              Docs · {doc.slug}
            </span>
            <h1 className="mt-4 text-3xl font-bold tracking-tight sm:text-4xl">
              {doc.title}
            </h1>
            {doc.description ? (
              <p className="mt-2 text-muted-foreground">{doc.description}</p>
            ) : null}
          </div>

          <Markdown html={html} />

          <div className="mt-16 grid gap-3 border-t border-white/5 pt-6 sm:grid-cols-2">
            {prev ? (
              <Link
                href={docHref(prev.slug)}
                className="group rounded-xl border border-white/10 bg-card/40 p-4 transition-colors hover:bg-card/70"
              >
                <span className="flex items-center gap-1 text-xs uppercase tracking-wider text-muted-foreground">
                  <ArrowLeft className="h-3 w-3" />
                  Previous
                </span>
                <span className="mt-1 block text-sm font-semibold text-foreground">
                  {prev.title}
                </span>
              </Link>
            ) : (
              <span />
            )}
            {next ? (
              <Link
                href={docHref(next.slug)}
                className="group rounded-xl border border-white/10 bg-card/40 p-4 text-right transition-colors hover:bg-card/70"
              >
                <span className="flex items-center justify-end gap-1 text-xs uppercase tracking-wider text-muted-foreground">
                  Next
                  <ArrowRight className="h-3 w-3" />
                </span>
                <span className="mt-1 block text-sm font-semibold text-foreground">
                  {next.title}
                </span>
              </Link>
            ) : null}
          </div>
        </div>
      </div>
    </div>
  );
}
