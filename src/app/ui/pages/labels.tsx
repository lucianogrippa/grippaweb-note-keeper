"use client"
import { Search, Add, Edit, Delete } from "@mui/icons-material";
import { Button, ButtonGroup, FormControlLabel, FormGroup, Paper, Switch } from "@mui/material";
import React, { createRef, Suspense, useCallback, useState } from "react";
import DataTable, { ColumnType } from "../data-table";
import SearchIcon from '@mui/icons-material/Search';
import AlertDialog from "../dialogs/alert-dialog";
import { Waiting } from "../waiting";
import { SearchIconWrapper, StyledInputBase } from "../theme";
import SecreatsDTO from "@/lib/models/secreats";


export type DashboardUiState = {
    items?: SecreatsDTO[],
    totalItems?: number,
    page?: number
    maxRowsPerPage?: number
}

export default function DashboardUI(props: any){

    const alertDialogRef = createRef<AlertDialog>();

    const [loading, setLoading] = useState(false);
    const [search, setSearch] = useState('');
    const [pages, setPages] = useState<DashboardUiState>({
        items: [],
        maxRowsPerPage: 50,
        page: 1,
        totalItems: 0

    });

    const loadItems = useCallback(async (_search= '', _page=1, _maxRows=50) => {

        setLoading(true);
      

        
        setLoading(false);
    },[setPages]);

    async function onCloseAlertDialog(feedback: "close-button" | "confirm-button") {
    }

    async function onAddItems(params:any) {
        
    }

    async function onEditItems(params:any) {
        
    }

    async function onDeleteItems(params:any) {
        
    }

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
                        <Button key="edit" onClick={onEditItems.bind(this, row)} color="secondary" startIcon={<Edit />} >Edit</Button>,
                        <Button key="delete" color="error" onClick={onDeleteItems.bind(this, row)} startIcon={<Delete />}>Delete</Button>,
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

    return <>
    <Waiting opened={loading} message="Load categories" />
    <AlertDialog ref={alertDialogRef} onCloseDialog={onCloseAlertDialog} />
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
                            loadItems(evn.target.value);
                        }}
                            value={search}
                            placeholder="Search…"
                            inputProps={{ 'aria-label': 'search' }}
                        />
                    </Search>
                </FormGroup>
                <Button size="small" color="primary" variant="outlined" onClick={onAddItems} title="Add new category"> <Add /> Add </Button>
            </div>
        </Paper>
        <Suspense fallback={<Waiting opened={true} />}>
            <DataTable onChangePage={(_newPage)=>{
                loadItems(search,_newPage,pages.maxRowsPerPage)
            }} rows={pages.items} columns={cols} maxRowsPerPage={pages.maxRowsPerPage} totalRows={pages.totalItems} />
        </Suspense>

    </div></>

}