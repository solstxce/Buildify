import Link from "next/link";
import { Logo } from "./logo";
import { GithubIcon } from "./icons";

const sections = [
  {
    title: "Product",
    links: [
      { label: "Features", href: "/#features" },
      { label: "How it works", href: "/#how-it-works" },
      { label: "Demo", href: "/#demo" },
      { label: "Waitlist", href: "/#waitlist" },
    ],
  },
  {
    title: "Developers",
    links: [
      { label: "Documentation", href: "/docs" },
      { label: "Architecture", href: "/docs/architecture" },
      { label: "API & testing", href: "/docs/api-and-testing" },
      { label: "Security & safety", href: "/docs/security-and-safety" },
    ],
  },
  {
    title: "Open source",
    links: [
      {
        label: "GitHub",
        href: "https://github.com/Sujith8257/Buildify",
        external: true,
      },
      {
        label: "Releases",
        href: "https://github.com/Sujith8257/Buildify/releases",
        external: true,
      },
      {
        label: "Issues",
        href: "https://github.com/Sujith8257/Buildify/issues",
        external: true,
      },
      {
        label: "llama.cpp",
        href: "https://github.com/ggml-org/llama.cpp",
        external: true,
      },
    ],
  },
];

export function SiteFooter() {
  return (
    <footer className="relative mt-24 border-t border-white/5">
      <div className="mx-auto max-w-7xl px-4 py-14 sm:px-6 lg:px-8">
        <div className="grid grid-cols-2 gap-10 md:grid-cols-4">
          <div className="col-span-2 md:col-span-1">
            <Link href="/" className="flex items-center gap-2">
              <Logo className="h-8 w-8" />
              <span className="text-base font-semibold tracking-tight">
                Buildify
              </span>
            </Link>
            <p className="mt-3 max-w-xs text-sm text-muted-foreground">
              Open-source Android app that turns your phone into a local AI
              server.
            </p>
            <div className="mt-4 flex items-center gap-2">
              <a
                href="https://github.com/Sujith8257/Buildify"
                target="_blank"
                rel="noreferrer noopener"
                aria-label="GitHub"
                className="inline-flex h-9 w-9 items-center justify-center rounded-md border border-white/10 bg-white/[0.03] text-muted-foreground transition-colors hover:bg-white/5 hover:text-foreground"
              >
                <GithubIcon className="h-4 w-4" />
              </a>
            </div>
          </div>

          {sections.map((section) => (
            <div key={section.title}>
              <h4 className="text-xs font-semibold uppercase tracking-wider text-foreground/80">
                {section.title}
              </h4>
              <ul className="mt-3 space-y-2 text-sm">
                {section.links.map((link) => (
                  <li key={link.href}>
                    {"external" in link && link.external ? (
                      <a
                        href={link.href}
                        target="_blank"
                        rel="noreferrer noopener"
                        className="text-muted-foreground transition-colors hover:text-foreground"
                      >
                        {link.label}
                      </a>
                    ) : (
                      <Link
                        href={link.href}
                        className="text-muted-foreground transition-colors hover:text-foreground"
                      >
                        {link.label}
                      </Link>
                    )}
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        <div className="mt-12 flex flex-col items-start justify-between gap-4 border-t border-white/5 pt-6 text-xs text-muted-foreground sm:flex-row sm:items-center">
          <p>
            © {new Date().getFullYear()} Buildify. Built on top of{" "}
            <a
              href="https://github.com/ggml-org/llama.cpp"
              className="underline-offset-2 hover:underline"
              target="_blank"
              rel="noreferrer noopener"
            >
              llama.cpp
            </a>
            . MIT-licensed.
          </p>
          <p>
            Made for people who want their AI in their pocket, not on someone
            else&apos;s server.
          </p>
        </div>
      </div>
    </footer>
  );
}
