import { Component, computed, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { DataService, Group, Category } from '../../core/data.service';
import { NavbarComponent } from '../../shared/components/navbar/navbar.component';

@Component({
  selector: 'app-category-detail',
  standalone: true,
  imports: [CommonModule, NavbarComponent, FormsModule],
  templateUrl: './category-detail.component.html',
  styleUrl: './category-detail.component.css'
})
export class CategoryDetailComponent implements OnInit {
  private dataService = inject(DataService);
  private router = inject(Router);
  private route = inject(ActivatedRoute);

  categoryId = signal<string>('');
  category = computed(() => {
    const id = this.categoryId();
    return this.dataService.categories().find(c => c.id === id);
  });
  
  groups = computed(() => {
    const id = this.categoryId();
    return this.dataService.getGroupsByCategory(id);
  });

  // UI state
  isLoaded = signal(false);
  showCreateForm = signal(false);
  isEditingGroup = signal<string | null>(null);

  // Form state  
  newGroup = signal({
    name: '',
    description: ''
  });

  editGroupName = signal('');
  editGroupDescription = signal('');

  ngOnInit(): void {
    this.route.paramMap.subscribe(params => {
      const id = params.get('id');
      if (id) {
        this.categoryId.set(id);
      }
    });

    setTimeout(() => {
      this.isLoaded.set(true);
    }, 100);
  }

  updateNewGroupName(event: Event): void {
    const target = event.target as HTMLInputElement;
    this.newGroup.update(current => ({ ...current, name: target.value }));
  }

  updateNewGroupDescription(event: Event): void {
    const target = event.target as HTMLTextAreaElement;
    this.newGroup.update(current => ({ ...current, description: target.value }));
  }

  getGroupStats(groupId: string): { noteCount: number } {
    const noteCount = this.dataService.getNotesByGroup(groupId).length;
    return { noteCount };
  }

  formatDate(date: string): string {
    const now = new Date();
    const groupDate = new Date(date);
    const diffTime = now.getTime() - groupDate.getTime();
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
    
    if (diffDays === 0) return 'Today';
    if (diffDays === 1) return 'Yesterday';
    if (diffDays < 7) return `${diffDays} days ago`;
    return groupDate.toLocaleDateString();
  }

  viewGroup(groupId: string): void {
    this.router.navigate(['/group', groupId]);
  }

  createGroup(): void {
    const group = this.newGroup();
    const name = group.name.trim();
    const description = group.description.trim();
    const categoryId = this.categoryId();
    
    if (name && categoryId) {
      this.dataService.createGroup(categoryId, name).subscribe({
        next: () => {
          this.showCreateForm.set(false);
          this.newGroup.set({ name: '', description: '' });
        },
        error: (error) => {
          console.error('Error creating group:', error);
        }
      });
    }
  }

  cancelCreate(): void {
    this.showCreateForm.set(false);
    this.newGroup.set({ name: '', description: '' });
  }

  editGroup(group: Group): void {
    this.isEditingGroup.set(group.id);
    this.editGroupName.set(group.name);
    this.editGroupDescription.set(group.description || '');
  }

  saveEditGroup(): void {
    const groupId = this.isEditingGroup();
    if (groupId) {
      const name = this.editGroupName().trim();
      const description = this.editGroupDescription().trim();
      
      if (name) {
        this.dataService.updateGroup(groupId, name).subscribe({
          next: () => {
            this.isEditingGroup.set(null);
          },
          error: (error) => {
            console.error('Error updating group:', error);
          }
        });
      }
    }
  }

  cancelEditGroup(): void {
    this.isEditingGroup.set(null);
  }

  deleteGroup(groupId: string): void {
    const group = this.groups().find(g => g.id === groupId);
    const groupName = group?.name || 'this group';
    
    if (confirm(`Are you sure you want to delete "${groupName}" and all its notes?`)) {
      this.dataService.deleteGroup(groupId).subscribe({
        next: () => {
          console.log('Group deleted successfully');
        },
        error: (error) => {
          console.error('Error deleting group:', error);
        }
      });
    }
  }

  goBack(): void {
    this.router.navigate(['/dashboard']);
  }
}