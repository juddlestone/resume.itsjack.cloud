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



// API Visitor Counter
fetch('https://func-cloud-resume-counter.azurewebsites.net/api/visitor-counter')
.then(response => {
    if (!response.ok) {
        throw new Error('HTTP status ' + response.status);
    }
    return response.text();
})
.then(data => {
    console.log('Visitor count received:', data); // Log the data for debugging
    document.getElementById('counter').innerText = data;
})
.catch(error => {
    console.error('Fetch operation error:', error);
    document.getElementById('counter').innerText = 'Error loading count: ' + error.message;
});