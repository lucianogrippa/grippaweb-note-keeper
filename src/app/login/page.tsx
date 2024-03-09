
"use client"
import LoginForm from "@/app/login/login-form";
import { Card, CardContent, CardHeader, Grid } from "@mui/material";

export default function LoginPage({
  searchParams
}) {

  return (
       <Grid
            container
            spacing={0}
            direction="column"
            alignItems="center"
            justifyContent="center"
            sx={{ minHeight: '100vh' }}
          >
            <Grid item xs={6} md={6}>
              <Card>
                <CardHeader title={"App Sign in"}> </CardHeader>
                <CardContent>
                  <LoginForm error={searchParams && searchParams.error} />
                </CardContent>
              </Card>
            </Grid>
          </Grid>
  );
}
