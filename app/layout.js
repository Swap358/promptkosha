import "./globals.css";

// Placeholder metadata. Phase 9 replaces this with settings-driven SEO from the database.
export const metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000"),
  title: "PromptKosha: AI prompt gallery",
  description: "Discover, preview and copy AI image, video and photo editing prompts.",
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body className="min-h-screen font-sans antialiased">{children}</body>
    </html>
  );
}
