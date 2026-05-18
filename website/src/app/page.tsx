import { Hero } from "@/components/site/hero";
import { Features } from "@/components/site/features";
import { HowItWorks } from "@/components/site/how-it-works";
import { LiveDemo } from "@/components/site/live-demo";
import { Faq } from "@/components/site/faq";
import { Waitlist } from "@/components/site/waitlist";

export default function HomePage() {
  return (
    <>
      <Hero />
      <Features />
      <HowItWorks />
      <LiveDemo />
      <Faq />
      <Waitlist />
    </>
  );
}
