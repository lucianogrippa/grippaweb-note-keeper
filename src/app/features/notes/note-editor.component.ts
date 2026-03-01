import { Component, computed, inject, signal, OnInit, ViewChild, ElementRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { DataService, Note, Group } from '../../core/data.service';
import { NavbarComponent } from '../../shared/components/navbar/navbar.component';

@Component({
  selector: 'app-note-editor',
  standalone: true,
  imports: [CommonModule, NavbarComponent, FormsModule],
  templateUrl: './note-editor.component.html',
  styleUrl: './note-editor.component.css'
})
export class NoteEditorComponent implements OnInit {
  private dataService = inject(DataService);
  public router = inject(Router);
  private route = inject(ActivatedRoute);

  @ViewChild('contentEditor', { static: false }) contentEditor!: ElementRef<HTMLTextAreaElement>;

  // Route params
  noteId = signal<string | null>(null);
  groupId = signal<string | null>(null);
  
  // Data
  note = computed(() => {
    const id = this.noteId();
    if (id) {
      return this.dataService.getNoteById(id);
    }
    return null;
  });

  group = computed(() => {
    const note = this.note();
    if (note) {
      return this.dataService.getGroupById(note.groups_id);
    }
    const groupId = this.groupId();
    if (groupId) {
      return this.dataService.getGroupById(groupId);
    }
    return null;
  });
  
  category = computed(() => {
    const group = this.group();
    if (group) {
      return this.dataService.categories().find(c => c.id === group.categories_id);
    }
    return null;
  });

  // Form state
  title = signal('');
  content = signal('');
  isEncrypted = signal(false);
  
  // UI state
  isLoaded = signal(false);
  isEditing = computed(() => this.noteId() !== null);
  isSaving = signal(false);
  hasUnsavedChanges = signal(false);
  showPreview = signal(false);
  wordCount = computed(() => {
    const text = this.content().replace(/\s+/g, ' ').trim();
    return text ? text.split(' ').length : 0;
  });
  characterCount = computed(() => this.content().length);

  ngOnInit(): void {
    this.route.paramMap.subscribe(params => {
      const noteId = params.get('id');
      const groupId = params.get('groupId');
      
      if (noteId && noteId !== 'new') {
        this.noteId.set(noteId);
        this.loadNote();
      } else if (groupId) {
        this.groupId.set(groupId);
        this.initNewNote();
      }
    });

    // Track changes for unsaved warning
    this.setupChangeTracking();

    setTimeout(() => {
      this.isLoaded.set(true);
    }, 100);
  }

  private loadNote(): void {
    const note = this.note();
    if (note) {
      this.title.set(note.title);
      this.content.set(note.content);
      this.isEncrypted.set(note.is_encrypted);
      this.hasUnsavedChanges.set(false);
    }
  }

  private initNewNote(): void {
    this.title.set('');
    this.content.set('');  
    this.isEncrypted.set(false);
    this.hasUnsavedChanges.set(false);
  }

  private setupChangeTracking(): void {
    // Initial values for comparison
    let initialTitle = this.title();
    let initialContent = this.content();
    let initialIsEncrypted = this.isEncrypted();

    // Check for changes whenever values update
    const checkChanges = () => {
      const hasChanges = 
        this.title() !== initialTitle || 
        this.content() !== initialContent ||
        this.isEncrypted() !== initialIsEncrypted;
      this.hasUnsavedChanges.set(hasChanges);
    };

    // Set up effect to track changes
    setTimeout(() => {
      const observer = new MutationObserver(() => {
        checkChanges();
      });
      
      observer.observe(document.body, {
        subtree: true,
        childList: true
      });
    }, 100);
  }

  updateTitle(event: Event): void {
    const target = event.target as HTMLInputElement;
    this.title.set(target.value);
  }

  updateContent(event: Event): void {
    const target = event.target as HTMLTextAreaElement;
    this.content.set(target.value);
  }

  toggleEncryption(): void {
    this.isEncrypted.update(current => !current);
  }

  togglePreview(): void {
    this.showPreview.update(current => !current);
  }

  insertText(textBefore: string, textAfter: string = ''): void {
    const textarea = this.contentEditor?.nativeElement;
    if (!textarea) return;

    const start = textarea.selectionStart;
    const end = textarea.selectionEnd;
    const selectedText = textarea.value.substring(start, end);
    
    const beforeText = textarea.value.substring(0, start);
    const afterText = textarea.value.substring(end);
    
    const newText = beforeText + textBefore + selectedText + textAfter + afterText;
    
    this.content.set(newText);
    
    // Restore cursor position
    setTimeout(() => {
      const newCursorPos = start + textBefore.length + selectedText.length;
      textarea.setSelectionRange(newCursorPos, newCursorPos);
      textarea.focus();
    }, 0);
  }

  formatBold(): void {
    this.insertText('**', '**');
  }

  formatItalic(): void {
    this.insertText('*', '*');
  }

  formatHeading(): void {
    this.insertText('## ');
  }

  formatList(): void {
    this.insertText('- ');
  }

  async saveNote(): Promise<void> {
    const titleValue = this.title().trim();
    const contentValue = this.content().trim();
    
    if (!titleValue || !contentValue) {
      alert('Please provide both title and content for the note.');
      return;
    }

    this.isSaving.set(true);
    
    try {
      if (this.isEditing()) {
        // Update existing note
        const noteId = this.noteId()!;
        await this.dataService.updateNote(
          noteId, 
          titleValue, 
          contentValue, 
          this.isEncrypted()
        ).toPromise();
      } else {
        // Create new note
        const groupId = this.groupId()!;
        await this.dataService.createNote(
          titleValue,
          contentValue,
          groupId,
          this.isEncrypted()
        ).toPromise();
      }
      
      this.hasUnsavedChanges.set(false);
      this.goBack();
    } catch (error) {
      console.error('Error saving note:', error);
      alert('Failed to save note. Please try again.');
    } finally {
      this.isSaving.set(false);
    }
  }

  deleteNote(): void {
    const noteId = this.noteId();
    if (!noteId) return;

    const noteTitle = this.title() || 'this note';
    if (confirm(`Are you sure you want to delete "${noteTitle}"?`)) {
      this.dataService.deleteNote(noteId).subscribe({
        next: () => {
          this.hasUnsavedChanges.set(false);
          this.goBack();
        },
        error: (error) => {
          console.error('Error deleting note:', error);
          alert('Failed to delete note. Please try again.');
        }
      });
    }
  }

  goBack(): void {
    const group = this.group();
    if (group) {
      this.router.navigate(['/group', group.id]);
    } else {
      this.router.navigate(['/dashboard']);
    }
  }

  canDeactivate(): boolean {
    if (this.hasUnsavedChanges()) {
      return confirm('You have unsaved changes. Are you sure you want to leave?');
    }
    return true;
  }

  formatDate(date: string): string {
    return new Date(date).toLocaleString();
  }
}