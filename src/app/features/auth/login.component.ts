import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../core/auth.service';
import { isDbExist } from '../../core/api/profiles';
import { SetupData } from '../../core/models';
import { Notification } from '../../services/notification';
import { ask } from '@tauri-apps/plugin-dialog';
import { finalize } from 'rxjs';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './login.component.html',
  styleUrl: './login.component.css'
})
export class LoginComponent {
  private fb = inject(FormBuilder);
  private authService = inject(AuthService);
  private router = inject(Router);
  private notificationService = inject(Notification);

  setupForm: FormGroup;
  loginForm: FormGroup;
  isLoading = signal(false);
  error = signal('');
  showNotePassword = signal(false);
  showMasterPassword = signal(false);
  isFirstTimeSetup = signal(false);

  constructor() {
    this.checkFirstTimeSetup();

    // Setup form for first-time installation
    this.setupForm = this.fb.group({
      full_name: ['', [Validators.required, Validators.minLength(2)]],
      note_password: ['', [Validators.required, Validators.minLength(6)]],
      master_password: ['', [Validators.required, Validators.minLength(8)]],
      confirm_master_password: ['', [Validators.required]]
    }, { validators: this.passwordMatchValidator });

    // Login form for returning users
    this.loginForm = this.fb.group({
      master_password: ['', [Validators.required]]
    });
  }

  private async checkFirstTimeSetup(): Promise<void> {
    try {
      const dbExists = await isDbExist();
      const isFirstSetup = !dbExists;
      this.isFirstTimeSetup.set(isFirstSetup);
      this.authService.isFirstTimeSetup.set(isFirstSetup);
    } catch {
      this.isFirstTimeSetup.set(false);
      this.authService.isFirstTimeSetup.set(false);
    }
  }

  onSetupSubmit(): void {
    if (this.setupForm.valid) {
      this.isLoading.set(true);
      this.error.set('');

      const setupData: SetupData = {
        full_name: this.setupForm.value.full_name,
        note_password: this.setupForm.value.note_password,
        master_password: this.setupForm.value.master_password
      };

      this.authService.setupFirstTime(setupData)
        .pipe(finalize(() => this.isLoading.set(false)))
        .subscribe({
          next: (success) => {
            this.isLoading.set(false);
            if (!success) {
              this.error.set('Setup failed. Please try again.');
              this.notificationService.showNotification('Setup Failed', 'An error occurred during setup. Please try again.');
            }
            // navigate to home page after successful setup
            this.performLogin(setupData.master_password);
          },
          error: (err) => {
            this.isLoading.set(false);
            this.error.set('Setup failed. Please try again.');
            this.notificationService.showNotification('Setup Failed', 'An error occurred during setup. Please try again.');
          }
        });
    } else {
      this.markFormGroupTouched(this.setupForm);
    }
  }

  onLoginSubmit(): void {
    if (this.loginForm.valid) {
      this.isLoading.set(true);
      this.error.set('');

      const masterPassword = this.loginForm.value.master_password;

      this.performLogin(masterPassword);
    } else {
      this.markFormGroupTouched(this.loginForm);
    }
  }


  toggleNotePasswordVisibility(): void {
    this.showNotePassword.set(!this.showNotePassword());
  }

  toggleMasterPasswordVisibility(): void {
    this.showMasterPassword.set(!this.showMasterPassword());
  }

  passwordMatchValidator(form: FormGroup) {
    const password = form.get('master_password');
    const confirmPassword = form.get('confirm_master_password');

    if (password && confirmPassword && password.value !== confirmPassword.value) {
      confirmPassword.setErrors({ passwordMismatch: true });
      return { passwordMismatch: true };
    }

    return null;
  }

  getFieldError(formName: 'setup' | 'login', fieldName: string): string {
    const form = formName === 'setup' ? this.setupForm : this.loginForm;
    const field = form.get(fieldName);

    if (field?.touched && field?.errors) {
      if (field.errors['required']) {
        return `${this.getFieldDisplayName(fieldName)} is required`;
      }
      if (field.errors['minlength']) {
        return `${this.getFieldDisplayName(fieldName)} must be at least ${field.errors['minlength'].requiredLength} characters`;
      }
      if (field.errors['passwordMismatch']) {
        return 'Passwords do not match';
      }
    }
    return '';
  }



  async resetApp(): Promise<void> {
    const userConfirmed = await ask('This will reset the entire application and delete all data. Are you sure?', {
      title: 'Confirm Reset',
      kind: "warning",
      okLabel: "Yes",
      cancelLabel: "No"
    });

    if (userConfirmed) {
      await this.authService.resetAccount();
      // after resetting the account, we can show a notification to the user
      this.notificationService.showNotification('App Reset', 'The application has been reset successfully. Please set up your account again.');
      window.location.reload();
    }
  }

  private getFieldDisplayName(fieldName: string): string {
    const displayNames: { [key: string]: string } = {
      'full_name': 'Full name',
      'note_password': 'Note password',
      'master_password': 'Master password',
      'confirm_master_password': 'Password confirmation'
    };
    return displayNames[fieldName] || fieldName.replace('_', ' ');
  }


  private markFormGroupTouched(form: FormGroup): void {
    Object.keys(form.controls).forEach(key => {
      const control = form.get(key);
      control?.markAsTouched();
    });
  }
  private performLogin(masterPassword: any) {
    this.isLoading.set(true);
    this.error.set('');
    this.authService.login(masterPassword).subscribe({
      next: (result) => {

        this.isLoading.set(false);
        if (!result) {
          this.error.set('Invalid master password. Please try again.');
          this.notificationService.showNotification('Login Failed', 'Invalid master password. Please try again.');
          return;
        }

        // navigate to home page after successful login
        this.router.navigate(['/dashboard']);
      },
      error: (err) => {
        this.isLoading.set(false);
        this.error.set('Login failed. Please try again.');
        this.notificationService.showNotification('Login Failed', err.message || 'An error occurred during login. Please try again.');
      }
    });
  }

}