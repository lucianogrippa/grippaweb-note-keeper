import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, Output, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { message } from '@tauri-apps/plugin-dialog';
import { addCategory, editCategory } from '../../core/api/categories';
import { catchError, from } from 'rxjs';

@Component({
  selector: 'app-edit-category-form',
  standalone: true,
  imports: [FormsModule, CommonModule],
  templateUrl: './edit-category-form.html',
  styleUrl: './edit-category-form.css',
})
export class EditCategoryForm {

  @Output() formSaved = new EventEmitter<boolean>();
  @Output() cancelEdit = new EventEmitter<void>();

  @Input() categoryId: string = '';

  @Input() userId: string = '';

  @Input() categoryData = signal({
    name: '',
    description: '',
    userId: this.userId
  });

  updateNewCategoryName(event: Event): void {
    const target = event.target as HTMLInputElement;
    this.categoryData.update(current => ({ ...current, name: target.value }));
  }
  updateNewCategoryDescription(event: Event): void {
    const target = event.target as HTMLTextAreaElement;
    this.categoryData.update(current => ({ ...current, description: target.value }));
  }

  saveData(): void {
    console.log('Saving category:', this.categoryData());
    if(this.categoryData().name.trim() === '') {
      message('Name is required',{
        kind:'error',
        title: 'Validation Error'
      });
      return;
    }

    if(this.categoryData().description.trim() === '') {
      message('Description is required',{
        kind:'error',
        title: 'Validation Error'
      });
      return;
    }

    // check for invalid characters avoid injection or some vulnerability
    const invalidChars = ['<', '>', ';', '--'];
    if(invalidChars.some(char => this.categoryData().name.includes(char) || this.categoryData().description.includes(char))) {
      message('Name and description cannot contain invalid characters like <, >, ;, --',{
        kind:'error',
        title: 'Validation Error'
      });
      return;
    }

    if(this.categoryId) {
      from(editCategory(this.categoryId, this.categoryData().name, this.categoryData().description))
      .pipe(catchError(error => {
        console.error('Error editing category:', error);
        message('Failed to edit category. Please try again.', {
          kind: 'error',
          title: 'Error'
        });
        return [];
      }))
      .subscribe(() => {
        console.log('Category updated successfully');
        this.formSaved.emit(true);
      });
    } else {
      from(addCategory(this.categoryData().userId, this.categoryData().name, this.categoryData().description))
      .pipe(catchError(error => {
        console.error('Error adding category:', error);
        message('Failed to add category. Please try again.', {
          kind: 'error',
          title: 'Error'
        });
        this.formSaved.emit(false);
        return [];
      }))
      .subscribe(newCategoryId => {
        console.log('New category added with ID:', newCategoryId);
        this.formSaved.emit(true);
      });
      console.log('Creating new category');
    }
  }

  cancelForm(): void {
    console.log('Canceling edit');
    this.categoryData.set({ name: '', description: '', userId: this.userId });
    this.formSaved.emit(false);
    this.cancelEdit.emit();
  }
}
