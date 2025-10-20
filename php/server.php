<?php

// Requires the OpenSwoole extension (the base image below provides it)
$host = "0.0.0.0";
$port = 9501;

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
    $res->end("Hello, world");
});

$server->start();
