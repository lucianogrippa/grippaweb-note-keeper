import { ApiAuthService } from "@/lib/auth/api/api-auth-service";
import { clearSessionByToken, updateSession } from "@/lib/auth/services/auth-service";
import { isValidToken, setTokenFromCookie } from "@/lib/auth/services/token-check";
import { NextRequest, NextResponse } from "next/server";
import CryptoJS from 'crypto-js';
import { JwtPayload } from "jsonwebtoken";

export async function GET(_req: NextRequest) {
    try {

        const formData = _req.nextUrl.searchParams || await _req.formData() || _req.headers;

        let token = formData.get("_t");
        const apiKey = formData.get("_k");
        const appCode = formData.get("_c");

        const systemAppCode = genAppKey(process.env.NEXT_PUBLIC_APP_CODE);
        const systemAppKey = genAppKey(process.env.NEXT_PUBLIC_APP_KEY);

        const chekAppCode = !!appCode && systemAppCode && systemAppCode === appCode;
        const chekAppKey = !!apiKey && systemAppKey && systemAppKey === apiKey;

        if (!chekAppCode || !chekAppKey) {
            return redirectToLogin(_req);
        }
        token = token.toString();
        const tokenPayload = await isValidToken(token);

        const chekAppToken = !!tokenPayload && !!(tokenPayload as JwtPayload).sub;


        if (chekAppToken) {
            // se il token e' valido allora cerca l'utente attraverso l'username
            const authService = new ApiAuthService(token);
            const userVer = await authService.findUserByToken((tokenPayload as JwtPayload).sub);

            if (!!userVer && !!userVer.data && !!userVer.data.username) {
                // utente trovato , setta il cookie
                const cookieData = await setTokenFromCookie(token);
                if (!!cookieData) {

                    // inizializza la sessione
                    await clearSessionByToken(token);
                    await updateSession(token, JSON.stringify({
                        userData: userVer.data,
                    }));
                    const headers = {
                        "Set-Cookie": cookieData
                    }
                    // redirect to main page
                    return NextResponse.redirect(new URL(`${process.env.NEXT_PUBLIC_DOMAIN}${process.env.NEXT_PUBLIC_MAIN_PAGE_APP}`, _req.url), {
                        headers
                    });
                }
            }

        }

    } catch (error) {
        console.error(error);
    }
    return redirectToLogin(_req);
}

function genAppKey(_appKey: string) {
    return CryptoJS.SHA256(_appKey).toString(CryptoJS.enc.Base64);
}

function redirectToLogin(_req: NextRequest) {
    const loginUrl = new URL('/login/?error=100', _req.url);
    return NextResponse.redirect(loginUrl);
}