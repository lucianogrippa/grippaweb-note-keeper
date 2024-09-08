"use client"
import CategoriesDto from "@/lib/models/categories";
import React, { Suspense, useCallback, useEffect, useState } from "react";
import DataTable, { ColumnType } from "../data-table";
import { Button, ButtonGroup, FormControlLabel, FormGroup, InputBase, Paper, Switch, alpha } from "@mui/material";
import { Add, Delete, Edit } from "@mui/icons-material";
import SearchIcon from '@mui/icons-material/Search';
import EditAddCategoryDialog from "../dialogs/add-category-dialog";
import { Waiting } from "../waiting";
import CategoryService from "@/lib/services/category-service";
import AlertDialog from "../dialogs/alert-dialog";
import { Search, SearchIconWrapper, StyledInputBase } from "../theme";

export type CategoryUiState = {
    categories?: CategoriesDto[],
    totalCategories?: number,
    page?: number
    maxRowsPerPage?: number
}

export default function CategoriesUI() {

    const alertDialogRef = React.createRef<AlertDialog>();
    const editDialgRef = React.createRef<EditAddCategoryDialog>();
    const [pages, setPages] = useState<CategoryUiState>({
        categories: [],
        maxRowsPerPage: 50,
        page: 1,
        totalCategories: 0

    });

    const [search, setSearch] = useState('');
    const [showAddEditCayegory, setShowAddEditCategory] = useState(false);
    const [editMode, setEditMode] = useState(true);
    const [category, setCategory] = useState<CategoriesDto>()
    const [loading,setLoading] = useState(false);

    /**
     * Ottieni le categorie
     */
    const loadCategories = useCallback(async (_search= '', _page=1, _maxRows=50) => {

        setLoading(true);
        const categoryService = new CategoryService();

        const resultData = await categoryService.loadAll(_search,_page,_maxRows);

        if(!!resultData){
            setPages({
                categories: resultData.items,
                maxRowsPerPage: resultData.maxRowsPerPage,
                page: resultData.pageIndex,
                totalCategories: resultData.totalResults
            });
        } else {
            setPages({
                categories: [],
                maxRowsPerPage: _maxRows,
                page: 1,
                totalCategories:0
            });
        }
        setLoading(false);
    },[setPages]);

    // carica all'avvio tutte le categorie
    useEffect(()=>{
        loadCategories();
    }, [loadCategories]);

    const cols: ColumnType[] = [
        {
            id: 0,
            bind: "id",
            maxWidth: 50,
            minWidth: 50,
            label: "Actions",
            renderRow: (value, row, cellIndex, rowIndex) => {
                if (!!value) {
                    return <ButtonGroup size="small" aria-label="Actions buttos edit and delete category" style={{ gap: 2 }} >
                        <Button key="edit" onClick={onEditCategory.bind(this, row)} color="secondary" startIcon={<Edit />} >Edit</Button>,
                        <Button key="delete" color="error" onClick={onDeleteCategory.bind(this, row)} startIcon={<Delete />}>Delete</Button>,
                    </ButtonGroup>
                }

                return <></>
            },
        },
        {
            id: 1,
            bind: "name",
            label: "Name",

        },
        {
            id: 10,
            bind: "code",
            label: "Code",

        },
        {
            id: 2,
            bind: "description",
            label: "Description",
            renderRow: (value, row, cellIndex, rowIndex) => {
                if (!!value) {
                    return <div> {value} </div>
                }

                return <></>
            },
        }, {
            id: 3,
            bind: "icon",
            label: "Icon",
            renderRow: (value, row, cellIndex, rowIndex) => {
                if (!!value) {
                    return <i className={`fa fa-${value}`} />
                }

                return <></>
            },
        },
        {
            id: 4,
            bind: "commons",
            label: "Share to anyone",
            renderRow: (value, row, cellIndex, rowIndex) => {


                return <FormGroup>
                    <FormControlLabel control={<Switch color={value ? "success" : "error"} checked={value} onChange={(event, checked) => {

                    }} />} label={value ? "YES" : "NO"} />
                </FormGroup>
            },
        },
    ]

    function onAddCategory() {
        editDialgRef.current.clearFields();
        setCategory(undefined);
        setEditMode(false);
        setShowAddEditCategory(true);
    }

    function onEditCategory(category: CategoriesDto) {
        editDialgRef.current.setCategory(category);
        setCategory(category);
        editDialgRef.current.loadCategory(category.id);
        setEditMode(true);
        setShowAddEditCategory(true);
    }

    async function onDeleteCategory(category: CategoriesDto)  {
        setCategory(category);
        
        alertDialogRef.current.showConfirm("you are deleting the category "+category.name+". Are you sure?", "DELETE CATEGORY","No", "Yes");
    }

    async function onCloseAlertDialog(feedback: "close-button" | "confirm-button") {
        if(feedback === "confirm-button"){
            setLoading(true);

            try {
                const categoryService = new CategoryService();

                const resultDelete = await categoryService.delete(category.id);

                setLoading(false);

                if(resultDelete){
                    setCategory(undefined);
                    await loadCategories(search);

                    return;
                }
            } catch (error) {
                console.error(error);
            }
            setCategory(undefined);
            setLoading(false);
        } else {
            setCategory(undefined);
        }
    }

    function onCloseDialog(feedback) {
        setShowAddEditCategory(false);
        loadCategories(search);
    }
    return <>
        <Waiting opened={loading} message="Load categories" />
        <AlertDialog ref={alertDialogRef} onCloseDialog={onCloseAlertDialog} />
        <EditAddCategoryDialog ref={editDialgRef} show={showAddEditCayegory} category={category} edit={editMode} close={onCloseDialog} />
        <div className="w-full">
            <Paper elevation={4} sx={{ width: '100%', marginTop: "5px", padding: 2 }}>
                <div className="flex justify-between items-center">
                    <FormGroup>
                        <Search>
                            <SearchIconWrapper>
                                <SearchIcon />
                            </SearchIconWrapper>
                            <StyledInputBase onChange={(evn) =>{
                                setSearch(evn.target.value);
                                loadCategories(evn.target.value);
                            }}
                                value={search}
                                placeholder="Search…"
                                inputProps={{ 'aria-label': 'search' }}
                            />
                        </Search>
                    </FormGroup>
                    <Button size="small" color="primary" variant="outlined" onClick={onAddCategory} title="Add new category"> <Add /> Add </Button>
                </div>
            </Paper>
            <Suspense fallback={<Waiting opened={true} />}>
                <DataTable onChangePage={(_newPage)=>{
                    loadCategories(search,_newPage,pages.maxRowsPerPage)
                }} rows={pages.categories} columns={cols} maxRowsPerPage={pages.maxRowsPerPage} totalRows={pages.totalCategories} />
            </Suspense>

        </div></>

}