export interface ApiResponse<T> {
    msg?: string,
    data?: T,
    error?: string
}

export type AuthToken = {
    completeName?: string
    userName?: string,
    role?: string,
    requireOtp?: boolean,
    token?: string,
    renew?: string,
    error?: string
}