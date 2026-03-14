import { Injectable } from '@angular/core';
import {
  sendNotification,
} from '@tauri-apps/plugin-notification';

@Injectable({
  providedIn: 'root',
})
export class Notification {

  async showNotification(title: string, body: string) {
    if (typeof window === 'undefined' || !('Notification' in window)) {
      return;
    }

    let permissionGranted = window.Notification.permission === 'granted';

    // Request browser/webview notification permission without invoking a Tauri command.
    if (!permissionGranted && window.Notification.permission === 'default') {
      const permission = await window.Notification.requestPermission();
      permissionGranted = permission === 'granted';
    }

    if (permissionGranted) {
      try {
        sendNotification({ title, body });
      } catch {
        // Keep auth/setup flow resilient if notification delivery is unavailable.
      }
    }
  }
}
