import CategoriesDto from "../models/categories";
import { PagedResults } from "../models/paged-results";

export default class CategoryService {

    constructor(private basePath?){
        this.basePath = basePath || `${process.env.NEXT_PUBLIC_DOMAIN}/api/categories`
    }

    async findById(_id: number) : Promise<CategoriesDto> {
        try {
            
             
            const fetchApi = await fetch(`${this.basePath}/${_id}`);

            if(fetchApi && fetchApi.ok){
                const body = await fetchApi.json();

                if(!!body && !body.error) {
                    return body.data;
                }
            }
        } catch (error) {
            console.error(error);
        }

        return null;
    }
    async loadAll(search: string = '' ,pageIndex: number= 1, maxRowPerPage: number = 50): Promise<PagedResults<CategoriesDto>> {
        try {
            
            const fetchApi = await fetch(`${this.basePath}?_s=${search}&_p=${pageIndex}&_m=${maxRowPerPage}`);

            if(fetchApi && fetchApi.ok){
                const body = await fetchApi.json();

                if(!!body && !body.error) {
                    return body.data;
                }
            }

        } catch (error) {
            console.error(error);
        }

        return null
    }

    async save(category:CategoriesDto): Promise<CategoriesDto> {
        try {
            
            const fetchApi = await fetch(`${this.basePath}`,{
                method: "POST",
                body: JSON.stringify(category)
            });

            if(fetchApi && fetchApi.ok){
                const body = await fetchApi.json();

                if(!!body && !body.error) {
                    return body.data;
                }
            }

        } catch (error) {
            console.error(error);
        }

        return null
    }

    async delete(id: number): Promise<PagedResults<boolean>> {
        try {
            
            const fetchApi = await fetch(`${this.basePath}/${id}`,{
                method: "DELETE"
            });

            if(fetchApi && fetchApi.ok){
                const body = await fetchApi.json();

                if(!!body && !body.error) {
                    return body.data;
                }
            }

        } catch (error) {
            console.error(error);
        }

        return null
    }
} 