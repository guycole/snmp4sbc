# snmp4sbc
SNMP for Single Board Computers (i.e. "BeagleBone Black" or "Raspberry Pi")

## Introduction
This project is to share my experience using [SNMP](https://en.wikipedia.org/wiki/Simple_Network_Management_Protocol) to manage a fleet of single board computers such as [BeagleBone Black](https://beagleboard.org/black) (etc) or the [Raspberry Pi](https://en.wikipedia.org/wiki/Raspberry_Pi) (etc).

SNMP is mature and well documented, there are several decent books and a great open source implementation provided by the [Net-SNMP](https://en.wikipedia.org/wiki/Net-SNMP) agent and utilities.  I share some advice about configuring and using Net-SNMP and end with extending the agent to monitor GPIO.

I am writing this in November, 2024 and the current source version of Net-SNMP is 5.9.4

## The Players
WRT54GL Wireless Access Point (all client IP address via DHCP)

| host  | IP address    | interface | role    | type                           | operating system                       |
|-------|---------------|-----------|---------|--------------------------------|----------------------------------------|
| bb11  | 192.168.1.109 | wlan0     | agent   | beaglebone black wireless      | Debian 10 Buster                       |
| rpi4e | 192.168.1.113 | wlan0     | agent   | raspberry pi 4                 | 2024-03-15 64bit rPi OS                |
| waifu | 192.168.1.126 | wlp0s20f3 | manager | Lenovo Notebook P/N 21FVX001US | Ubuntu 22.04.5 LTS (Jammy Jellyfish)   |

## The Plan (Raspberry Pi)
1. Simple Start (Notification/Trap)
    1. Goal: use the snmptrap(1) utility to generate notifications from a rPi to a manager host running tcpdump(8), which demonstrates routing between machines on UDP 162.
    1. On the agent (rPi) install the SNMP utilities by running ***apt-get install snmp***, which (in November, 2024) installs the Net-SNMP v5.9.3 utilities.
    1. On the manager, invoke tcpdump(8) (might need to be root) as ***tcpdump -v port 162***
    1. On the agent (rPi), tweak [trap-demo.sh](https://github.com/guycole/snmp4sbc/blob/main/bin/trap-demo.sh) to have the correct IP address of your manager and then invoke it.
    1. On the manager, tcpdump(8) should look similar to this:
        ```
        22:46:40.250146 IP (tos 0x0, ttl 64, id 2503, offset 0, flags [DF], proto UDP (17), length 122) 192.168.1.113.58095 > waifu.snmp-trap:  { SNMPv2c { V2Trap(79) R=212351885  system.sysUpTime.0=17714770 S:1.1.4.1.0=E:8072.2.3.0.1 E:8072.2.3.2.1=123456 } }
        ```
    1. snmptrapd(8) could also be used by the manager to log trap messages.
1. Simple "Read Only" Agent
    1. Goal: introduce a minimal SNMP agent configuration (rPi), and interrogate it from a manager host.
    1. On the agent (rPi) install the SNMP agent by running ***apt-get install snmpd***, which (in November, 2024) installs the Net-SNMP v5.9.3 SNMP agent.
        1. Verify working installation by invoking ***systemctl status snmpd***, the response should be similar to this:
        ```
        ● snmpd.service - Simple Network Management Protocol (SNMP) Daemon.
             Loaded: loaded (/lib/systemd/system/snmpd.service; enabled; preset: enabled)
             Active: active (running) since Sat 2024-11-30 07:59:56 UTC; 7h ago
           Main PID: 1232 (snmpd)
              Tasks: 1 (limit: 8731)
                CPU: 29.445s
             CGroup: /system.slice/snmpd.service
                     └─1232 /usr/sbin/snmpd -LOw -u Debian-snmp -g Debian-snmp -I -smux mteTrigger mteTrigger> 
        ```
    1. Surprisingly (for a systemd(1) service) journalctl(1) does not contain the agent logs.  snmpd(8) logs to /var/log/snmpd.log
    1. Now update the agent (rPi) configuration, use [simple.conf](https://github.com/guycole/snmp4sbc/blob/main/config/simple.conf) by copying it to overwrite /etc/snmp/snmpd.conf
    1. Restart the agent (rPi) by invoking ***systemctl restart snmpd***
    1. Request the system MIB contents by invoking ***snmpwalk -v 2c -c public 192.168.1.113 1.3.6.1.2.1.1*** (replace the address 192.168.1.113 with the IP address of your rPi).  The result should look like:
        ```
        SNMPv2-MIB::sysDescr.0 = STRING: Linux rpi4e 6.6.31+rpt-rpi-v8 #1 SMP PREEMPT Debian 1:6.6.31-1+rpt1 (2024-05-29) aarch64
        SNMPv2-MIB::sysObjectID.0 = OID: NET-SNMP-MIB::netSnmpAgentOIDs.10
        DISMAN-EVENT-MIB::sysUpTimeInstance = Timeticks: (19905) 0:03:19.05
        SNMPv2-MIB::sysContact.0 = STRING: "hax4bux”
        SNMPv2-MIB::sysName.0 = STRING: rpi4e
        SNMPv2-MIB::sysLocation.0 = STRING: "shasta"
        (etc, etc..)
        ```
1. Configure SNMP agent to generate start/shutdown traps
    1. Goal: configure the SNMP agent (rPi) to generate SNMPv2-MIB::coldStart and UCD-SNMP-MIB::ucdShutDown 
    1. On the manager, invoke tcpdump(8) as ***tcpdump -v port 162***
    1. On the agent (rPi) update the configuration by copying [simple_with_trap.conf](https://github.com/guycole/snmp4sbc/blob/main/config/simple_with_trap.conf) to replace /etc/snmp/snmpd.conf
        1. Update the IP address to match your manager
    1. Restart the agent (rPi) by invoking ***systemctl restart snmpd***
    1. On the agent (rPi) install the SNMP agent by running ***apt-get install snmpd***, which (in November, 2024) installs the Net-SNMP v5.9.3 SNMP agent.
    1. Note that when you restart the agent, a trap is now generated to announce "coldStart"  From tcpdump(8) it looks like:
        ```
        09:19:32.472153 IP (tos 0x0, ttl 64, id 54386, offset 0, flags [DF], proto UDP (17), length 123) 192.168.1.113.52157 > waifu.snmp-trap:  { SNMPv2c { V2Trap(80) R=133045648  system.sysUpTime.0=21 S:1.1.4.1.0=S:1.1.5.1 S:1.1.4.3.0=E:8072.3.2.10 } } 
   
        ```
    1. If you restart the agent (rPi) again, there will be two traps: One for "shut down" and then "cold start".
1. Use MIB names instead of raw OID
    1. Goal: refer to objects by name instead of using raw OID.  A component of SNMP is the [Management Information Base (MIB)](https://en.wikipedia.org/wiki/Management_information_base)
    1. The agent and utilities share a common configuration file "/etc/snmp/snmp.conf"
    1. On your manager, locate the "snmp.conf" file and update the "mibdirs" variable
        1. On my manager, "/usr/share/snmp/mibs" contains enough freely available MIB to work.
    1. Verify you can now reference items by name instead of OID
        1. ***snmpwalk -v 2c -c public 192.168.1.113 system***
1. Monitor Raspberry Pi using the "Host Resources MIB"
    1. Goal: access host resources such as date/time, file systems, CPU, memory, etc.
    1. The [HOST-RESOURCES-MIB](http://www.net-snmp.org/docs/mibs/host.html) defines how to access this information.
    1. Example: ***snmpwalk -v 2c -c public 192.168.1.113 host***
        ```
        HOST-RESOURCES-MIB::hrSystemUptime.0 = Timeticks: (1117912) 3:06:19.12
        HOST-RESOURCES-MIB::hrSystemDate.0 = STRING: 2024-11-30,20:25:29.0,+0:0
        HOST-RESOURCES-MIB::hrSystemInitialLoadDevice.0 = INTEGER: 393216
        HOST-RESOURCES-MIB::hrSystemInitialLoadParameters.0 = STRING: "coherent_pool=1M 8250.nr_uarts=0 snd_bcm2835.enable_headphones=0 snd_bcm2835.enable_headphones=1 snd_bcm2835.enable_hdmi=1 snd_b"
        HOST-RESOURCES-MIB::hrSystemNumUsers.0 = Gauge32: 5
        HOST-RESOURCES-MIB::hrSystemProcesses.0 = Gauge32: 206
        HOST-RESOURCES-MIB::hrSystemMaxProcesses.0 = INTEGER: 0
        HOST-RESOURCES-MIB::hrMemorySize.0 = INTEGER: 7997476 KBytes
        HOST-RESOURCES-MIB::hrStorageIndex.1 = INTEGER: 1
        (etc, etc...)
        ```

## The Plan (BeagleBone Black)
1. Net-SNMP installation notes
1. Register BeagleBone boot via notification/trap and share IP address
1. Configure agent to share useful system identification
1. Extend agent to share GPIO status
