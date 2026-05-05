import { EventEmitter, Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root',
})
export class Spinner {
  
  showEvent = new EventEmitter<void>();
  hideEvent = new EventEmitter<void>();


  show(): void {
    this.showEvent.emit();
  }
  
  hide(): void {
    this.hideEvent.emit();
  }
}
