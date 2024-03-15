import { ApiAuthService } from "@/lib/auth/api/api-auth-service";
import logger from "@/lib/logger-settings";
import { redirect } from "next/navigation";
import CryptoJS from 'crypto-js';

export type LoginState = {
    errors?: {
        email?: string[];
        password?: string[];
        status?: string[];
    };
    message?: string | null;
};

function genAppKey(_appKey: string) {
    return CryptoJS.SHA256(_appKey).toString(CryptoJS.enc.Base64);
}


export async function signin(prevState: LoginState, formData: FormData): Promise<LoginState> {
    try {
        const email = formData.get('email');
        const password = formData.get('password');

        const apiService = new ApiAuthService();
        const loginData = await apiService.loginWithUsernameAndPassword(email.toString(), password.toString());

        if (!!loginData && !!loginData.userName) {
            const token = loginData.token;

            if (!!token) {
                // fai il redirect al login effettivo
                const _t = token;
                const _k = genAppKey(process.env.NEXT_PUBLIC_APP_KEY);
                const _c = genAppKey(process.env.NEXT_PUBLIC_APP_CODE);
                const destinationUrl = `${process.env.NEXT_PUBLIC_DOMAIN}/api/auth/signin/?_t=${encodeURIComponent(_t)}&_k=${encodeURIComponent(_k)}&_c=${encodeURIComponent(_c)}`;

                location.replace(destinationUrl);

                return {
                    errors: {
                        email: [],
                        password: [],
                        status: []
                    },
                    message: null
                }
            }
        }

        return {
            errors: {
                email: ['error_email'],
                password: ['error password'],
                status: ['credential_error']
            },
            message: "Incorrect Username or Password"
        }
    } catch (error) {
        logger.error(error);
    }

    return {
        errors: {
            email: ['error_email'],
            password: ['error password'],
            status: ['credential_error']
        },
        message: "invalid username or password"
    }
}

export async function logout(state: FormData) {
    try {
        const noRedirect = state.get("no-redirect");

        const baseUrl = new URL('/', `${process.env.NEXT_PUBLIC_DOMAIN}`);

        const apiAuth = new ApiAuthService(null, baseUrl.toString());

        await apiAuth.logout();

        const loginUrl = new URL(`${process.env.NEXT_PUBLIC_DOMAIN}${process.env.NEXT_PUBLIC_LOGIN_FORM_PATH}`);

        if(!noRedirect){
            redirect(loginUrl.toString());
        }
    } catch (error) {
        console.error(error);
    }

    return true;
}