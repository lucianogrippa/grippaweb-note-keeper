import { NextRequest, NextResponse } from 'next/server';
import {  middlewareExcludeAuthFilter, middlewareAuthFilter } from '@/lib/auth/middleware-auth-filter';


export async function middleware(request: NextRequest) {

    console.debug("into middleware");
  
    const authFilterExclude = await middlewareExcludeAuthFilter(request);
    if (!authFilterExclude) {
      const jwtFilter = await  middlewareAuthFilter(request);
  
      return jwtFilter;
    }
  
    return NextResponse.next();
  }

/*
* Match all request paths except for the ones starting with:
* - api (API routes)
* - _next/static (static files)
* - _next/image (image optimization files)
* - favicon.ico (favicon file)
*/
export const config = {
    // https://nextjs.org/docs/app/building-your-application/routing/middleware#matcher
    matcher: ['/((?!api|locales|_next\/static|_next\/image|.*\\.ico|.*\\.jpg|.*\\.png$).*)'],
};