#!/bin/sh
while ! qsub 21934; do
  sleep 10
done

sh /home/bob/tiny_ge/test/check_ve.sh

qfinish 21934
