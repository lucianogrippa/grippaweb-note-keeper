import clsx from 'clsx';
import Button from '@mui/material/Button';
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
    children: React.ReactNode;
    size?: "small" | "large" | "medium";
    block?: boolean;
    className?: string;
    type?: "button" | "submit" | "reset";
    enabled?: boolean;
    onClick?:(event?: any)=>void;
}

export function UIButton({ children, size, block, className, type,enabled,onClick}: ButtonProps) {
    return (
        <Button
            disabled={!enabled}
            type={type??"button"}
            variant='contained'
            size={size || "large"}
            onClick={onClick}
            className={clsx(block ? "w-full min-w-full": "", className??"" )}
        >
            {children}
        </Button>
    );
}