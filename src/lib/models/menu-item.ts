
type MenuItem = {
    name: string,
    path: string
    tooltip: string
}

export const menuItems: MenuItem[] = [
    {
        name: 'Dashboard',
        path: '/ebm/dashboard',
        tooltip: 'show dashboard of situation of expenses and income'
    },
    {
        name: 'Exprenses',
        path: '/ebm/expenses',
        tooltip: 'Manage expenses'
    },
    {
        name: 'Incomes',
        path: '/ebm/incomes',
        tooltip: 'Manage incomes'
    },
    {
        name: 'Categories',
        path: '/ebm/categories',
        tooltip: 'Manage categories of expenses or incomes'
    },

    {
        name: 'Accounts',
        path: '/ebm/accounts',
        tooltip: 'Manage source accounts responsible of expreses or income'
    },

    {
        name: 'Payments status',
        path: '/ebm/status',
        tooltip: 'Manage payments status list'
    },
]