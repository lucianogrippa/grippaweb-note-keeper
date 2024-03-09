import logger from "@/lib/logger-settings";

export default class ApiService {

    private _token?: string;
    private _appKey?: string;
    private _appCode?: string;
    private _apiBaseController?: string;

    constructor(_token?: string,_apiControllerUrl?: string) {
        this.token = _token as string;
        this._appKey = process.env.NEXT_PUBLIC_APP_KEY as string;
        this._appCode = process.env.NEXT_PUBLIC_APP_CODE as string;
        this._apiBaseController =_apiControllerUrl || process.env.NEXT_PUBLIC_BACKEND_API_ENDPOINT as string
    }

    private _setHeaders(): any{

        const headers = {
            "Content-Type": "application/json"
        };

        if(!!this.token){
            headers["x-app-auth"]=`Bearer ${this.token}`;
        }

        if(!!this._appKey){
            headers["x-appkey-auth"]=this._appKey;
        }

        if(!!this._appCode){
            headers["x-appcode"]= this._appCode;
        }

        return headers;
    }

    private async _fetch(method: string, path: string, body?: any) {
        try {
            const options: RequestInit = {
                method,
                headers: this._setHeaders(),
                redirect: "follow",
            };

            if(!!body){
                options.body =JSON.stringify(body);
            }

            const result = await fetch(`${this._apiBaseController}/${path}`,options );

            if (result.ok) {
                return await result.json();
            }
        } catch (error) {
            logger.error(error);
        }
        return null;
    }

    get token(): string {
        return this._token as string;
    }

    set token(value: string) {
        this._token = value;
    }

    async get(path: string, body?: any) {
        return this._fetch("get", path, body);
    }

    async post(path: string, body?: any) {
        return this._fetch("post", path, body);
    }

    async put(path: string, body?: any) {
        return this._fetch("put", path, body);
    }

    async delete(path: string, body?: string) {
        return this._fetch("delete", path, body);
    }
}