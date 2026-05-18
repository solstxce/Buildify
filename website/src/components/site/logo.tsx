import { cn } from "@/lib/utils";

export function Logo({ className }: { className?: string }) {
  return (
    <span
      className={cn(
        "relative inline-flex h-8 w-8 items-center justify-center overflow-hidden rounded-lg",
        className
      )}
      aria-label="Buildify logo"
    >
      <span
        aria-hidden
        className="absolute inset-0 bg-gradient-to-br from-[oklch(0.82_0.16_195)] via-[oklch(0.7_0.2_290)] to-[oklch(0.85_0.18_145)]"
      />
      <span
        aria-hidden
        className="absolute inset-[2px] rounded-[7px] bg-background"
      />
      <svg
        aria-hidden
        viewBox="0 0 24 24"
        fill="none"
        className="relative h-4 w-4 text-foreground"
      >
        <path
          d="M7 4h6.5a3.5 3.5 0 0 1 3.5 3.5v0a3.5 3.5 0 0 1-2.286 3.282A3.75 3.75 0 0 1 17 14.5V15a4 4 0 0 1-4 4H7V4z"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinejoin="round"
        />
      </svg>
    </span>
  );
}
