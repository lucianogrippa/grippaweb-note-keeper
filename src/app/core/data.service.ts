import { inject, Injectable, signal } from '@angular/core';
import { BehaviorSubject, from, Observable, switchMap } from 'rxjs';
import { AuthService } from './auth.service';
import { User } from './models';
import { addCategory, deleteCategoryById, editCategory, findCategoryById, getCategoriesByUser } from './api/categories';
import { createGroup, deleteGroup, loadGroupsByCategory, updateGroup } from './api/groups';

export interface Category {
  id?: string;
  user_id: string;
  name: string;
  description?: string;
  created_at: string;
  updated_at: string;
}

export interface Group {
  id?: string;
  categories_id: string;
  name: string;
  description?: string;
  created_at: string;
  updated_at: string;
}

export interface Note {
  id?: string;
  groups_id: string;
  title: string;
  content: string;
  is_encrypted: boolean;
  created_at: string;
  updated_at: string;
}

@Injectable({
  providedIn: 'root'
})
export class DataService {

  private categoriesSubject = new BehaviorSubject<Category[]>([]);
  private groupsSubject = new BehaviorSubject<Group[]>([]);
  private notesSubject = new BehaviorSubject<Note[]>([]);
  private readonly authService = inject(AuthService);

  categories$ = this.categoriesSubject.asObservable();
  groups$ = this.groupsSubject.asObservable();
  notes$ = this.notesSubject.asObservable();

  // Signals for reactive UI
  categories = signal<Category[]>([]);
  groups = signal<Group[]>([]);
  notes = signal<Note[]>([]);

  currentUser = signal(this.authService.currentUser() as User | null);
  
  constructor() {
    this.loadCategories();
  }

  async loadCategories(): Promise<void> {
   
    const user = this.authService.currentUser();

    if (user) {
      // Load categories for the current user
      const userCategories = await getCategoriesByUser(user.id);
      this.categories.set(userCategories);
      this.categoriesSubject.next(userCategories);
    }
  }

    loadGroups(id: string): Observable<Group[]> {
      return from(loadGroupsByCategory(id).then(groups => {
        this.groups.set(groups);
        this.groupsSubject.next(groups);
        return groups;
      }));
    }

  // Categories CRUD
  getCategories(): Category[] {
    return this.categories();
  }

  getCategoryById(id: string): Category | undefined {
    return this.categories().find(cat => cat.id === id);
  }

  createCategory(name: string, description?: string): Observable<Category> {
    return new Observable(observer => {
      const newCategory: Category = {
        user_id: this.currentUser()?.id || '',
        name,
        description,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };

      addCategory(this.currentUser()?.id || 'user-1', name, description || '')
      .then(() => {
        getCategoriesByUser(this.currentUser()?.id || 'user-1')        .then(categories => {
          this.categories.set(categories);
          this.categoriesSubject.next(categories);
          
          observer.next(newCategory);
          observer.complete();
        })
        .catch(error => {
          console.error('Error loading categories after creation:', error);
          observer.error(error);
        });
      }).catch(error => {
        console.error('Error creating category:', error);
        observer.error(error);
      });
    });
  }

  updateCategory(id: string, name: string, description?: string): Observable<Category> {
    return new Observable(observer => {
      const categories = this.categories();

      findCategoryById(id)
        .then(category => {
          if (!category) {
            observer.error('Category not found');
            observer.complete();
            return;
          }

          // Update category in the backend
          editCategory(id, name, description || '')
            .then(() => {
              // After successful update, refresh categories from backend
              getCategoriesByUser(this.currentUser()?.id || 'user-1')
                .then(categories => {
                  this.categories.set(categories);
                  this.categoriesSubject.next(categories);
                  
                  const updatedCategory = categories.find(cat => cat.id === id);
                  if (updatedCategory) {
                    observer.next(updatedCategory);
                  } else {
                    observer.error('Updated category not found after refresh');
                  }
                  observer.complete();
                } )
                .catch(error => {
                  console.error('Error loading categories after update:', error);
                  observer.error(error);
                  observer.complete();
                });
            })
            .catch(error => {
              console.error('Error updating category:', error);
              observer.error(error);
              observer.complete();
            });
        })
        .catch(error => {
          console.error('Error finding category for update:', error);
          observer.error(error);
          observer.complete();
        });
    });
  }

  deleteCategory(id: string): Observable<boolean> {
    return new Observable(observer => {
      deleteCategoryById(id)
      .then(() => {
        getCategoriesByUser(this.currentUser()?.id || 'user-1')
          .then(categories => {
            this.categories.set(categories);
            this.categoriesSubject.next(categories);
          })
          .then(() => {
            observer.next(true);
            observer.complete();
          })
          .catch(error => {
            console.error('Error loading categories after deletion:', error);
            observer.error(error);
            observer.complete();
          });
      })
      .catch(error => {
        console.error('Error deleting category:', error);
        observer.error(error);
        observer.complete();
      });
    });
  }

