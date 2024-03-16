import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { ThemeProvider } from '@mui/material/styles';
import { AppRouterCacheProvider } from "@mui/material-nextjs/v13-appRouter";

import theme from '@/app/ui/theme';

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Grippaweb password keeper",
  description: "Manage password and another this to keep secreat",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>Document</title>
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css"/>
      </head>
      <body className={inter.className}>
        <ThemeProvider theme={theme}>
          <AppRouterCacheProvider options={{ key: 'css' }}>
            {children}
          </AppRouterCacheProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
