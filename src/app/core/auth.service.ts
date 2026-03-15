import { Injectable, signal } from '@angular/core';
import { Router } from '@angular/router';
import { invoke } from '@tauri-apps/api/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { deleteUserProfile, getUserProfile, isDbExist, logout, resetSession as resetApp } from './api';
import { SetupData, User } from './models';


@Injectable({
  providedIn: 'root'
})
export class AuthService {
  

  // Signal for modern Angular reactive patterns
  isAuthenticated = signal<boolean>(false);
  currentUser = signal<User | null>(null);
  isFirstTimeSetup = signal<boolean>(true);
  currentUser$: Observable<User | null>;

  private currentUserSubject = new BehaviorSubject<User | null>(null);


  private readonly CURRENT_USER_KEY = 'ddb5d33487cfa1b425980a9b4b487985';
  private readonly LAST_LOGIN_KEY = 'f1e2d3c4b5a6978876543210fedcba98';
  private readonly SESSION_EXPIRY_KEY = 'a1b2c3d4e5f67890abcdef1234567890';
  private readonly MAX_SESSION_DURATION = 20 * 60 * 1000; // 20 minutes

  constructor(private router: Router) {
    this.checkFirstTimeSetup();
    this.currentUser$ = this.currentUserSubject.asObservable();
  }

  async checkAuthentication(): Promise<boolean> {
    const storedUser = localStorage.getItem(this.CURRENT_USER_KEY);
    const isSessionValid = this.validateSession();

    if (!isSessionValid) {
      this.isAuthenticated.set(false);
      this.logout();
      return false;
    }
    
    const user = this.parseStoredUser(storedUser);
    const dbUser = await this.loadUserProfile();
    if (user && dbUser && dbUser.full_name === user.full_name) {
      this.setCurrentUser(user);
      this.isAuthenticated.set(true);
    } else {
      this.setCurrentUser(null);
      localStorage.clear();
      this.isAuthenticated.set(false);
    }
    return this.isAuthenticated();
  }

  validateSession(): boolean {
    const lastLogin = localStorage.getItem(this.LAST_LOGIN_KEY);
    const sessionExpiry = localStorage.getItem(this.SESSION_EXPIRY_KEY);
    
    if (lastLogin && sessionExpiry) {
      const lastLoginTime = new Date(atob(lastLogin)).getTime();
      const expiryTime = new Date(atob(sessionExpiry)).getTime();
      const currentTime = Date.now();
      if (currentTime < expiryTime) {
        return true;
      }
    }
    return false;
  }

  setupFirstTime(setupData: SetupData): Observable<boolean> {
    return new Observable(observer => {
      if (setupData.full_name && setupData.note_password && setupData.master_password) {


        invoke("register", {
          fullName: setupData.full_name,
          notePassword: setupData.note_password,
          masterPassword: setupData.master_password
        }).then(() => {

          // retrive user profile after successful registration
          this.loadUserProfile().then((user) => {
            if (user) {
              this.setCurrentUser(user);
            }
            observer.next(true);
            observer.complete();
          });

        })
          .catch((error) => {
            observer.next(false);
            observer.complete();
          });



      } else {
        observer.next(false);
        observer.complete();
      }
    });
  }

  login(masterPassword: string): Observable<boolean> {
    return new Observable(observer => {

      // login function return string if error occurred or return null if login is successful, so we check if the result is truthy to determine if login failed or not
      invoke("login", { masterPassword: masterPassword }).then((result) => {
        if (result == null) {
          this.loadUserProfile().then((user) => {
            if (user) {
              this.setCurrentUser(user);
              localStorage.setItem(this.LAST_LOGIN_KEY, btoa(new Date().toISOString()));
              localStorage.setItem(this.SESSION_EXPIRY_KEY, btoa(new Date(Date.now() + this.MAX_SESSION_DURATION).toISOString())); // 20 minutes session expiry
            }
            observer.next(true);
            observer.complete();
          });

        } else {
          observer.next(false);
          observer.complete();
        }
      }).catch((error) => {
        observer.next(false);
        observer.complete();
      });

    });
  }

  async logout(): Promise<void> {

   
    await logout();
     this.isAuthenticated.set(false);
    this.setCurrentUser(null);
    this.router.navigate(['/login']);
  }

  async resetSession(): Promise<void> {
    // Clear all data for complete reset
    localStorage.clear();
    this.setCurrentUser(null);
    this.isFirstTimeSetup.set(true);

    await logout();
    this.router.navigate(['/login']);
  }

  async resetAccount() {
    await resetApp();
    await this.resetSession();
    
    // TODO: Reset db and all user data through Tauri command
  }



  async getCurrentUser(): Promise<User | null> {



    const storedUser = localStorage.getItem(this.CURRENT_USER_KEY);

    const user = this.parseStoredUser(storedUser);

    if (user) {

      const dbExists = await isDbExist() as boolean;

      if (!dbExists) {
        return this.resetCurrentUser();
      }

      if (!user.full_name || !user.created_at || !user.updated_at) {
        return this.resetCurrentUser();
      }

      return user;
    }

    const subjectValue = this.currentUserSubject.value;


    if (subjectValue) {
      return subjectValue;
    }
    return null;
  }

  async loadUserProfile(): Promise<User | null> {

    const profile = await getUserProfile();
    const createdUser = profile as User | null;
    if (createdUser) {

      this.setCurrentUser(createdUser);
      this.isFirstTimeSetup.set(false);

      return createdUser;
    } else {
      return null;
    }
  }

  private setCurrentUser(user: User | null): void {
    this.currentUserSubject.next(user);
    this.currentUser.set(user);
    this.isAuthenticated.set(!!user);

    localStorage.setItem(this.CURRENT_USER_KEY, btoa(JSON.stringify(user)));
  }

  private async checkFirstTimeSetup(): Promise<void> {

    const storedUser = localStorage.getItem(this.CURRENT_USER_KEY);

    if (await isDbExist() && !!storedUser) {
      const user = this.parseStoredUser(storedUser);
      if (user) {
        this.setCurrentUser(user);
        this.isFirstTimeSetup.set(false);
      } else {
        this.isFirstTimeSetup.set(true);
      }
    } else {
      this.isFirstTimeSetup.set(true);
    }
  }

  private parseStoredUser(storedUser: string | null): User | null {
    if (!storedUser || storedUser === 'null' || storedUser === 'undefined' || storedUser.trim() === '') {
      return null;
    }

    // Support both Base64-encoded JSON and plain JSON for backward compatibility.
    try {
      const decoded = atob(storedUser);
      const parsed = JSON.parse(decoded) as User | null;
      return parsed ?? null;
    } catch {
      try {
        const parsed = JSON.parse(storedUser) as User | null;
        return parsed ?? null;
      } catch {
        return null;
      }
    }
  }

  private resetCurrentUser() {
    localStorage.removeItem(this.CURRENT_USER_KEY);
    return null;
  }

}