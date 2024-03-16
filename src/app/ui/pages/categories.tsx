"use client"
import CategoriesDto from "@/lib/models/categories";
import React, { useState } from "react";
import DataTable, { ColumnType } from "../data-table";
import { Button, ButtonGroup, FormControlLabel, FormGroup, Icon, InputBase, Paper, Switch, alpha, styled } from "@mui/material";
import { Add, Delete, Edit } from "@mui/icons-material";
import SearchIcon from '@mui/icons-material/Search';
import EditAddCategoryDialog from "../dialogs/add-category-dialog";

export type CategoryUiType = {
    categories: CategoriesDto[],
    totalCategories: number,
    page: number
    maxRowsPerPage: number
}

const Search = styled('div')(({ theme }) => ({
    position: 'relative',
    borderRadius: theme.shape.borderRadius,
    backgroundColor: alpha(theme.palette.common.white, 0.15),
    '&:hover': {
        backgroundColor: alpha(theme.palette.common.white, 0.25),
    },
    marginLeft: 0,
    width: '100%',
    [theme.breakpoints.up('sm')]: {
        marginLeft: theme.spacing(1),
        width: 'auto',
    },
}));


const SearchIconWrapper = styled('div')(({ theme }) => ({
    padding: theme.spacing(0, 2),
    height: '100%',
    position: 'absolute',
    pointerEvents: 'none',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
}));

const StyledInputBase = styled(InputBase)(({ theme }) => ({
    color: 'inherit',
    width: '100%',
    '& .MuiInputBase-input': {
        padding: theme.spacing(1, 1, 1, 0),
        // vertical padding + font size from searchIcon
        paddingLeft: `calc(1em + ${theme.spacing(4)})`,
        transition: theme.transitions.create('width'),
        [theme.breakpoints.up('sm')]: {
            width: '12ch',
            '&:focus': {
                width: '20ch',
            },
        },
    },
}));

export default function CategoriesUI(props: CategoryUiType) {

    const [showAddEditCayegory , setShowAddEditCategory] = useState(false);
    const [editMode, setEditMode] = useState(true);
    const [category, setCategory] = useState<CategoriesDto>()

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
                        <Button key="edit" onClick={onEditCategory.bind(this,row)} color="secondary" startIcon={<Edit />} >Edit</Button>,
                        <Button key="delete" color="error" startIcon={<Delete />}>Delete</Button>,
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
        setCategory(undefined);
        setEditMode(false);
        setShowAddEditCategory(true);
    }

    function onEditCategory(category:CategoriesDto) {
        setCategory(category);
        setEditMode(true);
        setShowAddEditCategory(true);
    }

    function onCloseDialog(feedback) {
        setShowAddEditCategory(false);
    }
    return <>
    <EditAddCategoryDialog show={showAddEditCayegory} category={category} edit={editMode}  close={onCloseDialog}/>
    <div className="w-full">
        <Paper elevation={4} sx={{ width: '100%', marginTop: "5px", padding: 2 }}>
            <div className="flex justify-between items-center">
                <FormGroup>
                    <Search>
                        <SearchIconWrapper>
                            <SearchIcon />
                        </SearchIconWrapper>
                        <StyledInputBase
                            placeholder="Search…"
                            inputProps={{ 'aria-label': 'search' }}
                        />
                    </Search>
                </FormGroup>
                <Button size="small" color="primary" variant="outlined" onClick={onAddCategory} title="Add new category"> <Add /> Add </Button>
            </div>
        </Paper>
        <DataTable rows={props.categories} columns={cols} maxRowsPerPage={props.maxRowsPerPage} totalRows={props.totalCategories} />

    </div></>

}