import { Injectable, signal } from '@angular/core';

export type Theme = 'light' | 'dark' | 'auto';

@Injectable({
  providedIn: 'root'
})
export class ThemeService {
  private readonly THEME_KEY = 'notekeeper-theme';
  
  currentTheme = signal<Theme>('light');
  isDarkMode = signal<boolean>(false);

  constructor() {
    this.initializeTheme();
    this.setupSystemThemeListener();
  }

  private initializeTheme(): void {
    const savedTheme = localStorage.getItem(this.THEME_KEY) as Theme;
    const theme = savedTheme || 'light';
    this.setTheme(theme);
  }

  setTheme(theme: Theme): void {
    this.currentTheme.set(theme);
    localStorage.setItem(this.THEME_KEY, theme);
    this.applyTheme(theme);
  }

  private applyTheme(theme: Theme): void {
    const root = document.documentElement;
    
    // Remove existing theme classes
    root.classList.remove('light-theme', 'dark-theme');
    
    if (theme === 'auto') {
      const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      root.classList.add(prefersDark ? 'dark-theme' : 'light-theme');
      this.isDarkMode.set(prefersDark);
    } else {
      root.classList.add(`${theme}-theme`);
      this.isDarkMode.set(theme === 'dark');
    }
  }

  private setupSystemThemeListener(): void {
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    
    mediaQuery.addEventListener('change', (e) => {
      if (this.currentTheme() === 'auto') {
        const root = document.documentElement;
        root.classList.remove('light-theme', 'dark-theme');
        root.classList.add(e.matches ? 'dark-theme' : 'light-theme');
        this.isDarkMode.set(e.matches);
      }
    });
  }

  toggleTheme(): void {
    const currentTheme = this.currentTheme();
    if (currentTheme === 'light') {
      this.setTheme('dark');
    } else if (currentTheme === 'dark') {
      this.setTheme('auto');
    } else {
      this.setTheme('light');
    }
  }
}