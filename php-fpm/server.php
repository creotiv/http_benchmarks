<?php

const ITERATIONS = 20;
const MODULUS = 1000003;

function cpu_work(int $iterations = ITERATIONS): int
{
    $acc = 0;
    for ($i = 0; $i < $iterations; $i++) {
        $value = $i;
        for ($j = 0; $j < $iterations; $j++) {
            $value = ($value * 31 + $j) % MODULUS;
        }
        $acc = ($acc + $value) % MODULUS;
    }

    return $acc;
}

header("Content-Type: text/plain");
echo "Hello, world " . cpu_work();
