const http = require('http');

const options = {
    host: 'localhost',
    port: process.env.PORT || 3000,
    path: '/health',
    timeout: 2000
};

const request = http.request(options, (res) => {
    console.log(`Health check status: ${res.statusCode}`);
    process.exit(res.statusCode === 200 ? 0 : 1);
});

request.on('error', (err) => {
    console.error('Health check failed:', err);
    process.exit(1);
});

request.end();
