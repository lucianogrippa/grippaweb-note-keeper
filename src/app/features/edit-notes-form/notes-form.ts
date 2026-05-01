import { Component, EventEmitter, inject, Input, Output, signal } from '@angular/core';
import { DataService } from '../../core/data.service';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { message } from '@tauri-apps/plugin-dialog';

@Component({
  selector: 'app-notes-form',
  standalone: true,
  imports: [FormsModule, CommonModule],
  templateUrl: './notes-form.html',
  styleUrl: './notes-form.css',
})
export class EditNotesForm {
 
@Input()
noteId: string = '';

@Input()
groupId: string = '';


@Input()
noteData = signal({
    id: '',
    title: '',
    content: '',
    is_encrypted: false
  });

  @Output() formSaved = new EventEmitter<boolean>();
  @Output() cancelEdit = new EventEmitter<void>();

  private readonly dataService = inject(DataService);

  updateNewNoteTitle(event: Event): void {
    const target = event.target as HTMLInputElement;
    this.noteData.update(current => ({ ...current, title: target.value }));
  }

  updateNewNoteContent(event: Event): void {
    const target = event.target as HTMLTextAreaElement;
    this.noteData.update(current => ({ ...current, content: target.value }));
  }

  toggleEncryption(): void {
    this.noteData.update(current => ({ ...current, is_encrypted: !current.is_encrypted }));
  }

  addEditNote(): void {
    if(this.noteId) {
      this.editNote();
    } else {
      this.createNote();
    }
  }

  editNote(): void {
    const id= this.noteId;
    const note = this.noteData();
    const title = note.title.trim();
    const content = note.content.trim();
    const groupId = this.groupId;
    const isEncrypted = note.is_encrypted;
  
    if (title && content && groupId) {
      
      // check in title and content potezialy vulnerability
      const invalidChars = ['<', '>', ';', '--'];
      if(invalidChars.some(char => title.includes(char) || content.includes(char))) {
        message('Title and content cannot contain invalid characters like <, >, ;, --',{
          kind:'error',
          title: 'Validation Error'
        });
        return;
      }
      
      // Call the updateNote method in the data service
      this.dataService.updateNote(
        id,
        title,
        content,
        isEncrypted 
      ).subscribe({
        next: () => {
          this.formSaved.emit(true);
        },
        error: (error) => {
          console.error('Error updating note:', error);
          message('Failed to update note. Please try again.', {
            kind: 'error',
            title: 'Update Error'
          });
        }
      });
    }
  }

   createNote(): void {
      const note = this.noteData();
      const title = note.title.trim();
      const content = note.content.trim();
      const groupId = this.groupId;
  
      if (title && content && groupId) {

        // check in title and content potezialy vulnerability
        const invalidChars = ['<', '>', ';', '--'];
        if(invalidChars.some(char => title.includes(char) || content.includes(char))) {
          message('Title and content cannot contain invalid characters like <, >, ;, --',{
            kind:'error',
            title: 'Validation Error'
          });
          return;
        }

      // check min and max characters
      if(title.length < 5 || title.length > 150) {  
        message('Title must be between 5 and 150 characters.', {
          kind: 'error',
          title: 'Validation Error'
        });
        return;
      }

      if(content.length < 10 || content.length > 500) {
        message('Content must be between 10 and 500 characters.', {
          kind: 'error',
          title: 'Validation Error'
        });
        return;
      }

        this.dataService.createNote(groupId,title, content, note.is_encrypted).subscribe({
          next: () => {
            this.noteData.set({id:'', title: '', content: '', is_encrypted: false });
            this.formSaved.emit(true);
          },
          error: (error) => {
            console.error('Error creating note:', error);
            message('Failed to create note. Please try again.', {
              kind: 'error',
              title: 'Create Error'
            });
          }
        });
      }
    }

    cancelCreate(): void {
      this.cancelEdit.emit();
    }
}
