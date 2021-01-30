#!/bin/sh
while ! qsub 10642; do
  sleep 10
done
echo "hello world"
sleep 30
qfinish 10642
