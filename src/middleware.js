import { NextResponse } from 'next/server';

export function middleware(request) {
  const { pathname } = request.nextUrl;

  // Strip duplicate /v1/v1 → /v1
  if (pathname.startsWith('/v1/v1/')) {
    const url = request.nextUrl.clone();
    url.pathname = pathname.replace(/^\/v1\/v1\//, '/v1/');
    return NextResponse.rewrite(url);
  }

  return NextResponse.next();
}

export const config = {
  matcher: '/v1/:path*',
};
