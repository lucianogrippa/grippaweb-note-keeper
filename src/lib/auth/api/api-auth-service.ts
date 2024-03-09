import logger from "@/lib/logger-settings";
import { AuthToken } from "./api-models";
import ApiService from "./api-service";
import CryptoJS from "crypto-js";

type SessionDataDto = {
    id: string;
    token: string;
    maxAge: number,
    lastUpdate: Date
}

export class ApiAuthService extends ApiService {

    async logout() {
        return await this.post('api/auth/logout');
    }

    async loginWithUsernameAndPassword(username: string, password: string): Promise<AuthToken | null> {

        try {
            const authCode = CryptoJS.SHA256((new Date()).getTime().toString()).toString();


            const authCodePwd = CryptoJS.SHA256(authCode + CryptoJS.SHA256(`${username}${password}`).toString()).toString();

            const body = {
                username,
                password: authCodePwd,
                code: authCode
            }

            const result = await this.post("api/v1/auth/signin", body);

            if(result && !!result.data){
                return result.data;
            }
        } catch (error) {
            console.log(error);
        }

        return null;
    }

    async findUserByToken(username: string) {
        try {
            return await this.get(`api/v1/accounts/user/${username}`);
        } catch (error) {
            logger.error(error);
        }

        return null;
    }

    async loadSessionData(authUrl: URL): Promise<SessionDataDto | null> {
        try {
            const data = await this.get(`api/auth`);
            if (data && data.id) {

                // esegui l'update della sessione se il token è valido

                return {
                    id: data.id,
                    lastUpdate: new Date(data.lastUpdate),
                    maxAge: Number(data.maxAge),
                    token: data.token
                }
            }
        } catch (error) {
            logger.error(error);
        }

        return null;
    }

}