import type { Metadata, Viewport } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { Toaster } from "@/components/ui/sonner";
import { SiteNav } from "@/components/site/nav";
import { SiteFooter } from "@/components/site/footer";

const geistSans = Geist({
  variable: "--font-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

const siteUrl = "https://buildify.me";

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: {
    default: "Buildify · Your phone speaks API now",
    template: "%s · Buildify",
  },
  description:
    "Turn your Android phone into a private LLM HTTP server. Open-source, local, free. Stop renting cloud GPUs — your pocket has a model now.",
  keywords: [
    "local LLM",
    "android ai server",
    "llama.cpp android",
    "private ai",
    "offline ai",
    "buildify",
    "gguf",
    "ollama on phone",
  ],
  authors: [{ name: "Buildify" }],
  openGraph: {
    title: "Buildify · Your phone speaks API now",
    description:
      "Open-source Android app that runs local LLMs and exposes an OpenAI-compatible API on your Wi-Fi.",
    url: siteUrl,
    siteName: "Buildify",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Buildify · Your phone speaks API now",
    description:
      "Open-source Android app that runs local LLMs and exposes an OpenAI-compatible API on your Wi-Fi.",
  },
  icons: {
    icon: "/favicon.ico",
  },
};

export const viewport: Viewport = {
  themeColor: "#0a0a0f",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      className={`${geistSans.variable} ${geistMono.variable} dark h-full antialiased`}
      suppressHydrationWarning
    >
      <body className="relative min-h-full flex flex-col bg-background text-foreground">
        <SiteNav />
        <main className="flex-1">{children}</main>
        <SiteFooter />
        <Toaster
          position="bottom-right"
          theme="dark"
          toastOptions={{
            classNames: {
              toast:
                "bg-card border border-white/10 text-foreground shadow-2xl",
            },
          }}
        />
      </body>
    </html>
  );
}
