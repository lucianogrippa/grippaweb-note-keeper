"use server"

import { getSessionDataByToken } from "@/lib/auth/services/auth-service"
import { redirect } from "next/navigation";
import CryptoJS from 'crypto-js'
import UserKeysservice from "@/lib/services/userkey-service";
import { checkPasswordPolicy } from "@/lib/global-utils";

export async function createPwd(token: string, params: FormData) {
    // dal token ottieni l'uitente
    const sessionData = await getSessionDataByToken(token);

    let errorCode = 100;
    const password = params.get("txtPwd");

    const mainRedirect = `${process.env.NEXT_PUBLIC_DOMAIN}${process.env.NEXT_PUBLIC_MAIN_PAGE_APP}`;

    if (!!sessionData && !!sessionData.id && !!password) {

        if (checkPasswordPolicy(password as string)) {

            const userData = (sessionData.data as any).userData;
            const uuid = CryptoJS.SHA256(userData.username).toString();
            const saltedPassword = CryptoJS.SHA256((sessionData.data as any).userData.username + "@" + password).toString();

            // memorizza la password
            const userKeyService = new UserKeysservice(uuid);

            const savedPwd = await userKeyService.save(saltedPassword);

            if (savedPwd && savedPwd.id > 0) {
                return redirect(`${mainRedirect}`);
            }
        } else {
            errorCode = 101;
        }
    }


    return redirect(`${process.env.NEXT_PUBLIC_DOMAIN}${process.env.NEXT_PUBLIC_MAIN_PAGE_APP}/${errorCode}`);
}