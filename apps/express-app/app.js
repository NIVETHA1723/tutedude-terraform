const express = require('express');
const axios = require('axios');
const app = express();
const port = 3000;

// Backend URL can be passed via environment variable
const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:5000';

app.get('/', async (req, res) => {
    try {
        const response = await axios.get(`${BACKEND_URL}/api`);
        res.send(`
            <h1>Hello from Express Frontend!</h1>
            <p>Data from Backend: ${JSON.stringify(response.data)}</p>
            <p>Backend URL: ${BACKEND_URL}</p>
        `);
    } catch (error) {
        res.send(`
            <h1>Hello from Express Frontend!</h1>
            <p>Error calling backend: ${error.message}</p>
            <p>Backend URL attempted: ${BACKEND_URL}</p>
        `);
    }
});

app.listen(port, '0.0.0.0', () => {
    console.log(`Express app listening at http://0.0.0.0:${port}`);
});
