import { Button, Dialog, DialogActions, DialogContent, DialogTitle, Typography } from "@mui/material";
import React from "react";

type AlertDialogProps = {

    onCloseDialog?: (feedback?: "close-button" | "confirm-button") => void

}

type AlertDialogState = {
    title?: string
    confirm?: boolean
    closeLabel?: string
    confirmLabel?: string
    message?: string
    show?: boolean
}

export default class AlertDialog extends React.Component<AlertDialogProps, AlertDialogState> {

    state: Readonly<AlertDialogState> = {
        show: false,
        title: "Message",
        confirm: false,
    };


    showAlert(message: string,title?: string, closeLabel?: string) {
        this.setState({
          show: true,  message, title, closeLabel
        })
    }

    showConfirm(message: string,title?: string, closeLabel?: string, confirmLabel?: string){
        this.setState({
            show: true, confirm: true, message, title, closeLabel, confirmLabel
        })
    }

    close(feedback?: "close-button" | "confirm-button") {
        this.setState({show: false});
        this.props.onCloseDialog ? this.props.onCloseDialog(feedback) : null
    }

    render(): React.ReactNode {
        return <Dialog
            open={this.state.show}
            onClose={() => {
                if (this.props.onCloseDialog) {
                    this.props.onCloseDialog();
                }
            }}
            aria-labelledby="alert-dialog-title"
        >
            <DialogTitle id="alert-dialog-title">
                {this.state.title ?? "Message"}
            </DialogTitle>
            <DialogContent>
                <Typography>{this.state.message ?? ""}</Typography>
            </DialogContent>
            <DialogActions>
                <Button color="secondary" variant="outlined" onClick={() => this.close("close-button")}>  {this.state.closeLabel ?? "Close"} </Button>
                {this.state.confirm ? <Button color="primary" variant="outlined" onClick={() => this.close("confirm-button")}> {this.state.confirmLabel ?? "Confirm"}</Button> : null}
            </DialogActions>
        </Dialog>
    }
}