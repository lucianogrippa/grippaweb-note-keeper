import { Component, computed, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { DataService, Note, Group } from '../../core/data.service';
import { NavbarComponent } from '../../shared/components/navbar/navbar.component';
import { map, tap } from 'rxjs';
import { EditNotesForm } from '../edit-notes-form/notes-form';

@Component({
  selector: 'app-group-detail',
  standalone: true,
  imports: [CommonModule, NavbarComponent, FormsModule, EditNotesForm],
  templateUrl: './group-detail.component.html',
  styleUrl: './group-detail.component.css'
})
export class GroupDetailComponent implements OnInit {

  protected totalNotes = signal(0);

  protected router = inject(Router);
  private dataService = inject(DataService);
  private route = inject(ActivatedRoute);


  groupId = signal<string>('');
  noteId = signal<string>('');
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
    console.log("Loading notes for group:", this.groupId());
    const id = this.groupId();
    return this.dataService.getNotesByGroup(id).pipe(
      tap(r => {
        this.totalNotes.set(r.length);
      })
    );
  });

  // UI state
  isLoaded = signal(false);
  showCreateForm = signal(false);

  // Form state  
  newNote = signal({
    id: '',
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



  cancelCreate(): void {
    this.showCreateForm.set(false);
    this.newNote.set({ id: '', title: '', content: '', is_encrypted: false });
  }

  deleteNote(noteId: string): void {
    this.notes().pipe(map(notes => notes.find(n => n.id === noteId))).subscribe({
      next: (result) => {
        if (confirm(`Are you sure you want to delete "${result?.title}"?`)) {
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
    });
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

  handleFormSaved(success: boolean): void {
    if (success) {
      this.noteId.set('');
      this.showCreateForm.set(false);
      this.newNote.set({ id: '', title: '', content: '', is_encrypted: false });
      this.dataService.getNotesByGroup(this.groupId()).subscribe({
        next: (notes) => {
          this.totalNotes.set(notes.length);
        },
        error: (error) => {
          console.error('Error loading notes:', error);
        }
      });
    }
  }
  handleCancelCreate(): void {
    this.noteId.set('');
    this.showCreateForm.set(false);
    this.newNote.set({ id: '', title: '', content: '', is_encrypted: false });
  }
  addNote(): void {
    this.noteId.set('');
    this.newNote.set({ id: '', title: '', content: '', is_encrypted: false });
    this.showCreateForm.set(true);
  }
  editNote(noteId: string): void {
    this.noteId.set(noteId);
    this.newNote.update(current => {
      const note = this.notes().pipe(map(notes => notes.find(n => n.id === noteId)));
      let foundNote: Note | undefined;
      note.subscribe(n => foundNote = n);
      if (foundNote) {
        return { ...current, ...foundNote };
      }
      return current;
    });
    this.showCreateForm.set(true);
  }
}