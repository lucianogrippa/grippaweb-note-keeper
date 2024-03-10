import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { getTokenFromCookie, isValidToken } from '@/lib/auth/services/token-check';
import logger from '@/lib/logger-settings';
import { ApiAuthService } from './api/api-auth-service';

async function getSessionByToken(_token?: string, request?: NextRequest) : Promise<{
  id: string,
  token: string,
  maxAge: number,
  lastUpdate: Date
} | null>
{
  try {
    const authUrl = new URL(`${process.env.NEXT_PUBLIC_DOMAIN}/`);
    // chiama in get /apiAuth per ottenere i dati di sessione
    const apiService = new ApiAuthService(_token,authUrl.toString());

    const sessionData = await  apiService.loadSessionData(authUrl);


    if(!!sessionData && !!sessionData.id){
      return sessionData;
    }

  } catch (error) {
      logger.error(error);
  }

  return null
}

export async function checkSession(_token?: string, request?: NextRequest) {
  const sessionData = await getSessionByToken(_token, request);

  if (!!sessionData && !!sessionData.id) {
      const exp = sessionData.lastUpdate.getTime() + sessionData.maxAge * 1000;

      const now = Date.now();

      return exp >= now;
  }

  return false;
}

/**
 * Restituisce true se il path della richiesta non deve essere sottoposto a verifica dell'autorizzaione
 *
 * @param request
 * @param pathToExclude array di path da escludere
 * @returns  true se i paths sono da escludere
 */
export async function middlewareExcludeAuthFilter(request: NextRequest, pathToExclude: string[] = []) {

  const stanndardPath = [process.env.NEXT_PUBLIC_LOGIN_FORM_PATH,'/_next/', ...pathToExclude];

  const pathName = request.nextUrl.pathname;

  return stanndardPath.some((_t) => pathName.includes(_t as string));
}


/**
 * Verifica se la sessione e' presente, se lo e' vai alla pagina del path richiesto altrimenti fasi il redirect alla login
 * 
 * @param request 
 * @returns 
 */
export async function middlewareAuthFilter(request: NextRequest) {


  // leggi il token dal cookie
  const sessionToken = await getTokenFromCookie(request);

  if (!!sessionToken) {
    // verifica che la sessione sia presente nel db
    const dbSession = await checkSession(sessionToken, request);

    if (!dbSession) {
      const loginPath = new URL(`${process.env.NEXT_PUBLIC_DOMAIN}${process.env.NEXT_PUBLIC_LOGIN_FORM_PATH}`);
      return Response.redirect(loginPath);
    }
  } else {
      // cookie non presente
      const loginPath = new URL(`${process.env.NEXT_PUBLIC_DOMAIN}${process.env.NEXT_PUBLIC_LOGIN_FORM_PATH}`);
      return Response.redirect(loginPath);
  }

  return NextResponse.next();
}

/// nell'header devo esserci :
/// x-appkey-auth x-appcode per poter utilizzare le api 
/// di get pinvece per le api di update inser e delete 
//  deve esserci x-app-auth
export async function middlewareJwtFilter(request: NextRequest) {

  logger.info("into middlewareJwtFilter");
  const appkey = request.headers.get("x-appkey");
  const appcode = request.headers.get("x-appcode");
  const appauth = request.headers.get("x-app-auth");
  const metod = request.method;

  if (!appkey || !appcode || appkey !== process.env.NEXT_PUBLIC_APP_KEY || appcode !== process.env.NEXT_PUBLIC_APP_CODE) {
    logger.info(`${appkey} o ${appcode} is not equal ${process.env.NEXT_PUBLIC_APP_KEY} or ${process.env.NEXT_PUBLIC_APP_CODE}`)
    return NextResponse.json({
      starus: "error",
      message: "not authorized api usage"
    }, {
      status: 401
    });
  }

  if (metod !== "GET") {

    if (!appauth) {
      return NextResponse.json({
        starus: "error",
        message: "not authorized api usage"
      }, {
        status: 401
      });
    }

    // verifica il token
    const token = appauth.replace("Bearer", "").trim();

    const tokenverify = await isValidToken(token);

    if (!tokenverify) {
      return NextResponse.json({
        starus: "error",
        message: "not authorized api usage"
      }, {
        status: 401
      });
    }
  }

  return NextResponse.next();
}
