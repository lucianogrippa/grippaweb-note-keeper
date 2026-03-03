import { Component, inject, OnInit } from "@angular/core";
import { Router, RouterOutlet } from "@angular/router";
import { ThemeService } from "./core/theme.service";
import { listen } from '@tauri-apps/api/event';

@Component({
  selector: "app-root",
  imports: [RouterOutlet],
  templateUrl: "./app.component.html",
  styleUrl: "./app.component.css",
})
export class AppComponent implements OnInit {
  title = 'NoteKeeper';
  private themeService = inject(ThemeService);
  private router = inject(Router);

  ngOnInit() {
    listen("setup_master_password", () => {
      this.router.navigate(["/setup"]);
    });
  }

}
