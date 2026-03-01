import { Routes } from "@angular/router";
import { AuthGuard } from "./core/auth.guard";

export const routes: Routes = [
  {
    path: '',
    redirectTo: '/dashboard',
    pathMatch: 'full'
  },
  {
    path: 'login',
    loadComponent: () => import('./features/auth/login.component').then(m => m.LoginComponent)
  },
  {
    path: 'dashboard',
    loadComponent: () => import('./features/dashboard/dashboard.component').then(m => m.DashboardComponent),
    canActivate: [AuthGuard]
  },
  {
    path: 'category/:id',
    loadComponent: () => import('./features/categories/category-detail.component').then(m => m.CategoryDetailComponent),
    canActivate: [AuthGuard]
  },
  {
    path: 'group/:id',
    loadComponent: () => import('./features/groups/group-detail.component').then(m => m.GroupDetailComponent),
    canActivate: [AuthGuard]
  },
  {
    path: 'note/:id',
    loadComponent: () => import('./features/notes/note-editor.component').then(m => m.NoteEditorComponent),
    canActivate: [AuthGuard]
  },
  {
    path: 'note/new/:groupId',
    loadComponent: () => import('./features/notes/note-editor.component').then(m => m.NoteEditorComponent),
    canActivate: [AuthGuard]
  },
  {
    path: 'profile',
    loadComponent: () => import('./features/profile/profile.component').then(m => m.ProfileComponent),
    canActivate: [AuthGuard]
  },
  {
    path: '**',
    redirectTo: '/dashboard'
  }
];
