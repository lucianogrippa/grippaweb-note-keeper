export default interface ResponseDto<T> {
    message: string
    error: boolean
    data: T | any
}