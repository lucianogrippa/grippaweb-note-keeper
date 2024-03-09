import logger from '@/lib/logger-settings';
import prisma from '@/lib/prisma';


const prismaClient = prisma;

export async function updateSession(token: string, data: string) {
    try {
        const tokenData = await getSessionByToken(token);

        if (!!tokenData && !!tokenData.token) {

            const resultSession = await prismaClient.sessions.update({
                where: {
                    token: token
                },
                data: {
                    token,
                    data,
                    maxAge: Number(process.env.SESSION_MAX_AGE),
                    lastUpdate: new Date()
                }
            });
            return resultSession ?? null;
        } else {

            const createSession = await prismaClient.sessions.create({
                data: {
                    token,
                    data,
                    maxAge: Number(process.env.SESSION_MAX_AGE)
                }
            });

            return createSession ?? null;
        }
    } catch (error) {
        logger.error(error);
    }

    return null;
}




export async function clearSessionByToken(_token?: string) {
    try {
        const deleteResult = await prismaClient.sessions.deleteMany({
            where: {
                token: _token
            }
        });

        return !!deleteResult && deleteResult.count > 0
    } catch (error) {
        logger.error(error);
    }

    return false;
}


export async function getSessionByToken(_token?: string) {
    try {
        const resultData = await prismaClient.sessions.findFirst({
            select: {
                id:true,
                data: true,
                maxAge: true,
                token: true,
                lastUpdate: true,
                creationDate: true,
            },
            where: {
                token: _token
            },
        });

        if (!!resultData && !!resultData.id) {
            return resultData;
        }
    } catch (error) {
        logger.error(error);
    }

}

export async function getSessionById(_id?: string) {
    try {
        const resultData = await prismaClient.sessions.findFirst({
            where: {
                id: _id
            }
        });

        if (!!resultData && !!resultData.id) {
            return resultData;
        }
    } catch (error) {
        logger.error(error);
    }

    return null;
}