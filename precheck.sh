#!/bin/bash

BL='\e[0;36m'
RD='\e[0;31m'
YW='\e[1;33m'
NC='\e[0m'
GN='\e[0;32m'
DEF_NIC=`route | grep '^default' | grep -o '[^ ]*$'`
SERVER_IP=`ip a s | grep $DEF_NIC | grep inet | sed -e 's/^[ \t]*//' | awk -F " " '{print $2}' | awk -F "/" '{print $1}' || echo -e "${RD}Something went wrong & couldnt get Server IP Details${NC}"`
vserver=$(lscpu | grep Hypervisor | wc -l)

PRECHK_FILE=precheck-`date '+%d%m%Y%H%M%S'`
touch /var/log/$PRECHK_FILE

function validate(){
if [ $2 == 0 ]; then
        echo -e "\n${GN}$1 Completed${NC}\n"
else
        echo -e "\n${RD}$1 Failed${NC}\n"
        exit
fi
}

clear
{
echo -e "\n################################################################ PRECHECK EXECUTION ##################################################################\n"
echo "Created and writing output to '/var/log/$PRECHK_FILE' log file."

echo -e "\n################################################################ TAR BACKUP ##################################################################\n"

TAR_PATH="/var/log"
TIME_STAMP=`date '+%d%m%Y%H%M%S'`

function tar_backup(){
TASK_NAME="Tar backup of $1"
echo "Taking tar backup of $1..."
tar -czvf $TAR_PATH/$2-$TIME_STAMP.tar.gz $1 &> /dev/null
retval="`echo $?`"
validate "$TASK_NAME" "$retval"

if [ -f $TAR_PATH/$2-$TIME_STAMP.tar.gz ]
then
        echo -e "${GN}$TAR_PATH/$2-$TIME_STAMP.tar.gz file created successfully.${NC}\n"
else
        echo -e "${RD}Tar file $TAR_PATH/$2-$TIME_STAMP.tar.gz not found. Check if the tar files are present manually.${NC}\n"
fi
}

tar_backup /boot boot
tar_backup /etc etc
tar_backup /etc/pam.d pam

echo -e "\n############################################################ SYSTEM INFORMATION ##################################################################\n"
echo -e "Hostname:\t\t${GN}`hostname || echo -e "${RD}Something went wrong & couldnt get Hostname Details${NC}"`${NC}"
echo -e "Server IP:\t\t${GN}$SERVER_IP${NC}"
echo -e "Subnet Mask:\t\t${GN}`ifconfig | grep $SERVER_IP | awk '{print $4}' || echo -e "${RD}Something went wrong & couldnt get Subnet Mask Details${NC}"`${NC}"
echo -e "Gateway:\t\t${GN}`ip route show | grep default | awk '{print $3}'|| echo -e "${RD}Something went wrong & couldnt get Gateway Details${NC}"`${NC}"
echo -e "uptime:\t\t\t${GN}`uptime | awk -F"," '{print $1}' | awk '{for(i=3;i<=NF;++i)printf $i""FS ; print ""}'|| echo -e "${RD}Something went wrong & couldnt get Uptime Details${NC}"`${NC}"
echo -e "Manufacturer:\t\t${GN}`cat /sys/class/dmi/id/chassis_vendor|| echo -e "${RD}Something went wrong & couldnt get Manufacturer Details${NC}"`${NC}"
echo -e "Product Name:\t\t${GN}`cat /sys/class/dmi/id/product_name|| echo -e "${RD}Something went wrong & couldnt get Product Name Details${NC}"`${NC}"
echo -e "Machine Type:\t\t${GN}`vserver=$(lscpu | grep Hypervisor | wc -l); if [ $vserver -gt 0 ]; then echo "VM"; else echo "Physical"; fi`${NC}"
echo -e "Operating System:\t${GN}`hostnamectl | grep "Operating System" | cut -d ' ' -f5- || echo -e "${RD}Something went wrong & couldnt get OS Details${NC}"`${NC}"
echo -e "Kernel:\t\t\t${GN}`uname -r|| echo -e "${RD}Something went wrong & couldnt get Kernel Details${NC}"`${NC}"
echo -e "Architecture:\t\t${GN}`arch|| echo -e "${RD}Something went wrong & couldnt get Architecture Details${NC}"`${NC}"
echo -e "Processor Name:\t\t${GN}`awk -F':' '/^model name/ {print $2}' /proc/cpuinfo | uniq | sed -e 's/^[ \t]*//'|| echo -e "${RD}Something went wrong & couldnt get Processor Name${NC}"`${NC}"
java -version &> /dev/null
if [ "`echo $?`" == 0 ]
then
        echo -e "Installed Java Version:\t${GN}`java -version 2>&1 | head -n 1|| echo -e "${RD}Something went wrong & couldnt get Java Details${NC}"`${NC}"
else
        echo  -e "Installed Java Version:\t${RD}Java is not installed${NC}"
fi
echo -e "Active User:\n${GN}`w | cut -d ' ' -f1 | grep -v USER | xargs -n1|| echo -e "${RD}Something went wrong & couldnt get Active User Details${NC}"`${NC}"

echo -e "\n####################################################### CPU, MEMORY & DISK DETAILS ##################################################################\n"
echo -e "Total No. of vCPU's:\t${GN}`lscpu | grep "CPU(s)" | head -n1 | awk -F":" '{print $2}' | sed -e 's/^\s*//' -e '/^$/d' || echo -e "${RD}Something went wrong & couldnt get vCPU Details${NC}"`${NC}"
RAM_SIZE=`free -g | grep Mem | awk -F":" '{print $2}' | awk '{print $1}'`
if [ $RAM_SIZE == 0 ]
then
        RAM_SIZE=`free -m | grep Mem | awk -F":" '{print $2}' | awk '{print $1}'`
        echo -e "Total RAM Size:\t\t${GN}$RAM_SIZE MB${NC}"
else
        echo -e "Total RAM Size:\t\t${GN}$RAM_SIZE GB${NC}"
fi
SWAP_SIZE=`free -g  | grep -i "Swap" | awk -F":" '{print $2}' | awk '{print $1}'`
if [ $SWAP_SIZE == 0 ]
then
        SWAP_SIZE=`free -m | grep "Swap" | awk -F":" '{print $2}' | awk '{print $1}'`
        echo -e "Total Swap Size:\t${GN}$SWAP_SIZE MB${NC}"
else
        echo -e "Total Swap Size:\t${GN}$SWAP_SIZE GB${NC}"
fi


echo -e "\n################################################# DISK DETAILS ATTACHED TO THE SERVER ############################################################\n"
TASK_NAME="Capturing Disk Details"
fdisk -l | egrep 'sd|xv|nv|hd' | grep "Disk"
retval=$?
validate "$TASK_NAME" "$retval"

echo -e "######################################################### BLOCK & MOUNT DETAILS #################################################################\n"
TASK_NAME="Capturing Block & Mount Details"
lsblk
retval=$?
validate "$TASK_NAME" "$retval"

echo -e "############################################################## UUID DETAILS #####################################################################\n"
TASK_NAME="Capturing UUID Details"
blkid
retval=$?
validate "$TASK_NAME" "$retval"

echo -e "############################################################### LVM DETAILS ####################################################################\n"

if [ ! -f /usr/sbin/lvs ] || [ $(lvs | wc -l) == 0 ]
then
        echo -e "${GN}No LVMs partitions available in the server.${NC}"
else
        echo "-----------------------------------------"
        TASK_NAME="Capturing Physical Volume Details"
        pvs
        retval=$?
        validate "$TASK_NAME" "$retval"
        echo "-----------------------------------------"
        TASK_NAME="Capturing Volume Group Details"
        vgs
        retval=$?
        validate "$TASK_NAME" "$retval"
        echo "-----------------------------------------"
        TASK_NAME="Capturing Logical Volume Details"
        lvs
        retval=$?
        validate "$TASK_NAME" "$retval"
        echo "-----------------------------------------"
fi

echo -e "\n###################################################### CPU/MEMORY USAGE DETAILS ################################################################\n"
echo -e "Total Memory Usage:\t${GN}`free | awk '/Mem/{printf("%.2f%"), $3/$2*100}' || echo -e "${RD}Something went wrong & couldnt get Memory Usage Details${NC}"`${NC}"
if [ "$SWAP_SIZE" == 0 ]
then
        echo -e "Total Swap Usage:\t${GN}Swap space not allocated${NC}"
else
        echo -e "Total Swap Usage:\t${GN}`free | awk '/Swap/{printf("%.2f%"), $3/$2*100}' || echo -e "${RD}Something went wrong & couldnt get SWAP Usage Details${NC}"`${NC}"
fi
echo -e "Total CPU Usage:\t${GN}`cat /proc/stat | awk '/cpu/{printf("%.2f%\n"), ($2+$4)*100/($2+$4+$5)}' |  awk '{print $0}' | head -1 || echo -e "${RD}Something went wrong & couldnt get CPU Usage Details${NC}"`${NC}"

echo -e "\n########################################################## MEMORY USAGE DETAILED INFORMATION #######################################################\n"
TASK_NAME="Capturing Memory Usage Details"
free -mt
retval=$?
validate "$TASK_NAME" "$retval"


echo -e "\n################################################################ DISK USAGE ####################################################################\n"
TASK_NAME="Capturing Disk Usage Details"
df -PhT
retval=$?
validate "$TASK_NAME" "$retval"

echo -e "\n########################################################### ROUTE & IP DETAILS ####################################################################\n"

TASK_NAME="Capturing Route Details"
route -n
retval=$?
validate "$TASK_NAME" "$retval"
echo -e "----------------------------------------------------------------------------------------------------\n"
TASK_NAME="Capturing IP Address Details"
ifconfig
retval=$?
validate "$TASK_NAME" "$retval"

echo -e "\n############################################################### WWN DETAILS ####################################################################\n"
TASK_NAME="Capturing WWN Details"
if [ $vserver -gt 0 ]
then
        echo "$(hostname) is a VM"
else
        cat /sys/class/fc_host/host?/port_name
fi
retval=$?
validate "$TASK_NAME" "$retval"

echo -e "\n############################################################### SELINUX DETAILS ####################################################################\n"

if [ -f /usr/sbin/sestatus ] && [ -f /etc/selinux/config ]
then
    TASK_NAME="Capturing SELinux Status"
    sestatus
    retval=$?
    validate "$TASK_NAME" "$retval"

    echo "----------------------------------------------------------------"
    echo -e "\nSELINUX Config File:${GN}"
    cat /etc/selinux/config | grep -w SELINUX | egrep -v '^#|^$'
    echo -e "${NC}"
else
    echo -e "${GN}SELinux Not Available/Configured in this server.${NC}"
fi

echo -e "\n############################################################### HOSTS FILE ####################################################################\n"
TASK_NAME="Capturing /etc/hosts file contents"
cat /etc/hosts | egrep -v '^#|^$'
retval=$?
validate "$TASK_NAME" "$retval"

echo -e "\n############################################################### DNS/RESOLV FILE ####################################################################\n"
TASK_NAME="Capturing /etc/resolv.conf file contents"
cat /etc/resolv.conf | egrep -v '^#|^$'
retval=$?
validate "$TASK_NAME" "$retval"


echo -e "\n############################################################### PASSWD FILE ####################################################################\n"
TASK_NAME="Capturing /etc/passwd file contents"
cat /etc/passwd
retval=$?
validate "$TASK_NAME" "$retval"

echo -e "\n############################################################### SHADOW DETAILS ####################################################################\n"
TASK_NAME="Capturing /etc/shadow file contents"
cat /etc/shadow
retval=$?
validate "$TASK_NAME" "$retval"

echo -e "\n############################################################### GROUP DETAILS ####################################################################\n"
TASK_NAME="Capturing /etc/group file contents"
cat /etc/group
retval=$?
validate "$TASK_NAME" "$retval"

echo -e "\n############################################################### GSHADOW DETAILS ####################################################################\n"
TASK_NAME="Capturing /etc/gshadow file contents"
if [ -f /etc/gshadow ]
then
    cat /etc/gshadow
    retval=$?
    validate "$TASK_NAME" "$retval"
else
    echo -e "${GN}/etc/gshadow file doesnt exists in this server${NC}"
fi

echo -e "\n############################################################### SUDOERS DETAILS ####################################################################\n"
TASK_NAME="Capturing /etc/sudoers file contents"
cat /etc/sudoers | egrep -v '^#|^$'
retval=$?
validate "$TASK_NAME" "$retval"

echo -e "\n############################################################### FSTAB DETAILS ####################################################################\n"
TASK_NAME="Capturing /etc/fstab file contents"
cat /etc/fstab
retval=$?
validate "$TASK_NAME" "$retval"

echo -e "\n############################################################### GRUB DETAILS ####################################################################\n"
TASK_NAME="Capturing GRUB file contents"
if [ -f /boot/grub2/grub.cfg ]
then
        cat /boot/grub2/grub.cfg | egrep -v '^#|^$'
        retval=$?
elif [ -f /boot/grub/grub.conf ]
then
        cat /boot/grub/grub.conf | egrep -v '^#|^$'
        retval=$?
elif [ -f /boot/grub/menu.lst ]
then
        cat /boot/grub/menu.lst | egrep -v '^#|^$'
else
        echo "Boot GRUB file is not available"
fi
validate "$TASK_NAME" "$retval"

echo -e "\n############################################################### ETC GRUB DETAILS ####################################################################\n"
TASK_NAME="Capturing /etc/default/grub file contents"
if [ -f /etc/default/grub ]
then
        cat /etc/default/grub | egrep -v '^#|^$'
        retval=$?
        validate "$TASK_NAME" "$retval"
else
        echo -e "${GN}/etc/default/grub file doesnt exists${NC}"
fi

echo -e "\n############################################################### RC.LOCAL DETAILS ####################################################################\n"
TASK_NAME="Capturing /etc/rc.lcoal file contents"
if [ -f /etc/rc.local ]
then
    cat /etc/rc.local | egrep -v '^#|^$'
    retval=$?
    validate "$TASK_NAME" "$retval"
else
    echo -e "${GN}/etc/rc.local file doesnt exists in this server${NC}"
fi

echo -e "\n############################################################# RUNNING PROCESSES ####################################################################\n"
TASK_NAME="Capturing currently running process details"
ps -ef
retval=$?
validate "$TASK_NAME" "$retval"


echo -e "\n######################################################### LISTENING/CONFIGURED PORTS ####################################################################\n"
TASK_NAME="Capturing currently listening/configured port details"
netstat -antlp
retval=$?
validate "$TASK_NAME" "$retval"

echo -e "\n############################################################## DB's RUNNING ####################################################################\n"
TASK_NAME="Capturing currently running DB details"
ps -ef | egrep 'pmon|dbsysc|mysql|postgres'
retval=$?
validate "$TASK_NAME" "$retval"

#echo -e "\n######################################################### ORACLE DB INSTANCES  ####################################################################\n"
#TASK_NAME="Capturing Oracle DB Instances"
#id oracle
#ORC_STATUS=`echo $?`
#if [ "$ORC_STATUS" == 0 ]
#then
#        ps -ef|grep pmon
#        echo "---------------------------------------------------------------------------"
#        cat /etc/oratab | egrep -v '^#|^$'
#        retval=$?
#        validate "$TASK_NAME" "$retval"
#else
#        echo -e "${GN}oracle user does not exist on $(hostname)${NC}"
#fi

echo -e "\n###################################################### SERVICES RUNNING #####################################################################\n"
TASK_NAME="Capturing currently running services details"
service --status-all
retval=$?
validate "$TASK_NAME" "$retval"

echo -e "\n############################################### SERVICES ENABLED DURING SERVER STARTUP  #############################################################\n"
TASK_NAME="Capturing services details enabled during server startup"
if [ ! -f /usr/bin/systemctl ]
then
        chkconfig --list
        retval=$?
else
        systemctl list-unit-files | grep enabled
        retval=$?
fi
validate "$TASK_NAME" "$retval"

echo -e "\n####################################################### AVAILABLE PACKAGE UPDATES ####################################################################\n"
TASK_NAME="Capturing available package updates details"
if (( $(cat /etc/*release | egrep 'Oracle|Red Hat|CentOS|Fedora|Amazon' | wc -l) > 0 ))
then
    #yum updateinfo list available
    yum list updates
    retval=$?
    #yum updateinfo list available | awk '{print $3}'
elif (( $(cat /etc/*release | grep "SUSE Linux"| wc -l) > 0 ))
then
    zypper list-updates
    #zypper list-patches | awk -F"|" '{print $7}' | egrep -v '^#|^$'
    retval=$?
elif (( $(cat /etc/*release | grep 'Ubuntu' | wc -l) > 0 ))
then
    #apt-get update && apt-get -s dist-upgrade | awk '/^Inst/ { print $2 }'
    retval=$?
else
   retval=1
fi
retval=$?
validate "$TASK_NAME" "$retval"

echo -e "\n########################################################### PRECHECK EXECUTION COMPLETED #############################################################\n"
} | tee /var/log/$PRECHK_FILE
