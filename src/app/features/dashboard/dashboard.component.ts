import { Component, computed, inject, signal, OnInit, effect } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { combineLatest, of } from 'rxjs';
import { map, switchMap } from 'rxjs/operators';
import { AuthService } from '../../core/auth.service';
import { DataService, Category } from '../../core/data.service';
import { NavbarComponent } from '../../shared/components/navbar/navbar.component';
import { EditCategoryForm } from '../edit-category-form/edit-category-form';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, NavbarComponent, FormsModule, EditCategoryForm],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.css'
})
export class DashboardComponent implements OnInit {

  private authService = inject(AuthService);
  private dataService = inject(DataService);
  private router = inject(Router);

  currentUser = computed(() => this.authService.currentUser());
  categories = computed(() => this.dataService.categories());
  noteCount = signal(0);
  // UI state
  isLoaded = signal(false);
  showCreateForm = signal(false);
  categoryId = signal<string | null>(null);
  
  // Form state  
  newCategory = signal({
    name: '',
    description: '',
    userId: this.currentUser()?.id || ''
  });

  ngOnInit(): void {
    // Trigger animation after small delay
    setTimeout(() => {
      this.isLoaded.set(true);
    }, 100);
  }

  getGreeting(): string {
    const hour = new Date().getHours();
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  currentTime(): Date {
    return new Date();
  }


  formatDate(date: string): string {
    const now = new Date();
    const noteDate = new Date(date);
    const diffTime = now.getTime() - noteDate.getTime();
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
    
    if (diffDays === 0) return 'Today';
    if (diffDays === 1) return 'Yesterday';
    if (diffDays < 7) return `${diffDays} days ago`;
    return noteDate.toLocaleDateString();
  }

  viewCategory(categoryId: string): void {
    this.router.navigate(['/category', categoryId]);
  }


  handleCancelEdit(): void {
    this.categoryId.set(null);
    this.showCreateForm.set(false);
    this.newCategory.set({ name: '', description: '', userId: this.currentUser()?.id || '' });
  }

  handleFormSaved(saved: boolean): void {
    if (saved) {
      this.categoryId.set(null);
      this.showCreateForm.set(false);
      this.newCategory.set({ name: '', description: '', userId: this.currentUser()?.id || '' });
      this.dataService.loadCategories();
    }
  }

  editCategory(category: Category): void {
    this.categoryId.set(category.id || null);
    this.newCategory.set({ name: category.name, description: category.description || '', userId: this.currentUser()?.id || '' });
    this.showCreateForm.set(true);
    this.dataService.loadCategories();
  }
  addCategory(): void {
    this.categoryId.set(null);
    this.newCategory.set({ name: '', description: '', userId: this.currentUser()?.id || '' });
    this.showCreateForm.set(true);
    this.dataService.loadCategories();
  }

  deleteCategory(categoryId: string): void {
    const category = this.categories().find(c => c.id === categoryId);
    const categoryName = category?.name || 'this category';
    
    if (confirm(`Are you sure you want to delete "${categoryName}" and all its groups and notes?`)) {
      this.dataService.deleteCategory(categoryId).subscribe({
        next: () => {
          console.log('Category deleted successfully');
        },
        error: (error) => {
          console.error('Error deleting category:', error);
        }
      });
    }
  }

  getCategoryColor(index: number): string {
    const colors = [
      '#667eea', '#f093fb', '#48cae4', '#06ffa5', 
      '#ffd23f', '#ff6b6b', '#4ecdc4', '#a8e6cf'
    ];
    return colors[index % colors.length];
  }

  logout(): void {
    this.authService.logout();
  }
}