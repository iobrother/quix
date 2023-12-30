#!/bin/bash

# 先杀死所有skynet进程
killall skynet

if [ -z $1 ]; then
    ./skynet/skynet etc/config &
else
    ./skynet/skynet etc/config.center &
    ./skynet/skynet etc/config.db &
    ./skynet/skynet etc/config.scene &
    ./skynet/skynet etc/config.game &
    ./skynet/skynet etc/config.im &
    ./skynet/skynet etc/config.api &
fi

