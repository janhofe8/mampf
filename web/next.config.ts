import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "nuriruulwjjpycdszdrn.supabase.co",
        pathname: "/storage/**",
      },
    ],
  },
};

export default nextConfig;
