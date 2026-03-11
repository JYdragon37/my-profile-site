# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Bucket List** is a personal goal-tracking web application. It lets users add, edit, delete, and track progress on life goals with persistent local storage. Zero backend, zero external dependencies (Tailwind CSS via CDN only).

## Running the Application

### Quick Start
- **Direct**: Double-click `index.html` in file explorer, or drag to browser
- **VS Code Live Server**: Right-click `index.html` → "Open with Live Server"
- **Python server**: `python -m http.server 8000` then visit `http://localhost:8000`

No build process, no npm install required. The app runs immediately in any modern browser.

## Code Architecture

### Separation of Concerns
- **`js/storage.js`**: Data layer (LocalStorage API wrapper). Pure data operations with no UI logic.
  - Methods: `load()`, `save()`, `addItem()`, `updateItem()`, `deleteItem()`, `toggleComplete()`, `getStats()`, `getFilteredList()`
  - Returns: Arrays of bucket items or stats objects

- **`js/app.js`**: Presentation layer (BucketListApp class). Manages UI, events, rendering.
  - Depends on `BucketStorage` (from storage.js)
  - Methods: event handlers (`handleAdd`, `handleDelete`, etc.), `render()`, `updateStats()`
  - Never touches localStorage directly—always goes through BucketStorage

- **`index.html`**: UI structure using Tailwind CSS (CDN) + semantic HTML5
- **`css/styles.css`**: Custom CSS enhancements: animations, filter button states, responsive tweaks, dark mode support

### Data Model
Each bucket item is a plain object:
```javascript
{
  id: "1730880000000",           // timestamp-based unique ID
  title: "Goal title",
  completed: false,
  createdAt: "2025-11-06T...",   // ISO string
  completedAt: null              // ISO string or null
}
```
All items stored in single localStorage key: `bucketList` (JSON array).

### Key Design Decisions
- **No framework**: Vanilla JS keeps the codebase tiny and easy to understand
- **Class-based app**: `BucketListApp` class encapsulates UI state and logic
- **Modular storage**: `BucketStorage` object can be tested and extended independently
- **Functional updates**: `render()` rebuilds UI from current state (no diffing needed at this scale)
- **HTML escaping**: `escapeHtml()` prevents XSS vulnerabilities

## File Responsibilities

| File | Purpose |
|------|---------|
| `index.html` | DOM structure, modal, filter buttons, input form, stats display |
| `js/storage.js` | All localStorage interactions; data validation and transformation |
| `js/app.js` | DOM event listeners, render logic, user input handling |
| `css/styles.css` | Animations, responsive media queries, theme enhancements |
| `README.md` | User-facing documentation and feature list |

## Common Development Tasks

### Adding a New Feature
1. **If it involves data**: Add method to `BucketStorage` first (no side effects)
2. **If it involves UI**: Add event handler in `BucketListApp`, then update `render()`
3. **Always call `render()`** after state changes to update the view
4. **Test in browser** by opening `index.html`—no build step needed

### Modifying Display Logic
- Edit `createBucketItemHTML()` to change how items render
- Edit `render()` to control when/what is displayed
- Add CSS to `styles.css` (prefer Tailwind classes in HTML first)

### Changing Data Structure
- Update the item object in `addItem()`
- Update `getStats()` if statistics calculation changes
- Update `createBucketItemHTML()` to display new fields

### Styling
- Use **Tailwind classes** (CDN) for most styling
- Add custom CSS to `styles.css` only when Tailwind doesn't suffice
- Keep animations in `styles.css` (slideIn, fadeIn, scaleIn already defined)

## Browser Compatibility

All modern browsers (Chrome, Firefox, Safari, Edge) that support:
- ES6+ JavaScript (classes, arrow functions, template literals)
- LocalStorage API
- CSS Grid/Flexbox

## Testing Approach

No automated tests. Verify changes manually:
1. Open `index.html` in browser
2. Test affected features: add/edit/delete/filter/complete
3. Check responsive design in DevTools (mobile 320px, tablet 768px, desktop 1024px+)
4. Verify data persists after refresh (check localStorage in DevTools)

## Performance Considerations

- DOM element caching in `cacheElements()` avoids repeated `querySelector` calls
- `render()` fully rebuilds the list—acceptable at current scale (typical use ~20-50 items)
- LocalStorage is synchronous and small (~50KB limit per domain), fine for this use case

## Key Gotchas

- **Always call `render()`** after data changes—UI won't update otherwise
- **`BucketStorage` methods handle load/save**—never modify localStorage directly
- **HTML escaping required**: User input in `createBucketItemHTML()` uses `escapeHtml()` to prevent XSS
- **Modal state**: `editingId` tracks which item is being edited; check before save
- **Filter state**: Current filter stored in `this.currentFilter`; affects what `render()` displays

## Future Enhancements (From README)

Priority order unclear, but these are documented:
- Category/tag grouping
- Image attachments
- Detailed notes
- Goal deadlines
- Priority levels
- Import/export (JSON)
- Dark mode toggle UI (CSS-only support exists)
- Drag-to-reorder

Consider adding a persistent sorting order to data model if drag-reorder is implemented.
