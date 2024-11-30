#!/bin/bash
#
# Title: trap-demo.sh
# Description: minimal notification example (uptime)
# Development Environment: Ubuntu 22.04.5 LTS (Jammy Jellyfish)
# Author: G.S. Cole (guycole at gmail dot com)
#
PATH=/bin:/usr/bin:/etc:/usr/local/bin; export PATH
#
MANAGER="192.168.1.105"
#
snmptrap -v 2c -c public $MANAGER '' 1.3.6.1.4.1.8072.2.3.0.1 1.3.6.1.4.1.8072.2.3.2.1 i 123456
#