import { JwtPayload } from 'jsonwebtoken';
import logger from '@/lib/logger-settings';
import { jwtVerify } from 'jose';
import CryptoJS from 'crypto-js';
import { NextRequest } from 'next/server';
import { serialize } from 'cookie';

export async function isValidToken(providedToken: string): Promise<JwtPayload | boolean> {
    try {
        let uint8ArrayKey = new TextEncoder().encode(process.env.JWT_SECREAT as string);
        const validate = await jwtVerify(providedToken, uint8ArrayKey);

        if (!!validate.payload) {
            const username = validate.payload.sub as string;
            const expDate = new Date(validate.payload.exp as number);
            const expired = expDate.getTime() <= Date.now();

            const verifyIssuer = !!validate.payload.iss;
            const audience = !!validate.payload.aud && validate.payload.aud.length>0;

            if (!!username && !expired && verifyIssuer && audience) {
                return validate && validate.payload as JwtPayload;
            }
        }
    } catch (error) {
        logger.error(error);
    }
    return false;
}

export async function getTokenFromCookie( req: NextRequest) {

    try {
        const keyCookie = CryptoJS.SHA256((process.env.AUTH_SECRET as string)).toString();
        const cookie = req.cookies.get(process.env.SESSION_COOKIE_NAME);

        
        if(!!cookie){
            return CryptoJS.AES.decrypt(cookie.value as string,keyCookie,{
                format: CryptoJS.format.OpenSSL
            }).toString(CryptoJS.enc.Utf8);
        }
    } catch (error) {
        logger.error(error);
    }

    return null;
}

export async function setTokenFromCookie(_token: string) {

    try {
        const keyCookie = CryptoJS.SHA256((process.env.AUTH_SECRET as string)).toString();
        const encData =  CryptoJS.AES.encrypt(_token as string,keyCookie,{
            format: CryptoJS.format.OpenSSL
        });

        return serialize(process.env.SESSION_COOKIE_NAME as string,encData.toString(),{
            httpOnly: true,
            maxAge:  Number(process.env.SESSION_MAX_AGE)*1000, // One week
            path: '/',
            secure: process.env.NODE_ENV === "production"
        });

    } catch (error) {
        logger.error(error);
    }

    return null;
}