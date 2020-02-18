#!/bin/sh

if [ $# -eq 1 ] && [ "$1" = "on" -o "$1" = "off" -o "$1" = "init" ]; then
    if [ "$1" = "off" ]; then
        echo 0 > /sys/class/backlight/0.pwm_bl/brightness
        echo 0 > /sys/class/gpio/gpio107/value
        echo 1 > /sys/class/gpio/gpio108/value
        sleep 1
        echo 1 > /sys/class/gpio/gpio107/value
    elif [ "$1" = "on" ]; then
        echo 250 > /sys/class/backlight/0.pwm_bl/brightness
        echo 1 > /sys/class/gpio/gpio107/value
        echo 0 > /sys/class/gpio/gpio108/value
        sleep 1
        echo 1 > /sys/class/gpio/gpio107/value
    elif [ "$1" = "init" ]; then
        echo 107 > /sys/class/gpio/export
        echo 108 > /sys/class/gpio/export
        echo out > /sys/class/gpio/gpio107/direction
        echo out > /sys/class/gpio/gpio108/direction
        echo 1 > /sys/class/gpio/gpio107/value
        echo 1 > /sys/class/gpio/gpio108/value
    fi
else
    echo "Usage: ircut.sh <off|on|init>"
fi
