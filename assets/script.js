// document.addEventListener('DOMContentLoaded', function() {
//     fetch('https://func-cloud-resume-counter.azurewebsites.net/api/visitor-counter')
//     .then(response => {
//         if (!response.ok) {
//             throw new Error('HTTP status ' + response.status);
//         }
//         return response.text();
//     })
//     .then(data => {
//         console.log('Visitor count received:', data); // Log the data for debugging
//         document.getElementById('counter').innerText = data;
//     })
//     .catch(error => {
//         console.error('Fetch operation error:', error);
//         document.getElementById('counter').innerText = 'Error loading count: ' + error.message;
//     });
// });

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