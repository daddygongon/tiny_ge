#!/bin/sh

while ! ../lib/check_ve_lock $$; do
  sleep 10
done
echo "hello world"

sleep 30

../lib/unlock_ve_lock $$
