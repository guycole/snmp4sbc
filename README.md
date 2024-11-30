# snmp4sbc
SNMP for Single Board Computers

## Introduction
This project is to share my experience using [SNMP](https://en.wikipedia.org/wiki/Simple_Network_Management_Protocol) to manage a fleet of single board computers such as [BeagleBone Black](https://beagleboard.org/black) (etc) or the [Raspberry Pi](https://en.wikipedia.org/wiki/Raspberry_Pi) (etc).

SNMP is mature and well documented, there are several decent books and a great implementation open source implementation provided by the [Net-SNMP](https://en.wikipedia.org/wiki/Net-SNMP) agent and utilities.  I share some advice about configuring and using Net-SNMP and end with extending the agent to monitor GPIO.

I am writing this in November, 2024 and the current source version of Net-SNMP is 5.9.4

## The Players
1. WRT54GL Wireless Access Point (all client IP address via DHCP)
1. bb11 192.168.1.109 wlan0 (agent, beaglebone black wireless on "AM335x 11.7 2023-09-02 4GB microSD IoT")
1. boris 192.168.1.105 en1 (manager, Mac Mini late 2014 on Monterey 12.7.6)
1. rpi4e 192.168.1.113 wlan0 (agent, raspberry pi 4 on 2024-03-15 64bit rPi OS)
1. waifu 192.168.1.126 wlp0s20f3 (manager, Lenovo Notebook P/N 21FVX001US on Ubuntu 24)

## The Plan (BeagleBone Black)
1. Net-SNMP installation notes
1. Register BeagleBone boot via notification/trap and share IP address
1. Configure agent to share useful system identification
1. Extend agent to share GPIO status
