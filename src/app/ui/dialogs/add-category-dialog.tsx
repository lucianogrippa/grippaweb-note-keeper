"use client"

import CategoriesDto from "@/lib/models/categories";
import CategoryService from "@/lib/services/category-service";
import { Button, Dialog, DialogActions, DialogContent, DialogTitle, FormControlLabel, FormGroup, Switch, TextField } from "@mui/material";
import React from "react";
import { Waiting } from "../waiting";

type EditAddCategoryDialogProps = {
    show: boolean
    edit: boolean
    category?: CategoriesDto
    close: (feedback: string, data?: CategoriesDto) => void
}

type EditAddCategoryDialogState = {
    loading: boolean,
    category?: CategoriesDto
}

export default class EditAddCategoryDialog extends React.Component<EditAddCategoryDialogProps> {

    state: Readonly<EditAddCategoryDialogState> = {
        loading: false,
        category: {
            code: '',
            commons: false,
            description: '',
            icon: '',
            id: 0,
            name: ''
        }
    };

    async loadCategory(_id: number): Promise<void>{
        this.setState({loading: true});
        const categoryService = new CategoryService();

        const category = await categoryService.findById(_id);

        if(!!category){
            this.setState({ 
                category
            });
        }

        this.setState({loading: false});
    }
    setCategory(category: CategoriesDto) {
        this.setState({category});
    }
    clearFields () {
        const {category} = this.state;

        category.id = 0;
        category.code="";
        category.name="";
        category.description="";
        category.icon="";
        category.commons=false;

        this.setState({
            category
        })
    }
    onSaveData() {

    }

    render(): React.ReactNode {
        return <>
        <Waiting opened={this.state.loading} message="Load categories" />
        <Dialog
            fullWidth
            onClose={() =>{ 
                this.clearFields();
                this.props.close && this.props.close("close-button");
            }}
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
                            let { category } = this.state;
                            if (!category) {
                                category = {} as CategoriesDto;
                            }
                            category.name = event.target.value;
                            this.setState({ category });
                        }} value={this.state.category?.name} />
                    </FormGroup>
                    <FormGroup>
                        <TextField label="Code" onChange={(event) => {
                             let { category } = this.state;
                             if (!category) {
                                 category = {} as CategoriesDto;
                             }
                            category.code = event.target.value;
                            this.setState({ category });
                        }} value={this.state.category?.code} />
                    </FormGroup>
                    <FormGroup>
                        <TextField onChange={(event)=>{
                             let { category } = this.state;
                             if (!category) {
                                 category = {} as CategoriesDto;
                             }

                             category.description = event.target.value;
                             this.setState({category});

                        }} label="Description" value={this.state.category?.description} />
                    </FormGroup>
                    <FormGroup>
                        <TextField onChange={(event)=>{
                             let { category } = this.state;
                             if (!category) {
                                 category = {} as CategoriesDto;
                             }
                             category.icon = event.target.value;
                             this.setState({category});

                        }} label="Icon" value={this.state.category?.icon} />
                    </FormGroup>
                    <FormGroup>
                        <FormControlLabel control={<Switch color={this.state.category?.commons  ? "success" : "error"} checked={this.state.category?.commons } onChange={(event, checked) => {
                             let { category } = this.state;
                             if (!category) {
                                 category = {} as CategoriesDto;
                             }
                            category.commons = checked;
                            this.setState({ category });
                        }} />} label={this.state.category?.commons ? "YES SHARE" : "NO SHARE"} />
                    </FormGroup>
                </div>
            </DialogContent>
            <DialogActions>
                <Button color="secondary" variant="outlined" onClick={() => this.props.close("close-button")}> Close</Button>
                <Button color="primary" variant="outlined" onClick={this.onSaveData.bind(this)}> Save</Button>
            </DialogActions>
        </Dialog></> 
    }
}