import type { Metadata } from "next";

import "./globals.css";

export const metadata: Metadata = {
  title: "Drum Lesson OS",
  description: "Student progress, traits, and next lesson cues for drum instructors.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
