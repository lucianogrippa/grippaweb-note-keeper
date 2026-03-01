import { Component, computed, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../../../core/auth.service';
import { ThemeService } from '../../../core/theme.service';
import { SearchService, SearchResults } from '../../../core/search.service';
import { Category, Group, Note } from '../../../core/data.service';

@Component({
  selector: 'app-navbar',
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule],
  templateUrl: './navbar.component.html',
  styleUrl: './navbar.component.css'
})
export class NavbarComponent {
  private authService = inject(AuthService);
  public themeService = inject(ThemeService);
  private searchService = inject(SearchService);
  private router = inject(Router);

  currentUser = computed(() => this.authService.currentUser());
  isMenuOpen = signal(false);
  
  // Search state
  searchQuery = signal('');
  searchResults = signal<SearchResults>({
    categories: [],
    groups: [],
    notes: [],
    totalResults: 0
  });
  isSearchOpen = signal(false);
  isSearching = signal(false);
  
  toggleMenu(): void {
    this.isMenuOpen.set(!this.isMenuOpen());
  }

  toggleSearch(): void {
    this.isSearchOpen.update(open => !open);
    if (!this.isSearchOpen()) {
      this.clearSearch();
    }
  }

  onSearchInput(event: Event): void {
    const target = event.target as HTMLInputElement;
    const query = target.value;
    this.searchQuery.set(query);
    
    if (query.trim().length >= 2) {
      this.performSearch(query.trim());
    } else {
      this.searchResults.set({
        categories: [],
        groups: [],
        notes: [],
        totalResults: 0
      });
    }
  }

  performSearch(query: string): void {
    this.isSearching.set(true);
    
    const results = this.searchService.search(query);
    this.searchResults.set(results);
    this.isSearching.set(false);
  }

  selectResult(result: Category | Group | Note, type: string): void {
    this.clearSearch();
    
    switch (type) {
      case 'category':
        this.router.navigate(['/category', result.id]);
        break;
      case 'group':
        this.router.navigate(['/group', result.id]);
        break;
      case 'note':
        this.router.navigate(['/note', result.id]);
        break;
    }
  }

  clearSearch(): void {
    this.searchQuery.set('');
    this.searchResults.set({
      categories: [],
      groups: [],
      notes: [],
      totalResults: 0
    });
    this.isSearchOpen.set(false);
  }

  getResultIcon(type: string): string {
    switch (type) {
      case 'category':
        return `<svg width="16" height="16" viewBox="0 0 24 24" fill="none">
          <path d="M22 19C22 20.1046 21.1046 21 20 21H4C2.89543 21 2 20.1046 2 19V5C2 3.89543 2.89543 2 4 2H20C21.1046 2 22 2.89543 22 4V19ZM2 7H22" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>`;
      case 'group':
        return `<svg width="16" height="16" viewBox="0 0 24 24" fill="none">
          <path d="M3 7V5C3 3.89543 3.89543 3 5 3H19C20.1046 3 21 3.89543 21 5V7M3 7L21 7M3 7V19C3 20.1046 3.89543 21 5 21H19C20.1046 21 21 20.1046 21 19V7M9 11V15M15 11V15" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>`;
      case 'note':
        return `<svg width="16" height="16" viewBox="0 0 24 24" fill="none">
          <path d="M14 2H6C5.46957 2 4.96086 2.21071 4.58579 2.58579C4.21071 2.96086 4 3.46957 4 4V20C4 20.5304 4.21071 21.0391 4.58579 21.4142C4.96086 21.7893 5.46957 22 6 22H18C18.5304 22 19.0391 21.7893 19.4142 21.4142C19.7893 21.0391 20 20.5304 20 20V8L14 2Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          <polyline points="14,2 14,8 20,8" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>`;
      default:
        return '';
    }
  }

  logout(): void {
    this.authService.logout();
  }
}