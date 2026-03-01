import { Injectable, signal } from '@angular/core';
import { Router } from '@angular/router';
import { BehaviorSubject, Observable } from 'rxjs';

export interface User {
  id: string;
  full_name: string;
  username: string;
  note_password?: string;
  master_password?: string;
  created_at: string;
  updated_at: string;
}

export interface SetupData {
  full_name: string;
  note_password: string;
  master_password: string;
}

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private currentUserSubject = new BehaviorSubject<User | null>(null);
  public currentUser$ = this.currentUserSubject.asObservable();
  
  // Signal for modern Angular reactive patterns
  isAuthenticated = signal<boolean>(false);
  currentUser = signal<User | null>(null);
  isFirstTimeSetup = signal<boolean>(true);

  constructor(private router: Router) {
    this.checkFirstTimeSetup();
  }

  private checkFirstTimeSetup(): void {
    const isSetup = localStorage.getItem('app_setup_completed');
    const storedUser = localStorage.getItem('currentUser');
    
    if (isSetup && storedUser) {
      const user = JSON.parse(storedUser);
      this.setCurrentUser(user);
      this.isFirstTimeSetup.set(false);
    } else {
      this.isFirstTimeSetup.set(true);
    }
  }

  setupFirstTime(setupData: SetupData): Observable<boolean> {
    return new Observable(observer => {
      // Simulate database setup
      setTimeout(() => {
        if (setupData.full_name && setupData.note_password && setupData.master_password) {
          const user: User = {
            id: this.generateId(),
            full_name: setupData.full_name,
            username: setupData.full_name.toLowerCase().replace(/\s+/g, '') + '@notekeeper.com',
            note_password: setupData.note_password,
            master_password: setupData.master_password,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          };
          
          // Store encrypted passwords (in real app, these would be properly hashed/encrypted)
          localStorage.setItem('master_password_hash', btoa(setupData.master_password));
          localStorage.setItem('note_password_hash', btoa(setupData.note_password));
          localStorage.setItem('currentUser', JSON.stringify(user));
          localStorage.setItem('app_setup_completed', 'true');
          
          this.setCurrentUser(user);
          this.isFirstTimeSetup.set(false);
          
          observer.next(true);
          observer.complete();
          
          this.router.navigate(['/dashboard']);
        } else {
          observer.next(false);
          observer.complete();
        }
      }, 1500); // Simulate setup time
    });
  }

  login(masterPassword: string): Observable<boolean> {
    return new Observable(observer => {
      // Simulate authentication
      setTimeout(() => {
        const storedHash = localStorage.getItem('master_password_hash');
        const storedUser = localStorage.getItem('currentUser');
        
        if (storedHash && storedUser && btoa(masterPassword) === storedHash) {
          const user = JSON.parse(storedUser);
          this.setCurrentUser(user);
          
          observer.next(true);
          observer.complete();
          
          this.router.navigate(['/dashboard']);
        } else {
          observer.next(false);
          observer.complete();
        }
      }, 1000);
    });
  }

  logout(): void {
    this.setCurrentUser(null);
    this.router.navigate(['/login']);
  }

  resetApp(): void {
    // Clear all data for complete reset
    localStorage.clear();
    this.setCurrentUser(null);
    this.isFirstTimeSetup.set(true);
    this.router.navigate(['/login']);
  }

  private generateId(): string {
    return Math.random().toString(36).substr(2, 16);
  }

  private setCurrentUser(user: User | null): void {
    this.currentUserSubject.next(user);
    this.currentUser.set(user);
    this.isAuthenticated.set(!!user);
  }

  getCurrentUser(): User | null {
    return this.currentUserSubject.value;
  }
}