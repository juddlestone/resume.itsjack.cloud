// Theme toggle functionality
function initTheme() {
    // Check for saved theme preference, defaulting to system preference
    const savedTheme = localStorage.getItem('theme');
    const systemPrefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    
    if (savedTheme === 'dark' || (!savedTheme && systemPrefersDark)) {
        document.documentElement.classList.add('dark');
    }
}

function toggleTheme() {
    const html = document.documentElement;
    const isDark = html.classList.toggle('dark');
    
    // Save preference
    localStorage.setItem('theme', isDark ? 'dark' : 'light');
}

// Initialize theme
initTheme();

// Add click event listener to toggle button
document.getElementById('themeToggle').addEventListener('click', toggleTheme);

// Optional: Listen for system theme changes
window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
    if (!localStorage.getItem('theme')) {  // Only auto-switch if user hasn't set a preference
        if (e.matches) {
            document.documentElement.classList.add('dark');
        } else {
            document.documentElement.classList.remove('dark');
        }
    }
});


// Theme toggling functionality
document.addEventListener('DOMContentLoaded', function() {
    // Check for saved theme preference or use default
    const currentTheme = localStorage.getItem('theme') || 'light';
    document.body.setAttribute('data-theme', currentTheme);
    
    // Set up theme toggle button
    const themeToggle = document.getElementById('themeToggle');
    themeToggle.addEventListener('click', function() {
        const currentTheme = document.body.getAttribute('data-theme');
        const newTheme = currentTheme === 'light' ? 'dark' : 'light';
        
        document.body.setAttribute('data-theme', newTheme);
        localStorage.setItem('theme', newTheme);
    });
    
    // Fetch visitor count from the API
    fetchVisitorCount();
});

// Function to get visitor count from the API
function fetchVisitorCount() {
    const counterElement = document.getElementById('counter');
    
    fetch('/get_visitor_count')
        .then(response => {
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            return response.json();
        })
        .then(data => {
            if (data.error) {
                counterElement.textContent = 'Visitor count unavailable';
                console.error('Error fetching visitor count:', data.error);
            } else {
                counterElement.textContent = `${data.count}`;
            }
        })
        .catch(error => {
            counterElement.textContent = 'Visitor count unavailable';
            console.error('Error fetching visitor count:', error);
        });
}