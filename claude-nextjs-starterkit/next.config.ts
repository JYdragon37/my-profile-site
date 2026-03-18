import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  experimental: {
    // Turbopack이 Google Fonts 등 HTTPS 요청 시 시스템 TLS 인증서 사용 (맥/프록시 환경에서 연결 오류 방지)
    turbopackUseSystemTlsCerts: true,
  },
};

export default nextConfig;
