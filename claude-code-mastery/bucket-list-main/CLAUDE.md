# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Bucket List** web application built with vanilla JavaScript (no frameworks). It's a static web app that uses LocalStorage for data persistence, requiring no backend server or build process.

## Running the Application

**Option 1: Direct File Open**
Simply open `index.html` in a web browser (double-click or drag into browser).

**Option 2: Local Server (Recommended for development)**
```bash
# Python 3
python -m http.server 8000

# Then open http://localhost:8000
```

**Option 3: VS Code Live Server**
Right-click `index.html` → "Open with Live Server"

## Architecture

The codebase follows a **modular separation of concerns**:

### Data Layer: `js/storage.js`
- `BucketStorage` object handles all LocalStorage operations
- All CRUD operations go through this module
- Provides data filtering and statistics calculation
- Key methods: `load()`, `save()`, `addItem()`, `updateItem()`, `deleteItem()`, `toggleComplete()`, `getStats()`, `getFilteredList()`

### Presentation Layer: `js/app.js`
- `BucketListApp` class manages UI rendering and user interactions
- Interacts with `BucketStorage` for all data operations
- Handles DOM manipulation, event binding, and state management
- Never directly accesses LocalStorage (always goes through `BucketStorage`)

### Styling: `css/styles.css`
- Complements Tailwind CSS (loaded via CDN)
- Contains custom animations, responsive breakpoints, and theme customizations
- Includes dark mode support via `prefers-color-scheme`

## Data Structure

Items in LocalStorage follow this schema:
```javascript
{
  id: "1730880000000",      // Timestamp-based unique ID
  title: "세계 일주하기",    // Bucket list item text
  completed: false,          // Completion status
  createdAt: "2025-11-06",  // ISO date string
  completedAt: null         // ISO date string (only when completed)
}
```

Storage key: `'bucketList'` in LocalStorage

## Code Conventions

- **Language**: Korean comments throughout the codebase
- **JavaScript**: ES6+ features (classes, arrow functions, template literals)
- **HTML**: Inline event handlers using `onclick` (e.g., `onclick="app.handleToggle('${item.id}')"`)
- **CSS**: Tailwind utility classes in HTML + custom CSS for animations
- **No build tools**: No webpack, no npm scripts, no transpilation

## Key Implementation Details

### Adding New Features
When adding functionality:
1. Add data operations to `BucketStorage` in `storage.js`
2. Add UI logic to `BucketListApp` in `app.js`
3. Update the render method if new UI elements are needed
4. Maintain the separation: UI layer never directly touches LocalStorage

### Security Note
The app uses `escapeHtml()` method (line 223 in app.js) to prevent XSS when rendering user input. Always use this when inserting user-provided text into the DOM.

### Modal Pattern
The edit modal (`#editModal`) uses:
- Hidden by default with `hidden` class
- Shown with `flex` class for centering
- Closes on backdrop click or cancel button
- Stores editing state in `this.editingId`

### Filter System
Three filter states managed via `currentFilter` property:
- `'all'`: Show all items
- `'active'`: Show incomplete items only
- `'completed'`: Show completed items only

Filter buttons use `data-filter` attribute and `.active` class for visual state.

## Browser Compatibility

Requires modern browser with LocalStorage support. The app uses:
- LocalStorage API
- ES6+ JavaScript (classes, arrow functions, template literals)
- CSS Grid and Flexbox
- CSS animations

## Future Enhancement Ideas (from README)

The README lists these potential improvements:
- Category/tag system
- Image attachments
- Target date setting
- Priority levels
- JSON export/import
- Drag-and-drop sorting

When implementing these, maintain the existing architectural pattern of separating data operations (storage.js) from UI logic (app.js).
