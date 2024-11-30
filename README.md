# snmp4sbc
SNMP for Single Board Computers

## Introduction
This project is to share my experience using [SNMP](https://en.wikipedia.org/wiki/Simple_Network_Management_Protocol) to manage a fleet of single board computers such as [BeagleBone Black](https://beagleboard.org/black) (etc) or the [Raspberry Pi](https://en.wikipedia.org/wiki/Raspberry_Pi) (etc).

SNMP is mature and well documented, there are several decent books and a great implementation open source implementation provided by the [Net-SNMP](https://en.wikipedia.org/wiki/Net-SNMP) agent and utilities.  I share some advice about configuring and using Net-SNMP and end with extending the agent to monitor GPIO.

I am writing this in November, 2024 and the current source version of Net-SNMP is 5.9.4

## The Players
WRT54GL Wireless Access Point (all client IP address via DHCP)

| host  | IP address    | interface | role    | type                           | operating system                       |
|-------|---------------|-----------|---------|--------------------------------|---------------------------------------|
| bb11  | 192.168.1.109 | wlan0     | agent   | beaglebone black wireless      | AM335x 11.7 2023-09-02 4GB microSD IoT |
| boris | 192.168.1.105 | en1       | manager | Mac Mini late 2014             | Monterey 12.7.6                        |
| rpi4e | 192.168.1.113 | wlan0     | agent   | raspberry pi 4                 | 2024-03-15 64bit rPi OS                |
| waifu | 192.168.1.126 | wlp0s20f3 | manager | Lenovo Notebook P/N 21FVX001US | Ubuntu 22.04.5 LTS (Jammy Jellyfish)   |

## The Plan (Raspberry Pi)
1. Simple Start (Notification/Trap)
    1. Goal: use the snmptrap(1) utility to generate notifications from a rPi to another host running tcpdump(8), which demonstrates routing between machines on UDP 162.
    1. On the agent (rPi) Install the snmp utilities by running ***apt-get install snmp***, which (in November, 2024) installs the Net-SNMP v5.9.3 utilities.
    1. On the manager, invoke tcpdump(8) (might need to be root) as ***tcpdump -v port 162***
    1. On the agent (rPi), tweak the trap script to have the correct IP address of your manager and then invoke it.
    1. On the manager, tcpdump(8) should look similar to this:
```22:46:40.250146 IP (tos 0x0, ttl 64, id 2503, offset 0, flags [DF], proto UDP (17), length 122) 192.168.1.113.58095 > waifu.snmp-trap:  { SNMPv2c { V2Trap(79) R=212351885  system.sysUpTime.0=17714770 S:1.1.4.1.0=E:8072.2.3.0.1 E:8072.2.3.2.1=123456 } }```
    1. snmptrapd(8) could also be used by your manager to log trap messages.

## The Plan (BeagleBone Black)
1. Net-SNMP installation notes
1. Register BeagleBone boot via notification/trap and share IP address
1. Configure agent to share useful system identification
1. Extend agent to share GPIO status
