import { CommonModule } from '@angular/common';
import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { Observable, map } from 'rxjs';
import { DataService, Group } from '../../core/data.service';
import { NavbarComponent } from '../../shared/components/navbar/navbar.component';
import { EditGroupForm } from '../edit-group-form/edit-group-form';
import { ask, message } from '@tauri-apps/plugin-dialog';

@Component({
  selector: 'app-category-detail',
  standalone: true,
  imports: [CommonModule, NavbarComponent, FormsModule, EditGroupForm],
  templateUrl: './category-detail.component.html',
  styleUrl: './category-detail.component.css'
})
export class CategoryDetailComponent implements OnInit {

  protected totalNoteInGroups = signal(0);
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
  showAddEditGroupForm = signal(false);
  editGroupId = signal<string | null>(null);


  groupData = signal<Group | null>(null);

  ngOnInit(): void {
    this.route.paramMap.subscribe(params => {
      const id = params.get('id');
      if (id) {
        this.categoryId.set(id);
        this.dataService.loadGroups(id).subscribe({
          next: () => {
            // Groups loaded successfully
            this.isLoaded.set(true);
          },
          error: (error) => {
            console.error('Error loading groups:', error);
          }
        });
      }
    });

    setTimeout(() => {
      this.isLoaded.set(true);
    }, 100);
  }




  getGroupStats(groupId: string): Observable<{ noteCount: number }> {
    return this.dataService.getNotesByGroup(groupId).pipe(map(notes => {
      console.log(`Group ${groupId} has ${notes.length} notes`);
      return { noteCount: notes.length };
    }));

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





  cancelEditGroup(): void {
    this.editGroupId.set(null);
    this.groupData.set(null);
  }

  async deleteGroup(groupId: string): Promise<void> {
    const group = this.groups().find(g => g.id === groupId);
    const groupName = group?.name || 'this group';

    if (await ask(`Are you sure you want to delete "${groupName}" and all its notes?`)) {
      this.dataService.deleteGroup(groupId).subscribe({
        next: () => {
          console.log('Group deleted successfully');
        },
        error: (error) => {
          console.error('Error deleting group:', error);
          message("Failed to delete group. Please try again. Be sure to delete all note inside the group.",{
            title: "Error",
            kind: "error"
          });
        }
      });
    }
  }

  goBack(): void {
    this.router.navigate(['/dashboard']);
  }

  handleFormSaved(success: boolean): void {
    if (success) {
      this.showAddEditGroupForm.set(false);
      this.editGroupId.set(null);

      // reload groups to reflect changes
      this.dataService.loadGroups(this.categoryId()).subscribe({
        next: () => {
          console.log('Groups reloaded successfully');
        },
        error: (error) => {
          console.error('Error reloading groups:', error);
        }
      });
    } else {
      console.error('Error saving group');
    }
  }

  addGroup(): void {
    this.showAddEditGroupForm.set(true);
    this.editGroupId.set(null);
    this.groupData.set({ name: '', id: '', categories_id: this.categoryId() } as Group);
  }

  editGroup(group: Group): void {
    this.showAddEditGroupForm.set(true);
    this.editGroupId.set(group.id || null);
    this.groupData.set({ name: group.name, id: group.id || '', categories_id: group.categories_id || '' } as Group);
  }
  handleCancelEdit(): void {
    this.showAddEditGroupForm.set(false);
    this.editGroupId.set(null);
    this.groupData.set(null);
  }

}