import { Component, computed, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../../core/auth.service';
import { ThemeService, Theme } from '../../core/theme.service';
import { NavbarComponent } from '../../shared/components/navbar/navbar.component';
import { ask, confirm, open } from '@tauri-apps/plugin-dialog';
import { Notification } from '../../services/notification';
import { Spinner } from '../../shared/services/spinner';
import { updateUserProfile } from '../../core/api/profiles';
import { finalize, from } from 'rxjs';

@Component({
  selector: 'app-profile',
  standalone: true,
  imports: [CommonModule, NavbarComponent, FormsModule],
  templateUrl: './profile.component.html',
  styleUrl: './profile.component.css'
})
export class ProfileComponent implements OnInit {
  private authService = inject(AuthService);
  public themeService = inject(ThemeService);
  private notificationService = inject(Notification);
  private router = inject(Router);
  private readonly spinner= inject(Spinner);

  currentUser = computed(() => this.authService.currentUser());

  // UI state
  isLoaded = signal(false);
  isEditing = signal(false);
  isSaving = signal(false);
  showPasswordChange = signal(false);

  // Form state
  profileForm = signal({
    full_name: '',
    note_password: '',
    master_password: ''
  });

  passwordForm = signal({
    current_password: '',
    new_password: '',
    confirm_password: ''
  });

  // Settings state
  settings = signal({
    auto_encrypt: false,
    auto_save_interval: 30,
    theme: this.themeService.currentTheme() as string,
    backup_enabled: true
  });

  ngOnInit(): void {
    const user = this.currentUser();
    if (user) {
      this.profileForm.set({
        full_name: user.full_name || '',
        note_password: user.note_password || '',
        master_password: user.master_password || ''
      });
    }

    setTimeout(() => {
      this.isLoaded.set(true);
    }, 100);
  }

  updateFullName(event: Event): void {
    const target = event.target as HTMLInputElement;
    this.profileForm.update(current => ({
      ...current,
      full_name: target.value
    }));
  }

  updateNotePassword(event: Event): void {
    const target = event.target as HTMLInputElement;
    this.profileForm.update(current => ({
      ...current,
      note_password: target.value
    }));
  }

  updateMasterPassword(event: Event): void {
    const target = event.target as HTMLInputElement;
    this.profileForm.update(current => ({
      ...current,
      master_password: target.value
    }));
  }

  updateCurrentPassword(event: Event): void {
    const target = event.target as HTMLInputElement;
    this.passwordForm.update(current => ({
      ...current,
      current_password: target.value
    }));
  }

  updateNewPassword(event: Event): void {
    const target = event.target as HTMLInputElement;
    this.passwordForm.update(current => ({
      ...current,
      new_password: target.value
    }));
  }

  updateConfirmPassword(event: Event): void {
    const target = event.target as HTMLInputElement;
    this.passwordForm.update(current => ({
      ...current,
      confirm_password: target.value
    }));
  }

  toggleAutoEncrypt(): void {
    this.settings.update(current => ({
      ...current,
      auto_encrypt: !current.auto_encrypt
    }));
  }

  toggleBackupEnabled(): void {
    this.settings.update(current => ({
      ...current,
      backup_enabled: !current.backup_enabled
    }));
  }

  updateAutoSaveInterval(event: Event): void {
    const target = event.target as HTMLSelectElement;
    this.settings.update(current => ({
      ...current,
      auto_save_interval: parseInt(target.value, 10)
    }));
  }

  updateTheme(event: Event): void {
    const target = event.target as HTMLSelectElement;
    const newTheme = target.value as Theme;
    this.themeService.setTheme(newTheme);
    this.settings.update(current => ({
      ...current,
      theme: newTheme
    }));
  }

  startEditing(): void {
    this.isEditing.set(true);
  }

  cancelEditing(): void {
    this.isEditing.set(false);
    // Reset form to original values
    const user = this.currentUser();
    if (user) {
      this.profileForm.set({
        full_name: user.full_name || '',
        note_password: user.note_password || '',
        master_password: user.master_password || ''
      });
    }
  }

  saveProfile(): void {
    const form = this.profileForm();
    if (!form.full_name.trim()) {
      alert('Full name is required');
      return;
    }

    this.spinner.show();
    this.isSaving.set(true);

    from(updateUserProfile(form.full_name))
    .pipe(finalize(() => {
      this.spinner.hide();
    }))
    .subscribe({
      next: (updatedUser) => {
        this.notificationService.showNotification('Profile Updated', 'Your profile has been updated successfully.');
        this.isEditing.set(false);
        this.isSaving.set(false);
      },
      error: (error) => {
        console.error('Error updating profile:', error);
        alert('Failed to update profile. Please try again.');
        this.isSaving.set(false);
      }
    });
  }

  changePassword(): void {
    const form = this.passwordForm();

    if (!form.current_password || !form.new_password || !form.confirm_password) {
      alert('All password fields are required');
      return;
    }

    if (form.new_password !== form.confirm_password) {
      alert('New passwords do not match');
      return;
    }

    if (form.new_password.length < 6) {
      alert('New password must be at least 6 characters');
      return;
    }

    this.isSaving.set(true);

    // Here you would integrate with your auth service to change password
    setTimeout(() => {
      console.log('Password changed');
      this.showPasswordChange.set(false);
      this.passwordForm.set({
        current_password: '',
        new_password: '',
        confirm_password: ''
      });
      this.isSaving.set(false);
    }, 1000);
  }

  exportData(): void {
    // Simulate data export
    const data = {
      user: this.currentUser(),
      settings: this.settings(),
      export_date: new Date().toISOString()
    };

    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `notekeeper-backup-${new Date().toISOString().split('T')[0]}.json`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }

  async logout(): Promise<void> {
    if (await confirm('Are you sure you want to logout?')) {
      this.authService.logout();
    }
  }

  async deleteAccount(): Promise<void> {
    const confirmation = prompt('Type "DELETE" to confirm account deletion:');
    if (confirmation === 'DELETE') {
      const finalConfirmation = await ask('This will reset the entire application and delete all data. Are you sure?', {
        title: 'Confirm Reset',
        kind: "warning",
        okLabel: "Yes",
        cancelLabel: "No"
      });
      if (finalConfirmation) {
        // Here you would integrate with your auth service to delete the account
        await this.authService.resetAccount();
      
        // after resetting the account, we can show a notification to the user
        this.notificationService.showNotification('App Reset', 'The application has been reset successfully. Please set up your account again.');
        window.location.reload();
      }
    }
  }
}