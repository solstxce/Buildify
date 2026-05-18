import { promises as fs } from "node:fs";
import path from "node:path";
import { NextResponse } from "next/server";

const STORAGE_PATH = path.join(process.cwd(), ".data", "waitlist.json");

type WaitlistEntry = {
  email: string;
  createdAt: string;
  source?: string;
  ua?: string;
};

async function readEntries(): Promise<WaitlistEntry[]> {
  try {
    const raw = await fs.readFile(STORAGE_PATH, "utf8");
    const parsed = JSON.parse(raw) as unknown;
    return Array.isArray(parsed) ? (parsed as WaitlistEntry[]) : [];
  } catch {
    return [];
  }
}

async function appendEntry(entry: WaitlistEntry) {
  const entries = await readEntries();
  const exists = entries.some(
    (e) => e.email.toLowerCase() === entry.email.toLowerCase(),
  );
  if (exists) return { added: false, total: entries.length };
  entries.push(entry);
  await fs.mkdir(path.dirname(STORAGE_PATH), { recursive: true });
  await fs.writeFile(STORAGE_PATH, JSON.stringify(entries, null, 2), "utf8");
  return { added: true, total: entries.length };
}

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export async function POST(req: Request) {
  try {
    const body = (await req.json().catch(() => ({}))) as {
      email?: unknown;
      source?: unknown;
    };
    const emailRaw =
      typeof body.email === "string" ? body.email.trim().toLowerCase() : "";
    if (!emailRaw || !EMAIL_RE.test(emailRaw) || emailRaw.length > 254) {
      return NextResponse.json(
        { error: "Please use a valid email address." },
        { status: 400 },
      );
    }
    const source = typeof body.source === "string" ? body.source : "homepage";
    const ua = req.headers.get("user-agent")?.slice(0, 200) ?? undefined;

    const result = await appendEntry({
      email: emailRaw,
      createdAt: new Date().toISOString(),
      source,
      ua,
    });

    return NextResponse.json({
      ok: true,
      duplicate: !result.added,
      total: result.total,
    });
  } catch (err) {
    console.error("waitlist POST error", err);
    return NextResponse.json(
      { error: "Server error. Try again in a moment." },
      { status: 500 },
    );
  }
}

export async function GET() {
  return NextResponse.json(
    { error: "Method not allowed" },
    { status: 405 },
  );
}
