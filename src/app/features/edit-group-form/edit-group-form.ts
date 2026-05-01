import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, Output, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { message } from '@tauri-apps/plugin-dialog';
import { catchError, from } from 'rxjs';
import { createGroup, updateGroup } from '../../core/api/groups';
import { Group } from '../../core/data.service';

@Component({
  selector: 'app-edit-group-form',
  standalone: true,
  imports: [FormsModule, CommonModule],
  templateUrl: './edit-group-form.html',
  styleUrl: './edit-group-form.css',
})
export class EditGroupForm {

  @Output() formSaved = new EventEmitter<boolean>();
  @Output() cancelEdit = new EventEmitter<void>();

  @Input() groupId: string = '';
  
  @Input() categoriesId: string = '';
  // Form state  
  @Input() groupData= signal<Group | null>(null);

  updateNewGroupName(event: Event): void {
    const target = event.target as HTMLInputElement;
    this.groupData.update(current => current ? ({ ...current, name: target.value }) : null);
  }

  saveData(): void {
    console.log('Saving group:', this.groupData());
    if(this.groupData()?.name.trim() === '') {
      message('Name is required',{
        kind:'error',
        title: 'Validation Error'
      });
      return;
    }

    // check for invalid characters avoid injection or some vulnerability
    const invalidChars = ['<', '>', ';', '--'];
    if(invalidChars.some(char => this.groupData()?.name.includes(char))) {
      message('Name cannot contain invalid characters like <, >, ;, --',{
        kind:'error',
        title: 'Validation Error'
      });
      return;
    }

    if(this.groupId) {
      from(updateGroup({
        id: this.groupId,
        name: this.groupData()?.name || '',
        categories_id: this.categoriesId
      } as Group))
      .pipe(catchError(error => {
        console.error('Error editing group:', error);
        message('Failed to edit group. Please try again.', {
          kind: 'error',
          title: 'Error'
        });
        return [];
      }))
      .subscribe(() => {
        console.log('Group updated successfully');
        this.formSaved.emit(true);
      });
    } else {
      from(createGroup({
        id: this.groupId,
        name:   this.groupData()?.name || '',
        categories_id: this.categoriesId
      } as Group))
      .pipe(catchError(error => {
        console.error('Error adding group:', error);
        message('Failed to add group. Please try again.', {
          kind: 'error',
          title: 'Error'
        });
        this.formSaved.emit(false);
        return [];
      }))
      .subscribe(newGroupId => {
        console.log('New group added with ID:', newGroupId);
        this.formSaved.emit(true);
      });
      console.log('Creating new group');
    }
  }

  cancelForm(): void {
    console.log('Canceling edit');
    this.groupData.set(null);
    this.formSaved.emit(false);
    this.cancelEdit.emit();
  }
}
