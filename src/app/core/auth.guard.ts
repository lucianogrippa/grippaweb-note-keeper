import { Injectable } from '@angular/core';
import { ActivatedRouteSnapshot, CanActivate, Router, RouterStateSnapshot } from '@angular/router';
import { AuthService } from './auth.service';
import { from, map, Observable } from 'rxjs';
import { getUserProfile } from './api';
import { User } from './models';

@Injectable({
  providedIn: 'root'
})
export class AuthGuard implements CanActivate {
  
  constructor(
    private auth: AuthService,
    private router: Router
  ) {}


  canActivate(route:ActivatedRouteSnapshot, state:RouterStateSnapshot):Observable<boolean>|boolean {
        return from(this.auth.checkAuthentication()).pipe(
          // If getUserProfile returns a user, allow access. Otherwise, redirect to login.
          map((result: boolean) => {
            if (result) {
              console.log('authenticated');
              return true;
            }
            console.log('not authenticated');
            this.router.navigateByUrl('/login');
            return false;
          })
        );
  }
}