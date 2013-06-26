#!/bin/bash

ifconfig p3p1 | grep "inet addr" | cut -d : -f 2 | awk '{print $1}'


