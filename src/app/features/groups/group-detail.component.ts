import { Component, computed, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { DataService, Note, Group } from '../../core/data.service';
import { NavbarComponent } from '../../shared/components/navbar/navbar.component';

@Component({
  selector: 'app-group-detail',
  standalone: true,
  imports: [CommonModule, NavbarComponent, FormsModule],
  templateUrl: './group-detail.component.html',
  styleUrl: './group-detail.component.css'
})
export class GroupDetailComponent implements OnInit {
  private dataService = inject(DataService);
  public router = inject(Router);
  private route = inject(ActivatedRoute);

  groupId = signal<string>('');
  group = computed(() => {
    const id = this.groupId();
    return this.dataService.getGroupById(id);
  });
  
  category = computed(() => {
    const group = this.group();
    if (group) {
      return this.dataService.categories().find(c => c.id === group.categories_id);
    }
    return undefined;
  });
  
  notes = computed(() => {
    const id = this.groupId();
    return this.dataService.getNotesByGroup(id);
  });

  // UI state
  isLoaded = signal(false);
  showCreateForm = signal(false);

  // Form state  
  newNote = signal({
    title: '',
    content: '',
    is_encrypted: false
  });

  ngOnInit(): void {
    this.route.paramMap.subscribe(params => {
      const id = params.get('id');
      if (id) {
        this.groupId.set(id);
      }
    });

    setTimeout(() => {
      this.isLoaded.set(true);
    }, 100);
  }

  updateNewNoteTitle(event: Event): void {
    const target = event.target as HTMLInputElement;
    this.newNote.update(current => ({ ...current, title: target.value }));
  }

  updateNewNoteContent(event: Event): void {
    const target = event.target as HTMLTextAreaElement;
    this.newNote.update(current => ({ ...current, content: target.value }));
  }

  toggleEncryption(): void {
    this.newNote.update(current => ({ ...current, is_encrypted: !current.is_encrypted }));
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

  getTimeAgo(date: string): string {
    const now = new Date();
    const noteDate = new Date(date);
    const diffTime = now.getTime() - noteDate.getTime();
    const diffMinutes = Math.floor(diffTime / (1000 * 60));
    const diffHours = Math.floor(diffTime / (1000 * 60 * 60));
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
    
    if (diffMinutes < 60) return `${diffMinutes}m ago`;
    if (diffHours < 24) return `${diffHours}h ago`;
    if (diffDays < 7) return `${diffDays}d ago`;
    return noteDate.toLocaleDateString();
  }

  getPreview(content: string, maxLength: number = 150): string {
    if (content.length <= maxLength) return content;
    return content.substring(0, maxLength) + '...';
  }

  viewNote(noteId: string): void {
    this.router.navigate(['/note', noteId]);
  }

  createNote(): void {
    const note = this.newNote();
    const title = note.title.trim();
    const content = note.content.trim();
    const groupId = this.groupId();
    
    if (title && content && groupId) {
      this.dataService.createNote(title, content, groupId, note.is_encrypted).subscribe({
        next: () => {
          this.showCreateForm.set(false);
          this.newNote.set({ title: '', content: '', is_encrypted: false });
        },
        error: (error) => {
          console.error('Error creating note:', error);
        }
      });
    }
  }

  cancelCreate(): void {
    this.showCreateForm.set(false);
    this.newNote.set({ title: '', content: '', is_encrypted: false });
  }

  deleteNote(noteId: string): void {
    const note = this.notes().find(n => n.id === noteId);
    const noteTitle = note?.title || 'this note';
    
    if (confirm(`Are you sure you want to delete "${noteTitle}"?`)) {
      this.dataService.deleteNote(noteId).subscribe({
        next: () => {
          console.log('Note deleted successfully');
        },
        error: (error) => {
          console.error('Error deleting note:', error);
        }
      });
    }
  }

  goBack(): void {
    const group = this.group();
    if (group) {
      this.router.navigate(['/category', group.categories_id]);
    } else {
      this.router.navigate(['/dashboard']);
    }
  }

  goToCategory(): void {
    const group = this.group();
    if (group) {
      this.router.navigate(['/category', group.categories_id]);
    }
  }
}