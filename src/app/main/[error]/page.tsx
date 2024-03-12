import { ButtonBack } from "@/app/ui/button";
import { NavigateBefore } from "@mui/icons-material";
import { Button, Dialog, DialogActions, DialogContent, DialogContentText, DialogTitle, FormControl, Input, InputLabel, Typography } from "@mui/material";

export default async function ErrorCode({ searchParams, params }) {

    const cssProperty = { justifyContent: "center", alignItems: "center", height: "100vh" }
    const { error } = params;

    const renderErrorMessage = (_error) => {

        switch (Number(_error)) {
            case 100:

                return <Typography>
                    Cant&quote;; t save the selected key
                </Typography>

            case 101:
                // password not match th policy
                return <Typography>
                    The password not match minimum security policy:
                    <ul>
                        <li> min 6 chars length </li>
                        <li> at least 1 numeric chars </li>
                        <li> at least 1 uppercase chars </li>
                        <li> at least 1 lowercase chars </li>
                        <li> at least 1 special char ($!_-@) chars </li>
                    </ul>
                </Typography>
            default:
                return <Typography>
                    Generic Error
                </Typography>
        }

    }

    return <div style={cssProperty} className="flex">
        <Dialog
            open={true}
            aria-labelledby="password-choose-title"
        >
            <DialogTitle id="password-choose-title">
                Error occurred
            </DialogTitle>
            <DialogContent>
                <DialogContentText>
                    {renderErrorMessage(error)}
                </DialogContentText>
            </DialogContent>
            <DialogActions>
                <ButtonBack label="Go Back"/>
            </DialogActions>
        </Dialog>
    </div>


}


