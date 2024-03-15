import CategoryService from "@/lib/services/categoris-service";
import MainAppPage from "../MainApp";
import CategoriesUI from "@/app/ui/pages/categories";
import {  getUUIDFromHeaders } from "@/lib/auth/services/token-check";



export default async function MainCategories({ searchParams }) {

    const uuid = await getUUIDFromHeaders();

    const search = searchParams._s || "";

    const categoryService = new CategoryService(uuid);
    let categories = []
    const maxRowsPerPage = 100;
    const page = searchParams._p  || 1;

    let totalCategories= 0;
    
    try {
        
        const categoryRersult = await  categoryService.loadAllCategories(search,page,maxRowsPerPage);
        
        if(categoryRersult && categoryRersult.totalResults>0){

            categories = categoryRersult.items;
            totalCategories = categoryRersult.totalResults;

        }

    } catch (error) {
        console.error(error);
    }

    return <MainAppPage mainContainerUI={<CategoriesUI 
                                            categories={categories} 
                                            maxRowsPerPage={maxRowsPerPage} 
                                            page={page} 
                                            totalCategories={totalCategories}/>} />
}
