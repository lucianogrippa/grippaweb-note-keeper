"use client"
import { Backdrop, Box, CircularProgress, Typography } from "@mui/material";
import { useState } from "react";

type WaitingType = {
  opened: boolean;
  message?: string
}

export function Waiting({ opened, message }: WaitingType) {

  const [open, setOpen] = useState(opened);

  const handleClose = () => {
    setOpen(!open);
  }

  return <Backdrop
    sx={{ color: '#fff', position: "absolute", zIndex: (theme) => theme.zIndex.drawer + 1 }}
    open={open}
    onClick={handleClose}
  >
    <CircularProgress color="inherit" />
    <Box sx={{ display: { md: "block", sm: "none", xs: "none" }, margin: { md: 5} }}>
      <Typography fontSize={15} component="div" fontStyle="italic">
        {message ?? ""}
      </Typography>
    </Box>
  </Backdrop>
}