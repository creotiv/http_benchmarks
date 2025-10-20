<?php

// Requires the OpenSwoole extension (the base image below provides it)
$host = "0.0.0.0";
$port = 9501;

function cpu_work(int $iterations = 20): int
{
    $acc = 0;
    for ($i = 0; $i < $iterations; $i++) {
        $value = $i;
        for ($j = 0; $j < $iterations; $j++) {
            $value = ($value * 31 + $j) % 1000003;
        }
        $acc = ($acc + $value) % 1000003;
    }

    return $acc;
}

// SWOOLE_BASE avoids process manager overhead; feel free to test SWOOLE_PROCESS too.
$server = new OpenSwoole\Http\Server($host, $port, SWOOLE_BASE);

$server->set([
    'worker_num' => 1,               // keep fair vs other stacks
    'reactor_num' => 1,
    'task_worker_num' => 0,
    'http_compression' => false,
    'enable_coroutine' => true,
    'max_coroutine' => 200000,
    'enable_reuse_port' => false,
]);

$server->on("request", function ($req, $res) {
    $res->header("Content-Type", "text/plain");
    $result = cpu_work();
    $res->end("Hello, world " . $result);
});

$server->start();
