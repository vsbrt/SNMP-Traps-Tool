# SNMP-Traps-Tool
A system that listens SNMP traps, sends alerts regarding the same from the manager device to other devices and shows alerts on a web interface.

#Prerequisties:

Some of the dependencies required for executing assignment3 are 

* Perl Module Net::SNMP
* Perl Module Config::IniFiles
* Linux Lamp Stack which includes PHP, MySQL, Apache in one package.
* For installing the Lampstack, Enter the following command in the terminal:
	* sudo apt-get install lamp-server^

* perl (On the listner as well as agent machine)
* snmp (On the listner as well as agent machine)
* snmpd (On the listner as well as agent machine)


# EXECUTION OF THE SCRIPT:

1. Change the database the creditials in db.conf in et2536-save15/ Folder.
2. Change the permissions of apache directory /var/www by the entering the following command:
	"sudo chmod -R 777 /var/www to avoid problems"
3. Add the following lines to the snmpdtrapd.conf file in the /etc/snmp/snmptrapd.conf:
---
authCommunity log,execute,net public 
disableAuthorization yes
#doNotLogTraps yes
snmpTrapdAddr udp:50162
traphandle 1.3.6.1.4.1.41717.10.* /usr/bin/perl path/to/et2536-save15/assignment3/trapDaemon.pl
4. In the configuration of the snmptrapd.conf near traphandle add the path of the script, such that the scripts gets executed.
5. Change TRAPDRUN=yes in /etc/default/snmpd.
6. sudo service snmpd restart.
7. Then Open the Terminal and give the command as:

sudo snmptrap -v 1 -c public 192.168.32.141:50162 .1.3.6.1.4.1.41717.10 10.2.3.4 6 247 '' .1.3.6.1.4.1.41717.10.1 s "" .1.3.6.1.4.1.41717.10.2 i 1

---
8. Open localhost/et2536-save15/assignment3/index.php, where you can see the status of the device. 
9. If there is a Fail trap recieved, then the on the webpage, there is a link as "SNMP TRAP SENDER".
10. Click on the specified  link on the webpage to send the Traps to the manager specified to the user. 
11. After the link is clicked, specify the IP, COMMUNITY and PORT for which the trap should be sent.
12. Click submit.


NOTE: IF THERE is NO PREVIOUS STATUS AND TIME then those corresponding OID's are not present in the TRAP when the trap is being sent to the trap listener. 


 


