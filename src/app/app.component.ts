import { Component, inject, OnInit, signal } from "@angular/core";
import { RouterOutlet } from "@angular/router";
import { BlockUIModule } from 'primeng/blockui';
import { Spinner } from "./shared/services/spinner";

@Component({
  selector: "app-root",
  imports: [RouterOutlet, BlockUIModule],
  templateUrl: "./app.component.html",
  styleUrl: "./app.component.css",
})
export class AppComponent implements OnInit {
  title = 'NoteKeeper';
  blockUI = signal(false);

  private readonly spinner = inject(Spinner);

  ngOnInit() {
    this.spinner.showEvent.subscribe(() => {
      this.blockUI.set(true);
    });

    this.spinner.hideEvent.subscribe(() => {
      this.blockUI.set(false);
    });
  }

}
