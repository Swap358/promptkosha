// Next.js settings. Kept small on purpose; more is added in later phases.
const supabaseHost = process.env.NEXT_PUBLIC_SUPABASE_URL
  ? new URL(process.env.NEXT_PUBLIC_SUPABASE_URL).hostname
  : null;

/** @type {import('next').NextConfig} */
const nextConfig = {
  // Spec URLs look like /prompt/my-slug/ (with a trailing slash).
  trailingSlash: true,

  // Allow next/image to load pictures from our Supabase Storage bucket.
  images: {
    remotePatterns: supabaseHost
      ? [{ protocol: "https", hostname: supabaseHost, pathname: "/storage/v1/object/public/**" }]
      : [],
  },

  // Do not advertise the framework in response headers.
  poweredByHeader: false,
};

module.exports = nextConfig;
