import { clearSessionByToken } from "@/lib/auth/services/auth-service";
import { getTokenFromCookie } from "@/lib/auth/services/token-check";
import logger from "@/lib/logger-settings";
import { NextRequest, NextResponse } from "next/server";

export async function POST(_req: NextRequest) {
    try {
        const cookieData = await getTokenFromCookie(_req);

        const isDelete = _req.cookies.delete(process.env.SESSION_COOKIE_NAME);

        logger.debug("cookie deleted ",isDelete);

        if(!!cookieData){
            await clearSessionByToken(cookieData);
        }

        return   NextResponse.json({
            message: "session expired"
        }, {
            status: 200
        })
    } catch (error) {
        logger.error(error);
    }

    return NextResponse.json({
        message: "deleted"
    }, {
        status: 200
    })
}