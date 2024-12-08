#!/bin/bash

sleep 1 &

wait

echo "Processus zombie créé avec PID $!"

while true; do
    sleep 1
done
