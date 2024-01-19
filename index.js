const express = require('express');
    const { MongoClient } = require('mongodb');

    const app = express();
    const port = 3000;
    const mongoURI = 'mongodb://${aws_instance.mongo_server.public_ip}:27017/test';

    let db; 
    let mensaje;

    app.use(async (req, res, next) => {
    try {
        if (!db) {
        const client = new MongoClient(mongoURI);
        await client.connect();
        db = client.db();
        mensaje = 'Conectado a MongoDB';
        }

        req.db = db;
        next();
    } catch (error) {
        console.error('Error connecting to MongoDB:', error);
        res.status(500).send('Internal Server Error');
    }
    });
    app.get('/', (req, res) => { res.send(mensaje) });

    app.listen(port, () => { console.log(`Escucha en el puerto ${port}`) });