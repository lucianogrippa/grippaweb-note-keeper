# Global UI Style Guide

Use these classes from the global stylesheet in `src/styles.css`.

## Color palette tokens

- `--color-primary`, `--color-primary-hover`
- `--color-secondary`, `--color-secondary-hover`
- `--color-accent`, `--color-accent-hover`
- `--color-highlight`, `--color-highlight-hover`
- `--gradient-primary`, `--gradient-secondary`, `--gradient-accent`

## Reusable components

### Cards

- `.card`
- `.glass-card`

### Badges

- `.badge`

### Buttons

- Base: `.btn`
- Variants: `.btn-primary`, `.btn-secondary`, `.btn-accent`, `.btn-ghost`, `.btn-danger`
- Sizes: `.btn-sm`, `.btn-lg`

### Inputs

- `.input`
- `.textarea`
- `.select`

## Typography helpers

- `.text-gradient`
- `.section-title`
- `.section-subtitle`

## Example usage

```html
<div class="card">
  <h2 class="section-title text-gradient">Dashboard</h2>
  <p class="section-subtitle">Manage your secure notes</p>

  <div style="display:flex; gap: .5rem; margin-top: .75rem;">
    <button class="btn btn-primary">Save</button>
    <button class="btn btn-secondary">Sync</button>
    <button class="btn btn-ghost">Cancel</button>
  </div>

  <div style="margin-top: 1rem;">
    <input class="input" placeholder="Search notes" />
  </div>

  <div style="margin-top: .75rem;">
    <span class="badge">Encrypted</span>
  </div>
</div>
```
