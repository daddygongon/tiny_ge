#!/bin/sh
while ! qsub 2301; do
  sleep 10
done
echo "hello world"
sleep 30
  qfinish 2301
