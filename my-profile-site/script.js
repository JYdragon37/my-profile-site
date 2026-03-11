// ========================================
// THEME MANAGEMENT
// ========================================

class ThemeManager {
    constructor() {
        this.themeKey = 'profile-theme';
        this.lightTheme = 'light';
        this.darkTheme = 'dark';
        this.init();
    }

    init() {
        // Initialize theme on page load
        const savedTheme = this.getSavedTheme();
        const systemTheme = this.getSystemTheme();
        const theme = savedTheme || systemTheme;
        this.setTheme(theme, false);

        // Listen for theme toggle button
        const themeToggle = document.getElementById('themeToggle');
        if (themeToggle) {
            themeToggle.addEventListener('click', () => this.toggleTheme());
        }

        // Listen for system theme changes
        if (window.matchMedia) {
            window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
                if (!this.getSavedTheme()) {
                    this.setTheme(e.matches ? this.darkTheme : this.lightTheme);
                }
            });
        }
    }

    getSavedTheme() {
        return localStorage.getItem(this.themeKey);
    }

    getSystemTheme() {
        if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
            return this.darkTheme;
        }
        return this.lightTheme;
    }

    setTheme(theme, savePreference = true) {
        const html = document.documentElement;
        html.setAttribute('data-theme', theme);

        if (savePreference) {
            localStorage.setItem(this.themeKey, theme);
        }

        // Update theme toggle icon visibility
        this.updateThemeIcon(theme);
    }

    toggleTheme() {
        const currentTheme = document.documentElement.getAttribute('data-theme') || this.lightTheme;
        const newTheme = currentTheme === this.lightTheme ? this.darkTheme : this.lightTheme;
        this.setTheme(newTheme, true);
    }

    updateThemeIcon(theme) {
        const sunIcon = document.querySelector('.sun-icon');
        const moonIcon = document.querySelector('.moon-icon');

        if (sunIcon && moonIcon) {
            if (theme === this.darkTheme) {
                sunIcon.style.display = 'block';
                moonIcon.style.display = 'none';
            } else {
                sunIcon.style.display = 'none';
                moonIcon.style.display = 'block';
            }
        }
    }
}

// ========================================
// MOBILE MENU
// ========================================

class MobileMenu {
    constructor() {
        this.toggleBtn = document.getElementById('mobileMenuToggle');
        this.menu = document.getElementById('mobileMenu');
        this.menuIcon = this.toggleBtn?.querySelector('.menu-icon');
        this.closeIcon = this.toggleBtn?.querySelector('.close-icon');
        this.init();
    }

    init() {
        if (!this.toggleBtn) return;

        // Toggle menu on button click
        this.toggleBtn.addEventListener('click', () => this.toggle());

        // Close menu when clicking on a link
        const links = this.menu?.querySelectorAll('a');
        links?.forEach(link => {
            link.addEventListener('click', () => this.close());
        });

        // Close menu when clicking outside
        document.addEventListener('click', (e) => {
            if (!this.toggleBtn.contains(e.target) && !this.menu.contains(e.target)) {
                this.close();
            }
        });
    }

    toggle() {
        this.menu.classList.contains('hidden') ? this.open() : this.close();
    }

    open() {
        this.menu.classList.remove('hidden');
        this.menuIcon?.classList.add('hidden');
        this.closeIcon?.classList.remove('hidden');
    }

    close() {
        this.menu.classList.add('hidden');
        this.menuIcon?.classList.remove('hidden');
        this.closeIcon?.classList.add('hidden');
    }
}

// ========================================
// NAVIGATION & SCROLL
// ========================================

class Navigation {
    constructor() {
        this.sections = document.querySelectorAll('[id]');
        this.navLinks = document.querySelectorAll('a[href^="#"]');
        this.navbar = document.getElementById('navbar');
        this.init();
    }

    init() {
        // Smooth scroll behavior for nav links
        this.navLinks.forEach(link => {
            link.addEventListener('click', (e) => {
                const href = link.getAttribute('href');
                if (href !== '#') {
                    e.preventDefault();
                    const target = document.querySelector(href);
                    if (target) {
                        target.scrollIntoView({ behavior: 'smooth' });
                    }
                }
            });
        });

        // Update active nav item on scroll
        window.addEventListener('scroll', () => this.updateActiveNav());
    }

