# JY - IT Consultant Portfolio Website

A modern, professional portfolio website built with HTML, CSS, and JavaScript featuring a light/dark theme toggle and responsive design.

## 🌟 Features

- **Light/Dark Theme Toggle** - Seamless theme switching with localStorage persistence
- **Responsive Design** - Optimized for mobile, tablet, and desktop devices
- **Smooth Animations** - Fade-in effects and scroll animations using Intersection Observer API
- **Professional McKinsey-Style Design** - Clean layout with emphasis on whitespace and clarity
- **Mobile-Friendly Navigation** - Hamburger menu for mobile devices
- **Email Copy Functionality** - Click email to copy to clipboard
- **Back to Top Button** - Quick navigation to page top
- **Modern Typography** - IBM Plex Sans for body text and Playfair Display for headings
- **Accessibility** - Semantic HTML, keyboard navigation support, focus states

## 📁 Project Structure

```
my-profile-site/
├── index.html          # Main HTML file with page structure
├── styles.css          # Custom CSS with theme variables
├── script.js           # JavaScript for interactivity
├── README.md           # Project documentation
└── assets/             # (Optional) For future images/icons
```

## 🛠 Tech Stack

- **HTML5** - Semantic markup
- **CSS3** - Custom properties, flexbox, grid, animations
- **JavaScript (ES6+)** - Component-based architecture
- **Tailwind CSS** - CDN-based utility classes
- **Google Fonts** - IBM Plex Sans, Playfair Display

## 🎨 Design System

### Light Theme
- **Background**: White (#FFFFFF), Light Gray (#F8F9FA)
- **Text**: Dark Gray (#1A1A1A), Medium Gray (#4A4A4A)
- **Accent**: McKinsey Blue (#0066CC), Dark Blue (#003D82)
- **Border**: Light Gray (#E0E0E0)

### Dark Theme
- **Background**: Dark Gray (#1A1A1A), Darker Gray (#2A2A2A)
- **Text**: Light Gray (#F5F5F5), Medium Gray (#B0B0B0)
- **Accent**: Bright Blue (#4A9EFF), Light Blue (#6BB5FF)
- **Border**: Dark Gray (#404040)

## 🚀 Getting Started

### Local Development

1. **Clone or download the project**
   ```bash
   cd my-profile-site
   ```

2. **Option A: Open directly in browser**
   ```bash
   # Simply open index.html in your web browser
   open index.html
   # or right-click and select "Open with Browser"
   ```

3. **Option B: Run with a local server** (recommended)
   ```bash
   # Using Python 3
   python3 -m http.server 8000
   # or using Python 2
   python -m SimpleHTTPServer 8000

   # Using Node.js
   npx serve

   # Using PHP
   php -S localhost:8000
   ```

4. **Open in browser**
   - Navigate to `http://localhost:8000`

## 📱 Responsive Breakpoints

- **Mobile**: < 640px
- **Tablet**: 640px - 768px
- **Desktop**: > 768px

## 🎛 Customization Guide

### Change User Information

Edit `index.html` to update:
- Name and title (Hero section)
- Bio and introduction (About section)
- Tech stack cards (customize skills and descriptions)
- Project portfolio (add/remove project cards)
- Contact email

### Modify Colors

Edit the CSS custom properties at the top of `styles.css`:

```css
/* Light Theme */
:root {
    --accent-primary: #0066cc;      /* Change primary color */
    --accent-secondary: #003d82;    /* Change secondary color */
    /* ... other properties */
}

/* Dark Theme */
html[data-theme="dark"] {
    --accent-primary: #4a9eff;      /* Change dark theme primary */
    /* ... other properties */
}
```

### Add Projects

In `index.html`, duplicate a project card in the Projects section:

```html
<article class="project-card fade-in">
    <div class="project-image"></div>
    <div class="project-content">
        <h3 class="text-xl font-bold mb-2">Project Title</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
            Project description goes here.
        </p>
        <div class="tech-tags">
            <span>Technology 1</span>
            <span>Technology 2</span>
        </div>
    </div>
</article>
```

### Add Project Images

1. Create an `assets/images/` directory
2. Add your project images
3. Update the CSS to use background images:

```css
.project-image {
    background-image: url('assets/images/project1.jpg');
    background-size: cover;
    background-position: center;
}
```

### Adjust Theme Transition Speed

Edit the transition duration in `styles.css`:

```css
:root {
    --transition-duration: 0.3s;  /* Change to 0.5s for slower transitions */
}
```

## 🌐 Deployment

### GitHub Pages

1. Create a GitHub repository named `my-profile-site`
2. Push all files to the repository
3. Go to Settings → Pages
4. Select "main" branch as source
5. Your site will be live at `https://yourusername.github.io/my-profile-site`

### Netlify

1. Sign up at [Netlify](https://netlify.com)
2. Click "New site from Git"
3. Connect your GitHub repository
4. Build settings:
   - Build command: (leave empty)
   - Publish directory: `/`
5. Deploy!

### Vercel

1. Sign up at [Vercel](https://vercel.com)
2. Import your GitHub repository
3. Deploy with default settings
4. Your site will be live immediately

### Traditional Hosting

1. Upload all files to your web server via FTP/SFTP
2. Ensure `index.html` is in the root directory
3. Access your site via your domain

## 🔧 Features in Detail

### Theme Toggle
- Click the sun/moon icon in the navigation to switch themes
- Your preference is saved in localStorage
- Automatically uses system preference on first visit

### Mobile Menu
- Hamburger menu appears on screens < 768px
- Auto-closes when clicking a link
- Auto-closes when clicking outside

### Smooth Scrolling
- All navigation links smoothly scroll to sections
- Active section is highlighted in the menu
- Shadow appears on navbar when scrolling

### Animations
- Elements fade in when scrolling into view
- Cards have lift effect on hover
- Smooth color transitions between themes

### Email Copy
- Click the email address to copy it to clipboard
- Shows confirmation message
- Works in all modern browsers

## ♿ Accessibility Features

- Semantic HTML5 structure
- ARIA labels for interactive elements
- Keyboard navigation support
- Focus states for all interactive elements
- Sufficient color contrast for readability
- Respects `prefers-reduced-motion` preference

## 📊 Performance

- Lightweight CSS without heavy frameworks
- Minimal JavaScript for fast load times
- CSS animations for smooth 60fps performance
- Lazy loading for scroll animations
- Optimized for Core Web Vitals

## 🐛 Troubleshooting

### Theme not persisting
- Check if localStorage is enabled in your browser
- Clear browser cache and try again
- Check browser console for errors

### Smooth scroll not working
- Ensure JavaScript is enabled
- Try opening in a different browser
- Check for JavaScript errors in console

### Mobile menu not working
- Ensure JavaScript file is loaded correctly
- Check console for any error messages
- Verify screen width is < 768px

## 📝 Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)
- Mobile browsers (iOS Safari, Chrome for Android)

## 📄 License

This project is open source and available for personal and commercial use.

## 🤝 Contributing

Feel free to fork, modify, and customize this template for your needs!

## 📞 Support

For issues or questions, check the code comments or review the included documentation.

---

**Built with ❤️ for professional portfolios**

Last updated: 2024