  // Groups CRUD
  getGroupsByCategory(categoryId: string): Group[] {
    return this.groups().filter(group => group.categories_id === categoryId);
  }

  getGroupById(id: string): Group | undefined {
    return this.groups().find(group => group.id === id);
  }

  createGroup(categoryId: string, name: string): Observable<Group> {
    return from(createGroup({ name, categories_id: categoryId }))
    .pipe(
      switchMap(()=>loadGroupsByCategory(categoryId)),
      switchMap(groups => {
        this.groups.set(groups);
        this.groupsSubject.next(groups);
        const createdGroup = groups.find(g => g.name === name);
        if (createdGroup) {
          return new Observable<Group>(observer => {
            observer.next(createdGroup);
            observer.complete();
          });
        } else {
          return new Observable<Group>(observer => {
            observer.error('Created group not found after refresh');
            observer.complete();
          });
        }
      }));
     } 

  updateGroup(id: string, name: string): Observable<Group> {
    return from(updateGroup({id, name} as Group))
    .pipe(
      switchMap(() => {
        const group = this.getGroupById(id);
        if (group) {
          return loadGroupsByCategory(group.categories_id);
        } else {
          return new Observable<Group[]>(observer => {
            observer.error('Group not found for update');
            observer.complete();
          });
        }
      }),
      switchMap(groups => {
        this.groups.set(groups);
        this.groupsSubject.next(groups);
        const updatedGroup = groups.find(g => g.id === id);
        if (updatedGroup) {
          return new Observable<Group>(observer => {
            observer.next(updatedGroup);
            observer.complete();
          });
        } else {
          return new Observable<Group>(observer => {
            observer.error('Updated group not found after refresh');
            observer.complete();
          });
        }
      })
    );
  }

  deleteGroup(id: string): Observable<boolean> {
    return from(deleteGroup(id))
    .pipe(
      switchMap(() => {
        const group = this.getGroupById(id);
        if (group) {
          return loadGroupsByCategory(group.categories_id);
        } else {
          return new Observable<Group[]>(observer => {
            observer.error('Group not found for deletion');
            observer.complete();
          });
        }
      }),
      switchMap(groups => {
        this.groups.set(groups);
        this.groupsSubject.next(groups);
        return new Observable<boolean>(observer => {
          observer.next(true);
          observer.complete();
        });
      })
    );
  }

  // Notes CRUD
  getNotesByGroup(groupId: string): Note[] {
    return this.notes().filter(note => note.groups_id === groupId);
  }

  getNoteById(id: string): Note | undefined {
    return this.notes().find(note => note.id === id);
  }

  createNote(groupId: string, title: string, content: string, isEncrypted: boolean = false): Observable<Note> {
    return new Observable(observer => {
      const newNote: Note = {
        groups_id: groupId,
        title,
        content,
        is_encrypted: isEncrypted,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };

      const updatedNotes = [...this.notes(), newNote];
      this.notes.set(updatedNotes);
      this.notesSubject.next(updatedNotes);
      
      observer.next(newNote);
      observer.complete();
    });
  }

  updateNote(id: string, title: string, content: string, isEncrypted?: boolean): Observable<Note> {
    return new Observable(observer => {
      const notes = this.notes();
      const index = notes.findIndex(note => note.id === id);
      
      if (index !== -1) {
        const updatedNote = {
          ...notes[index],
          title,
          content,
          is_encrypted: isEncrypted !== undefined ? isEncrypted : notes[index].is_encrypted,
          updated_at: new Date().toISOString()
        };
        
        const updatedNotes = [...notes];
        updatedNotes[index] = updatedNote;
        
        this.notes.set(updatedNotes);
        this.notesSubject.next(updatedNotes);
        
        observer.next(updatedNote);
      } else {
        observer.error('Note not found');
      }
      observer.complete();
    });
  }

  deleteNote(id: string): Observable<boolean> {
    return new Observable(observer => {
      const updatedNotes = this.notes().filter(note => note.id !== id);
      this.notes.set(updatedNotes);
      this.notesSubject.next(updatedNotes);
      
      observer.next(true);
      observer.complete();
    });
  }

  // Search functionality
  searchAll(query: string): { categories: Category[], groups: Group[], notes: Note[] } {
    const lowerQuery = query.toLowerCase();
    
    const matchedCategories = this.categories().filter(cat => 
      cat.name.toLowerCase().includes(lowerQuery) || 
      cat.description?.toLowerCase().includes(lowerQuery)
    );
    
    const matchedGroups = this.groups().filter(group => 
      group.name.toLowerCase().includes(lowerQuery)
    );
    
    const matchedNotes = this.notes().filter(note => 
      note.title.toLowerCase().includes(lowerQuery) || 
      note.content.toLowerCase().includes(lowerQuery)
    );
    
    return {
      categories: matchedCategories,
      groups: matchedGroups,
      notes: matchedNotes
    };
  }
}