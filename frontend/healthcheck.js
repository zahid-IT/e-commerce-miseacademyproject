const http = require('http');

const options = {
    host: 'localhost',
    port: 80,
    path: '/',
    timeout: 2000
};

const request = http.request(options, (res) => {
    console.log(`Frontend health check status: ${res.statusCode}`);
    process.exit(res.statusCode === 200 ? 0 : 1);
});

request.on('error', (err) => {
    console.error('Frontend health check failed:', err);
    process.exit(1);
});

request.end();
