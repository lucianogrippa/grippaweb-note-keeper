import { Injectable, signal } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';

export interface Category {
  id: string;
  user_id: string;
  name: string;
  description?: string;
  created_at: string;
  updated_at: string;
}

export interface Group {
  id: string;
  categories_id: string;
  name: string;
  description?: string;
  created_at: string;
  updated_at: string;
}

export interface Note {
  id: string;
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

  categories$ = this.categoriesSubject.asObservable();
  groups$ = this.groupsSubject.asObservable();
  notes$ = this.notesSubject.asObservable();

  // Signals for reactive UI
  categories = signal<Category[]>([]);
  groups = signal<Group[]>([]);
  notes = signal<Note[]>([]);

  constructor() {
    this.initializeMockData();
  }

  private generateId(): string {
    return Math.random().toString(36).substr(2, 16);
  }

  private initializeMockData(): void {
    const userId = 'user-1';
    const mockCategories: Category[] = [
      {
        id: 'cat-1',
        user_id: userId,
        name: 'Bank',
        description: 'Banking and financial information',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      },
      {
        id: 'cat-2',
        user_id: userId,
        name: 'TV Subscriptions',
        description: 'Streaming services and entertainment',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      },
      {
        id: 'cat-3',
        user_id: userId,
        name: 'Cloud',
        description: 'Cloud services and storage',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      },
      {
        id: 'cat-4',
        user_id: userId,
        name: 'Work',
        description: 'Work-related notes and information',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      }
    ];

    const mockGroups: Group[] = [
      { id: 'grp-1', categories_id: 'cat-1', name: 'Credit Cards', created_at: new Date().toISOString(), updated_at: new Date().toISOString() },
      { id: 'grp-2', categories_id: 'cat-1', name: 'Savings Account', created_at: new Date().toISOString(), updated_at: new Date().toISOString() },
      { id: 'grp-3', categories_id: 'cat-2', name: 'Netflix', created_at: new Date().toISOString(), updated_at: new Date().toISOString() },
      { id: 'grp-4', categories_id: 'cat-2', name: 'Prime Video', created_at: new Date().toISOString(), updated_at: new Date().toISOString() },
      { id: 'grp-5', categories_id: 'cat-2', name: 'Disney+', created_at: new Date().toISOString(), updated_at: new Date().toISOString() },
      { id: 'grp-6', categories_id: 'cat-3', name: 'Google Drive', created_at: new Date().toISOString(), updated_at: new Date().toISOString() },
      { id: 'grp-7', categories_id: 'cat-3', name: 'Dropbox', created_at: new Date().toISOString(), updated_at: new Date().toISOString() },
      { id: 'grp-8', categories_id: 'cat-4', name: 'Meeting Notes', created_at: new Date().toISOString(), updated_at: new Date().toISOString() }
    ];

    const mockNotes: Note[] = [
      {
        id: 'note-1',
        groups_id: 'grp-1',
        title: 'Visa Card Info',
        content: 'Card number: **** **** **** 1234\\nExpiry: 12/25\\nCVV: ***',
        is_encrypted: true,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      },
      {
        id: 'note-2',
        groups_id: 'grp-3',
        title: 'Netflix Login',
        content: 'Email: user@example.com\\nPassword: ********\\nProfiles: Family, Kids',
        is_encrypted: true,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      },
      {
        id: 'note-3',
        groups_id: 'grp-8',
        title: 'Project Planning Meeting',
        content: 'Discussed Q1 goals and timeline. Next meeting on Friday.',
        is_encrypted: false,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      }
    ];

    this.categories.set(mockCategories);
    this.groups.set(mockGroups);
    this.notes.set(mockNotes);
    
    this.categoriesSubject.next(mockCategories);
    this.groupsSubject.next(mockGroups);
    this.notesSubject.next(mockNotes);
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
        id: this.generateId(),
        user_id: 'user-1', // Should come from auth service
        name,
        description,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };

      const updatedCategories = [...this.categories(), newCategory];
      this.categories.set(updatedCategories);
      this.categoriesSubject.next(updatedCategories);
      
      observer.next(newCategory);
      observer.complete();
    });
  }

  updateCategory(id: string, name: string, description?: string): Observable<Category> {
    return new Observable(observer => {
      const categories = this.categories();
      const index = categories.findIndex(cat => cat.id === id);
      
      if (index !== -1) {
        const updatedCategory = {
          ...categories[index],
          name,
          description,
          updated_at: new Date().toISOString()
        };
        
        const updatedCategories = [...categories];
        updatedCategories[index] = updatedCategory;
        
        this.categories.set(updatedCategories);
        this.categoriesSubject.next(updatedCategories);
        
        observer.next(updatedCategory);
      } else {
        observer.error('Category not found');
      }
      observer.complete();
    });
  }

  deleteCategory(id: string): Observable<boolean> {
    return new Observable(observer => {
      // Also delete associated groups and notes
      const groupsToDelete = this.groups().filter(g => g.categories_id === id);
      groupsToDelete.forEach(group => {
        const notesToDelete = this.notes().filter(n => n.groups_id === group.id);
        const updatedNotes = this.notes().filter(n => !notesToDelete.includes(n));
        this.notes.set(updatedNotes);
        this.notesSubject.next(updatedNotes);
      });

      const updatedGroups = this.groups().filter(g => g.categories_id !== id);
      this.groups.set(updatedGroups);
      this.groupsSubject.next(updatedGroups);

      const updatedCategories = this.categories().filter(cat => cat.id !== id);
      this.categories.set(updatedCategories);
      this.categoriesSubject.next(updatedCategories);
      
      observer.next(true);
      observer.complete();
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
    return new Observable(observer => {
      const newGroup: Group = {
        id: this.generateId(),
        categories_id: categoryId,
        name,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };

      const updatedGroups = [...this.groups(), newGroup];
      this.groups.set(updatedGroups);
      this.groupsSubject.next(updatedGroups);
      
      observer.next(newGroup);
      observer.complete();
    });
  }

  updateGroup(id: string, name: string): Observable<Group> {
    return new Observable(observer => {
      const groups = this.groups();
      const index = groups.findIndex(group => group.id === id);
      
      if (index !== -1) {
        const updatedGroup = {
          ...groups[index],
          name,
          updated_at: new Date().toISOString()
        };
        
        const updatedGroups = [...groups];
        updatedGroups[index] = updatedGroup;
        
        this.groups.set(updatedGroups);
        this.groupsSubject.next(updatedGroups);
        
        observer.next(updatedGroup);
      } else {
        observer.error('Group not found');
      }
      observer.complete();
    });
  }

  deleteGroup(id: string): Observable<boolean> {
    return new Observable(observer => {
      // Delete associated notes
      const updatedNotes = this.notes().filter(note => note.groups_id !== id);
      this.notes.set(updatedNotes);
      this.notesSubject.next(updatedNotes);

      const updatedGroups = this.groups().filter(group => group.id !== id);
      this.groups.set(updatedGroups);
      this.groupsSubject.next(updatedGroups);
      
      observer.next(true);
      observer.complete();
    });
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
        id: this.generateId(),
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