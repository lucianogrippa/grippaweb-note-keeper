import { Injectable, signal } from '@angular/core';
import { DataService, Category, Group, Note } from './data.service';

export interface SearchResults {
  categories: Category[];
  groups: Group[];
  notes: Note[];
  totalResults: number;
}

@Injectable({
  providedIn: 'root'
})
export class SearchService {
  searchQuery = signal<string>('');
  searchResults = signal<SearchResults>({
    categories: [],
    groups: [],
    notes: [],
    totalResults: 0
  });
  isSearching = signal<boolean>(false);

  constructor(private dataService: DataService) {}

  search(query: string): SearchResults {
    this.searchQuery.set(query);
    this.isSearching.set(true);

    if (!query.trim()) {
      const emptyResults = {
        categories: [],
        groups: [],
        notes: [],
        totalResults: 0
      };
      this.searchResults.set(emptyResults);
      this.isSearching.set(false);
      return emptyResults;
    }

    const results = this.dataService.searchAll(query);
    const totalResults = results.categories.length + results.groups.length + results.notes.length;
    
    const searchResults = {
      ...results,
      totalResults
    };

    this.searchResults.set(searchResults);
    this.isSearching.set(false);
    
    return searchResults;
  }

  clearSearch(): void {
    this.searchQuery.set('');
    this.searchResults.set({
      categories: [],
      groups: [],
      notes: [],
      totalResults: 0
    });
    this.isSearching.set(false);
  }

  getResultType(item: Category | Group | Note): 'category' | 'group' | 'note' {
    if ('user_id' in item) return 'category';
    if ('categories_id' in item) return 'group';
    return 'note';
  }

  getParentInfo(item: Group | Note): { category?: Category, group?: Group } {
    if ('categories_id' in item) {
      // It's a group
      const category = this.dataService.getCategoryById(item.categories_id);
      return { category };
    } else {
      // It's a note
      const group = this.dataService.getGroupById(item.groups_id);
      const category = group ? this.dataService.getCategoryById(group.categories_id) : undefined;
      return { category, group };
    }
  }
}