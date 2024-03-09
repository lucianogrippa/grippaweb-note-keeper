"use client"
import {
    ExclamationCircleIcon,
} from '@heroicons/react/24/outline';
import { ArrowRightIcon } from '@heroicons/react/20/solid';
import { UIButton } from '@/app/ui/button';
import { useFormState, useFormStatus } from 'react-dom';
import { signin } from '@/app/actions/auth-actions';
import { useCallback, useEffect, useState } from 'react';
import { Box, CardActions, CardContent, FormControl, FormHelperText, Input, InputLabel } from '@mui/material';
import { Waiting } from '../ui/waiting';


export default function LoginForm({ error }) {

    const { pending } = useFormStatus();
    const [showWaiting, setShowWaiting] = useState(false);

    const [state, dispatch] = useFormState(signin, {
        errors: {
            email: [],
            password: [],
            status: []
        },
        message: error
    });

    if (pending) {
        setShowWaiting(false);
    }


    return (
        <>
        <Waiting opened={showWaiting || pending} />
        <form action={dispatch} noValidate autoComplete='off' className="w-full" >
            <CardContent>
                <Box className="w-full space-y-3">
                    <FormControl className='mb-2 w-full'>
                        <InputLabel
                            htmlFor="email"
                        >
                            Email
                        </InputLabel>
                        <Input
                            id="email"
                            type="email"
                            name="email"
                            aria-errormessage='email_error'
                            placeholder={"Enter your email address"}
                            required
                        />
                        <FormHelperText id="email_error" className='text-muted text-red-500 text-sm'>{state.errors && state.errors.email && (
                            state.errors.email.map((_item, _index) => {
                                return <p key={_index}>{_item}</p>
                            })
                        )
                        }</FormHelperText>
                    </FormControl>
                    <FormControl className='mb-2 w-full'>
                        <InputLabel
                            htmlFor="password"
                        >
                            Password
                        </InputLabel>
                        <Input
                            id="password"
                            type="password"
                            name="password"
                            placeholder="Enter password"
                            required
                        />
                    </FormControl>
                </Box>

                <div className="flex h-8 items-end space-x-1">
                    <div
                        className="flex h-8 items-end space-x-1"
                        aria-live="polite"
                        aria-atomic="true"
                    >
                        {state && state.message && (
                            <>
                                <ExclamationCircleIcon className="h-5 w-5 text-red-500" />
                                {state.message === "100" ? <p className="text-sm text-red-500">{"invalid username or password"}</p> :
                                    <p className="text-sm text-red-500">{state.message}</p>}
                            </>
                        )}
                    </div>
                </div>
            </CardContent>
            <CardActions>
                <LoginButton label={"Sign in"} errors={!!state && !!state.message} pending={pending}  />
            </CardActions>
        </form></>
    );
}

function LoginButton({ label, errors, pending }) {


    return (
        <UIButton type='submit' className="mt-4 w-full" enabled={!pending}>
            {label} <ArrowRightIcon className="ml-auto h-5 w-5 text-gray-50" />
        </UIButton>
    );
}