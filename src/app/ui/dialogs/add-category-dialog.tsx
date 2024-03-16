"use client"

import CategoriesDto from "@/lib/models/categories";
import { Button, Dialog, DialogActions, DialogContent, DialogContentText, DialogTitle, FormControlLabel, FormGroup, Switch, TextField } from "@mui/material";
import React from "react";

type EditAddCategoryDialogProps = {
    show: boolean
    edit: boolean
    category?: CategoriesDto
    close: (feedback: string, data?: CategoriesDto) => void
}

type EditAddCategoryDialogState = {
    category?: CategoriesDto
}

export default class EditAddCategoryDialog extends React.Component<EditAddCategoryDialogProps> {

    state: Readonly<EditAddCategoryDialogState> = {
        category: {
            code: '',
            commons: false,
            description: '',
            icon: '',
            id: 0,
            name: ''
        }
    };

    onSaveData() {

    }

    render(): React.ReactNode {
        return <Dialog
            fullWidth
            open={this.props.show}
            aria-labelledby="password-choose-title"
        >
            <DialogTitle id="password-choose-title">
                {this.props.edit ? "Edit Category" : "Add new Category"}
            </DialogTitle>
            <DialogContent>
                <div className="flex flex-grow justify-around flex-col gap-4">
                    <FormGroup>
                        <TextField label="Name" onChange={(event) => {
                            let { category } = this.props;
                            if (!category) {
                                category = this.state.category;
                            }
                            category.name = event.target.value;
                            this.setState({ category });
                        }} value={this.state.category?.name || this.props.category?.name} />
                    </FormGroup>
                    <FormGroup>
                        <TextField label="Code" onChange={(event) => {
                            let { category } = this.props;
                            if (!category) {
                                category = this.state.category;
                            }
                            category.code = event.target.value;
                            this.setState({ category });
                        }} value={this.state.category?.code || this.props.category?.code} />
                    </FormGroup>
                    <FormGroup>
                        <TextField label="Description" value={this.state.category?.description || this.props.category?.description} />
                    </FormGroup>
                    <FormGroup>
                        <TextField label="Icon" value={this.state.category?.icon || this.props.category?.icon} />
                    </FormGroup>
                    <FormGroup>
                        <FormControlLabel control={<Switch color={this.state.category?.commons || this.props.category?.commons ? "success" : "error"} checked={this.state.category?.commons || this.props.category?.commons} onChange={(event, checked) => {
                            let { category } = this.props;
                            if (!category) {
                                category = this.state.category;
                            }
                            category.commons = checked;
                            this.setState({ category });
                        }} />} label={this.state.category?.commons || this.props.category?.commons ? "YES SHARE" : "NO SHARE"} />
                    </FormGroup>
                </div>
            </DialogContent>
            <DialogActions>
                <Button color="secondary" variant="outlined" onClick={() => this.props.close("close-button")}> Close</Button>
                <Button color="primary" variant="outlined" onClick={this.onSaveData.bind(this)}> Save</Button>
            </DialogActions>
        </Dialog>
    }
}