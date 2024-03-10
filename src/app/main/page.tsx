import { getSessionDataByToken } from "@/lib/auth/services/auth-service";
import UserKeysservice from "@/lib/services/userkey-service";
import CryptoJS from "crypto-js";

export default async function MainPage({ searchParams}) {

    // verifica se necessario effettuare la creazione delle credenziali
    const token =  searchParams?._t;

    if (!!token) {
        const sessionData = await getSessionDataByToken(token);

        if (!!sessionData && !!sessionData.data) {
            // ottieni le chiavi
            const userKeysService = new UserKeysservice(CryptoJS.SHA256((sessionData.data as any).userData.username).toString());
            const key =await userKeysService.findKey();
            if(!key){

                return <div>
                    Sceli una chiave
                </div>
            }
        }
    }

    return <>
        Main
    </>
} 