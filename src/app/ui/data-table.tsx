import { Paper, Table, TableHead, TableRow, TableCell, TableBody, TablePagination, Typography, Box } from "@mui/material";
import React from "react";


export type ColumnType = {
    // id univoco della colonna
    id: number,
    // nome del campo su cui fa il bind con i dati
    bind: string,
    label: string,
    minWidth?: number,
    maxWidth?:number,
    align?: 'left' | 'right' | 'center',
    renderRow?: (value: any, row: any, cellIndex: number, rowIndex: number) => React.JSX.Element,
}

type DataTableProps = {
    columns: ColumnType[],
    rows?: any[],
    totalRows?: number,
    maxRowsPerPage?: number,
    onRowClick?: (rowValue: any) => void
}


export default function DataTable({ columns, rows, totalRows, maxRowsPerPage, onRowClick }: DataTableProps) {
    const [page, setPage] = React.useState(0);
    const [rowsPerPage, setRowsPerPage] = React.useState(maxRowsPerPage);

    if (totalRows === undefined) {
        totalRows = rows?.length || 0
    }

    if (rows === undefined) {
        rows = [];
    }

    const handleChangePage = (event: any, newPage: number) => {
        setPage(newPage);
    };

    const handleChangeRowsPerPage = (event) => {
        setRowsPerPage(+event.target.value);
        setPage(0);
    };

    return (
        <Paper elevation={4} sx={{ width: '100%' , marginTop: "5px"}}>
     
                <Table stickyHeader aria-label="sticky table">
                    <TableHead>
                        <TableRow>
                            {columns.map((column, _idx) => (
                                <TableCell
                                    key={column.id || _idx}
                                    align={column.align}
                                    style={{ top: 57, minWidth: column.minWidth, maxWidth: column.maxWidth }}
                                >
                                    {column.label}
                                </TableCell>
                            ))}
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {rows.map((row, index) => {
                            return (
                                <TableRow  hover onClick={onRowClick?.bind(this, row)} key={index}>
                                    {columns.map((column, _idx) => {
                                        const value = row[column.bind];
                                        return (
                                            <TableCell key={column.id || _idx} align={column.align}>
                                                {column.renderRow ? column.renderRow(value, row, _idx,index) : <div> {`${value}`} </div>}
                                            </TableCell>
                                        );
                                    })}
                                </TableRow>
                            );
                        })}
                    </TableBody>
                </Table>
            {totalRows > 0 ?
                <TablePagination
                    rowsPerPageOptions={[10, 25, 100]}
                    component="div"
                    count={totalRows}
                    rowsPerPage={rowsPerPage}
                    page={page}
                    onPageChange={handleChangePage}
                    onRowsPerPageChange={handleChangeRowsPerPage}
                /> : 
                <Box sx={{display: "flex" , flexGrow: 1, textAlign: "center", flexDirection: "row", alignItems: "center", justifyContent: "center"}}>
                    <Typography> No results found</Typography>
                </Box>}
        </Paper>
    );
}