    updateActiveNav() {
        let currentSection = '';

        this.sections.forEach(section => {
            const sectionTop = section.offsetTop;
            const sectionHeight = section.clientHeight;

            if (window.pageYOffset >= sectionTop - 100) {
                currentSection = section.getAttribute('id');
            }
        });

        this.navLinks.forEach(link => {
            link.classList.remove('active');
            if (link.getAttribute('href') === `#${currentSection}`) {
                link.classList.add('active');
            }
        });

        // Add shadow to navbar on scroll
        if (window.pageYOffset > 10) {
            this.navbar.style.boxShadow = '0 2px 10px rgba(0, 0, 0, 0.1)';
        } else {
            this.navbar.style.boxShadow = 'none';
        }
    }
}

// ========================================
// SCROLL ANIMATIONS
// ========================================

class ScrollAnimations {
    constructor() {
        this.fadeElements = document.querySelectorAll('.fade-in');
        this.init();
    }

    init() {
        if (!('IntersectionObserver' in window)) {
            // Fallback for browsers that don't support IntersectionObserver
            this.fadeElements.forEach(el => {
                el.style.opacity = '1';
                el.style.transform = 'translateY(0)';
            });
            return;
        }

        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const delay = entry.target.style.animationDelay || '0s';
                    entry.target.style.animationDelay = delay;
                    entry.target.style.opacity = '1';
                    entry.target.style.transform = 'translateY(0)';
                    observer.unobserve(entry.target);
                }
            });
        }, {
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        });

        this.fadeElements.forEach(el => {
            observer.observe(el);
        });
    }
}

// ========================================
// BACK TO TOP BUTTON
// ========================================

class BackToTop {
    constructor() {
        this.button = document.getElementById('backToTop');
        this.init();
    }

    init() {
        if (!this.button) return;

        window.addEventListener('scroll', () => this.handleScroll());
        this.button.addEventListener('click', () => this.scrollToTop());
    }

    handleScroll() {
        if (window.pageYOffset > 300) {
            this.button.classList.remove('hidden');
        } else {
            this.button.classList.add('hidden');
        }
    }

    scrollToTop() {
        window.scrollTo({
            top: 0,
            behavior: 'smooth'
        });
    }
}

// ========================================
// EMAIL COPY FUNCTIONALITY
// ========================================

class EmailCopy {
    constructor() {
        this.emailLink = document.querySelector('a[href^="mailto:"]');
        this.init();
    }

    init() {
        if (!this.emailLink) return;

        this.emailLink.addEventListener('click', (e) => {
            e.preventDefault();
            const email = this.extractEmail();
            this.copyToClipboard(email);
        });
    }

    extractEmail() {
        const href = this.emailLink.getAttribute('href');
        return href.replace('mailto:', '');
    }

    copyToClipboard(text) {
        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(text).then(() => {
                this.showFeedback();
            }).catch(err => {
                console.error('Failed to copy:', err);
                this.fallbackCopy(text);
            });
        } else {
            this.fallbackCopy(text);
        }
    }

    fallbackCopy(text) {
        const textarea = document.createElement('textarea');
        textarea.value = text;
        document.body.appendChild(textarea);
        textarea.select();
        try {
            document.execCommand('copy');
            this.showFeedback();
        } catch (err) {
            console.error('Failed to copy:', err);
        }
        document.body.removeChild(textarea);
    }

    showFeedback() {
        const originalText = this.emailLink.textContent;
        this.emailLink.textContent = '✓ Copied to clipboard!';

        setTimeout(() => {
            this.emailLink.textContent = originalText;
        }, 2000);
    }
}

// ========================================
// MAIN INITIALIZATION
// ========================================

document.addEventListener('DOMContentLoaded', () => {
    // Initialize all components
    const themeManager = new ThemeManager();
    const mobileMenu = new MobileMenu();
    const navigation = new Navigation();
    const scrollAnimations = new ScrollAnimations();
    const backToTop = new BackToTop();
    const emailCopy = new EmailCopy();

    console.log('Portfolio website initialized successfully!');
});

// ========================================
// UTILITY FUNCTIONS
// ========================================

// Debounce function for performance optimization
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Handle window resize for responsive behavior
let resizeTimer;
window.addEventListener('resize', debounce(() => {
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(() => {
        // Handle any resize-specific logic here
    }, 250);
}, 250));
