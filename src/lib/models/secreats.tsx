import CategoriesDto from "./categories"

export default interface SecreatsDTO {
    id: number
    uuid: number
    category: CategoriesDto
    name: string
    content: string
}