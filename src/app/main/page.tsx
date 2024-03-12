

import { getSessionDataByToken } from "@/lib/auth/services/auth-service";
import UserKeysservice from "@/lib/services/userkey-service";
import CryptoJS from "crypto-js";
import '@/app/main/main.module.css';
import React from "react";
import { Button, Dialog, DialogActions, DialogContent, DialogContentText, DialogTitle, FormControl, Input, InputLabel } from "@mui/material";
import { createPwd } from "./main-actions";
import MainAppPage from "./MainApp";
import { cookies } from "next/headers";
import { getTokenFromCookieObjct } from "@/lib/auth/services/token-check";


export default async function MainPage() {

    const cookie = cookies();

    const sessionFromCookie = await getTokenFromCookieObjct(cookie);

    const cssProperty = { justifyContent: "center", alignItems: "center", height: "100vh" }

    // verifica se necessario effettuare la creazione delle credenziali
    const token = sessionFromCookie;

    if (!!token) {
        const sessionData = await getSessionDataByToken(token);

        if (!!sessionData && !!sessionData.data) {
            // ottieni le chiavi
            const userKeysService = new UserKeysservice(CryptoJS.SHA256((sessionData.data as any).userData.username).toString());
            const key = await userKeysService.findKey();
            if (!key) {
                return <div style={cssProperty} className="flex">
                    <Dialog
                        open={true}
                        aria-labelledby="password-choose-title"
                    >
                        <DialogTitle  id="password-choose-title">
                            Choose password for key keeper
                        </DialogTitle>
                        <form action={createPwd.bind(this,token)}>
                            <DialogContent>
                                <DialogContentText>
                                    <FormControl  className='mb-2 w-full'>
                                        <InputLabel
                                            htmlFor="txtPwd"
                                        >
                                            Password
                                        </InputLabel>
                                        <Input
                                            id="txtPwd"
                                            type="password"
                                            name="txtPwd"
                                            autoComplete="off"
                                            placeholder={"Enter strong password for key keeper"}
                                            required
                                        />
                                        </FormControl>
                                </DialogContentText>
                            </DialogContent>
                            <DialogActions>
                                <Button title="create first time password" type="submit" variant="contained" color="primary">Create</Button>
                            </DialogActions>
                        </form>
                    </Dialog>
                </div>
            }
        }
    }

    

    return <MainAppPage />
} 