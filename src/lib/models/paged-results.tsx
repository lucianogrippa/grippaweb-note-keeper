export interface PagedResults<T> {
    maxRowsPerPage: number
    pageIndex: number;
    totalResults: number;
    items: T[]
}