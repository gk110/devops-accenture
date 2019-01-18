#!/bin/sh
#Group addition
groupadd -g 54321 oinstall
groupadd -g 54322 dba
groupadd -g 54323 oper
groupadd -g 54327 asmdba
groupadd -g 54328 asmoper
groupadd -g 54329 asmadmin

#adding oracle user
useradd -u 54321 -g oinstall -G dba,oper,asmadmin oracle

#modification & check of kernel parameters & restart
if [[ -f /etc/sysctl.conf ]];then
    {
    kernel.shmmni = 4096 
    kernel.shmmax = 4398046511104
    kernel.shmall = 1073741824
    kernel.sem = 250 32000 100 128
    fs.aio-max-nr = 1048576
    fs.file-max = 6815744
    net.ipv4.ip_local_port_range = 9000 65500
    net.core.rmem_default = 262144
    net.core.rmem_max = 4194304
    net.core.wmem_default = 262144
    net.core.wmem_max = 1048586
    } >> /etc/sysctl.conf
    /sbin/sysctl -p
    return=$?
        if [[return == 0]];then
            echo " Good to proceed ahead"
        else
            echo " Restart failed check manually"
            exit $return
        fi
else
    echo " sysctl.conf file not found"
    exit 1
fi

#Add following lines to set shell limits for user oracle in file /etc/security/limits.conf

if [[ -f /etc/security/limits.conf ]];then
    {
oracle   soft   nproc    131072
oracle   hard   nproc    131072
oracle   soft   nofile   131072
oracle   hard   nofile   131072
oracle   soft   core     unlimited
oracle   hard   core     unlimited
oracle   soft   memlock  50000000
oracle   hard   memlock  50000000
    } >> /etc/security/limits.conf
    /sbin/sysctl -p
    return=$?
        if [[return == 0]];then
            echo " Good to proceed ahead"
        else
            echo " Restart failed check manually"
            exit $return
        fi
else
    echo " sysctl.conf file not found"
    exit 1
fi

#Modify .bash_profile for user oracle in his home directory

if [[ -f ${ORACLE_HOME_PROFILE} ]];then
    {
export TMP=/tmp

export ORACLE_HOSTNAME=oel6.dbaora.com
export ORACLE_UNQNAME=ORA11G
export ORACLE_BASE=/ora01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/11.2.0/db_1
export ORACLE_SID=ORA11G

PATH=/usr/sbin:$PATH:$ORACLE_HOME/bin

export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib;
export CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib;

alias cdob='cd $ORACLE_BASE'
alias cdoh='cd $ORACLE_HOME'
alias tns='cd $ORACLE_HOME/network/admin'
alias envo='env | grep ORACLE'

umask 022
    } >> ${ORACLE_HOME_PROFILE}
else
    echo "Profile for Oracle user is not present"
    exit 1
fi

#Creating required directory
mkdir -p /ora01/app/oracle/product/11.2.0/db_1
return=$?
if [[ ${return} -ne 0 ]];
    echo " Directory creation has failed"
    exit $return
else
    chown oracle:oinstall -R /ora01
    return=$?
    if [[  ${return} -ne 0 ]];then 
        echo "Issue in changing owner please check"
        exit $return
    fi
fi
