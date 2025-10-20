import cluster from 'node:cluster';
import http from 'node:http';
import os from 'node:os';

const ITERATIONS = 20;
const MODULUS = 1_000_003;
const PORT = Number(process.env.PORT || 3000);
const WORKERS = Number(process.env.WORKERS || 4);

function cpuWork(iterations = ITERATIONS) {
    let acc = 0;
    for (let i = 0; i < iterations; i++) {
        let value = i;
        for (let j = 0; j < iterations; j++) {
            value = (value * 31 + j) % MODULUS;
        }
        acc = (acc + value) % MODULUS;
    }
    return acc;
}

if (cluster.isPrimary) {
    const desiredWorkers = Math.min(WORKERS, os.cpus().length || 1);
    console.log(`Primary ${process.pid} starting ${desiredWorkers} workers`);
    for (let i = 0; i < desiredWorkers; i += 1) {
        cluster.fork();
    }
    cluster.on('exit', (worker, code, signal) => {
        console.warn(`Worker ${worker.process.pid} exited (code=${code}, signal=${signal}); restarting`);
        cluster.fork();
    });
} else {
    const server = http.createServer((req, res) => {
        const result = cpuWork();
        res.statusCode = 200;
        res.setHeader('Content-Type', 'text/plain');
        res.end(`Hello, world ${result}`);
    });

    server.listen(PORT, '0.0.0.0', () => {
        console.log(`Worker ${process.pid} listening on ${PORT}`);
    });
}
