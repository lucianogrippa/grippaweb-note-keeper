import CategoriesDto from "@/lib/models/categories";
import { Typography } from "@mui/material";
import React from "react";
import DataTable from "../data-table";

export type CategoryUiType = {
    categories: CategoriesDto[],
    totalCategories: number,
    page: number
    maxRowsPerPage: number
}

export default function CategoriesUI(props: CategoryUiType){

    return <div>

        <DataTable />

    </div>

}