import { Component, computed, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../../core/auth.service';
import { DataService, Category } from '../../core/data.service';
import { NavbarComponent } from '../../shared/components/navbar/navbar.component';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, NavbarComponent, FormsModule],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.css'
})
export class DashboardComponent implements OnInit {
  private authService = inject(AuthService);
  private dataService = inject(DataService);
  private router = inject(Router);

  currentUser = computed(() => this.authService.currentUser());
  categories = computed(() => this.dataService.categories());
  
  // UI state
  isLoaded = signal(false);
  showCreateForm = signal(false);
  isEditingCategory = signal<string | null>(null);
  
  // Form state  
  newCategory = signal({
    name: '',
    description: ''
  });
  editCategoryName = signal('');
  editCategoryDescription = signal('');

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

  updateNewCategoryName(event: Event): void {
    const target = event.target as HTMLInputElement;
    this.newCategory.update(current => ({ ...current, name: target.value }));
  }

  updateNewCategoryDescription(event: Event): void {
    const target = event.target as HTMLTextAreaElement;
    this.newCategory.update(current => ({ ...current, description: target.value }));
  }

  getCategoryStats(categoryId: string): { groupCount: number; noteCount: number } {
    const groupCount = this.dataService.getGroupsByCategory(categoryId).length;
    const groups = this.dataService.getGroupsByCategory(categoryId);
    const noteCount = groups.reduce((total, group) => {
      return total + this.dataService.getNotesByGroup(group.id || '').length;
    }, 0);
    
    return { groupCount, noteCount };
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

  createCategory(): void {
    const category = this.newCategory();
    const name = category.name.trim();
    const description = category.description.trim();
    
    if (name) {
      this.dataService.createCategory(name, description || undefined).subscribe({
        next: () => {
          this.showCreateForm.set(false);
          this.newCategory.set({ name: '', description: '' });
        },
        error: (error) => {
          console.error('Error creating category:', error);
        }
      });
    }
  }

  cancelCreate(): void {
    this.showCreateForm.set(false);
    this.newCategory.set({ name: '', description: '' });
  }

  editCategory(category: Category): void {
    this.isEditingCategory.set(category.id || null);
    this.editCategoryName.set(category.name);
    this.editCategoryDescription.set(category.description || '');
  }

  cancelEditCategory(): void {
    this.isEditingCategory.set(null);
  }

  saveEditCategory(): void {
    const categoryId = this.isEditingCategory();
    if (categoryId) {
      const name = this.editCategoryName().trim();
      const description = this.editCategoryDescription().trim();
      
      if (name) {
        this.dataService.updateCategory(categoryId, name, description || undefined).subscribe({
          next: () => {
            this.isEditingCategory.set(null);
          },
          error: (error) => {
            console.error('Error updating category:', error);
          }
        });
      }
    }
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