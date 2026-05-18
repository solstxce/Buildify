export function Markdown({ html }: { html: string }) {
  return (
    <article
      className="prose-buildify mx-auto max-w-3xl"
      dangerouslySetInnerHTML={{ __html: html }}
    />
  );
}
