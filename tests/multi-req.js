import http from 'k6/http';
import { check } from 'k6';
import { Trend } from 'k6/metrics';

export const options = {
    scenarios: {
        burst: {
            executor: 'shared-iterations',
            vus: __ENV.VUS ? parseInt(__ENV.VUS, 10) : 100,
            iterations: __ENV.ITER ? parseInt(__ENV.ITER, 10) : 100000,
            maxDuration: __ENV.MAX_DURATION || '10m',
        },
    },
    thresholds: {
        http_req_duration: ['p(95)<2000', 'p(99)<5000'],
    },
};

const url = __ENV.BASE_URL || 'http://localhost:8080/';
const latency = new Trend('latency');

export default function () {
    const res = http.get(url);
    latency.add(res.timings.duration);
    check(res, {
        'status is 200': r => r.status === 200,
        'body ok': r => r.body && r.body.indexOf('Hello, world') !== -1,
    });
}
