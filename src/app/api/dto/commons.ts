export interface CommonResponseEntity<T> {
    message: string,
    data: T
    status: "ok" | "error"
}