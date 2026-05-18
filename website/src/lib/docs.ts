import { promises as fs } from "node:fs";
import path from "node:path";

import matter from "gray-matter";

const DOCS_DIR = path.resolve(process.cwd(), "..", "docs");

const ORDER = [
  "product-vision",
  "architecture",
  "android-llama-engine",
  "models-and-downloads",
  "api-and-testing",
  "security-and-safety",
  "troubleshooting",
  "roadmap",
  "marketing-site-deployment",
];

const TITLES: Record<string, string> = {
  README: "Documentation overview",
  "product-vision": "Product vision",
  architecture: "Architecture",
  "android-llama-engine": "Android engine (llama.cpp)",
  "models-and-downloads": "Models & downloads",
  "api-and-testing": "API & testing",
  "security-and-safety": "Security & safety",
  troubleshooting: "Troubleshooting",
  roadmap: "Roadmap",
  JNIBundle: "JNI bundle layout",
  "marketing-site-deployment": "Marketing site deployment",
};

const DESCRIPTIONS: Record<string, string> = {
  "product-vision":
    "Why Buildify exists, what we ship, and what we explicitly don’t.",
  architecture:
    "Flutter → MethodChannel → foreground service → llama.cpp → GGUF on device.",
  "android-llama-engine":
    "Why the binary lives in jniLibs, what files belong in arm64-v8a, and how packaging works.",
  "models-and-downloads":
    "Curated GGUF models, where they’re stored on the phone, and how to ADB-copy your own.",
  "api-and-testing":
    "Local HTTP endpoints, OpenAI-compatible chat completions, and how to test with Postman.",
  "security-and-safety":
    "API key authentication, idle/battery/thermal auto-stop, and how to call the server from your laptop.",
  troubleshooting: "Common errors and how to fix them fast.",
  roadmap: "Phases that are done, in progress, and planned.",
  JNIBundle: "How to copy the llama-server release tarball into jniLibs/.",
  "marketing-site-deployment":
    "pnpm vs npm, Vercel vs GitHub Pages, and Cloudflare DNS for buildify.me.",
};

export interface DocMeta {
  slug: string;
  title: string;
  description?: string;
}

export interface DocFile extends DocMeta {
  content: string;
  raw: string;
}

export async function listDocs(): Promise<DocMeta[]> {
  let names: string[];
  try {
    names = await fs.readdir(DOCS_DIR);
  } catch {
    return [];
  }
  const docs = names
    .filter((n) => n.endsWith(".md"))
    .map((n) => n.replace(/\.md$/, ""))
    .filter((slug) => slug !== "README");

  const ordered = [
    ...ORDER.filter((s) => docs.includes(s)),
    ...docs.filter((s) => !ORDER.includes(s)),
  ];

  return ordered.map((slug) => ({
    slug,
    title: TITLES[slug] ?? slug,
    description: DESCRIPTIONS[slug],
  }));
}

export async function getDoc(slug: string): Promise<DocFile | null> {
  const filePath = path.join(DOCS_DIR, `${slug}.md`);
  let raw: string;
  try {
    raw = await fs.readFile(filePath, "utf8");
  } catch {
    return null;
  }
  const { content, data } = matter(raw);
  const title =
    (data?.title as string | undefined) ?? TITLES[slug] ?? slug;
  const description =
    (data?.description as string | undefined) ?? DESCRIPTIONS[slug];
  return { slug, title, description, content, raw };
}

export function docHref(slug: string) {
  return `/docs/${slug}`;
}
