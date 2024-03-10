import { NextRequest, NextResponse } from 'next/server';
import { getTokenFromCookie} from '@/lib/auth/services/token-check';
import { getSessionByToken, updateSession } from '@/lib/auth/services/auth-service';
import logger from '@/lib/logger-settings';

/**
 * Ottiene i dati della sessione
 * @param _req 
 */
export async function GET(_req: NextRequest) {
    try {
        const apiToken = await getTokenFromCookie(_req);
        // ottieni il token dall'header
        const headerToken = _req.headers.get("x-app-auth");
        if (!!headerToken) {

            const cleandToken = headerToken.replace("Bearer", '').trim();

            const sessionData = await getSessionByToken(cleandToken);

            if(!!sessionData && !!sessionData.id){
                // aggiorna il last update
                await updateSession(cleandToken, sessionData.data);
                return NextResponse.json(sessionData, {
                    status: 200
                });
            } else{
                return NextResponse.json({
                    message: 'Session not found'
                }, {
                    status: 404
                });
            }

        } else {
            return NextResponse.json({
                message: 'Invalid credentials'
            }, {
                status: 400
            });
        }
    } catch (error) {
        logger.error(error);
    }

    return NextResponse.json({
        message: 'bad request'
    }, {
        status: 400
    })
}
