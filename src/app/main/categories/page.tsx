import MainAppPage from "../MainApp";
import CategoriesUI from "@/app/ui/pages/categories";



export default async function MainCategories({ searchParams }) {

    return <MainAppPage mainContainerUI={<CategoriesUI />} />
}
