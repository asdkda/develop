#!/bin/sh

usage(){
echo "Usage: $0 [-i INTERFACE] [-s INTERVAL] [-c COUNT]"
echo
echo "-i INTERFACE"
echo "    The interface to monitor, default is eth0."
echo "-s INTERVAL"
echo "    The time to wait in seconds between measurements, default is 1 seconds."
echo "-c COUNT"
echo "    The number of times to measure, default is 20000 times."
exit 3
}

readargs(){
while [ "$#" -gt 0 ] ; do
  case "$1" in
   -i)
    if [ "$2" ] ; then
     interface="$2"
     shift ; shift
    else
     echo "Missing a value for $1."
     echo
     shift
     usage
    fi
   ;;
   -x)
    if [ "$2" ] ; then
     interface2="$2"
     shift ; shift
    else
     echo "Missing a value for $1."
     echo
     shift
     usage
    fi
   ;;
   -y)
    if [ "$2" ] ; then
     interface3="$2"
     shift ; shift
    else
     echo "Missing a value for $1."
     echo
     shift
     usage
    fi
   ;;
   -s)
    if [ "$2" ] ; then
     sleep="$2"
     shift ; shift
    else
     echo "Missing a value for $1."
     echo
     shift
     usage
    fi
   ;;
   -c)
    if [ "$2" ] ; then
     counter="$2"
     shift ; shift
    else
     echo "Missing a value for $1."
     echo
     shift
     usage
    fi
   ;;
   *)
    echo "Unknown option $1."
    echo
    shift
    usage
   ;;
  esac
done
}

checkargs(){
if [ ! "$interface" ] ; then
  interface="wlan0"
fi
if [ ! "$interface2" ] ; then
  interface2="ppp301"
fi
if [ ! "$interface3" ] ; then
  interface3="ppp302"
fi
if [ ! "$sleep" ] ; then
  sleep="1"
fi
if [ ! "$counter" ] ; then
  counter="20000"
fi
}

printrxbytes(){
/sbin/ifconfig "$1" | grep "RX bytes" | cut -d: -f2 | awk '{ print $1 }'
}

printtxbytes(){
/sbin/ifconfig "$1" | grep "TX bytes" | cut -d: -f3 | awk '{ print $1 }'
}

bytestohumanreadable(){
multiplier="0"
number="$1"
while [ "$number" -ge 1024 ] ; do
  multiplier=$(($multiplier+1))
  number=$(($number/1024))
done
case "$multiplier" in
  1)
   echo "$number Kb"
  ;;
  2)
   echo "$number Mb"
  ;;
  3)
   echo "$number Gb"
  ;;
  4)
   echo "$number Tb"
  ;;
  *)
   echo "$1 b"
  ;;
esac
}
 
printresults(){
output=0
#echo "Monitoring $interface every $sleep seconds."
while [ "$counter" -ge 0 ] ; do
  counter=$(($counter - 1))
  if [ "$rxbytes" ] ; then
   oldrxbytes="$rxbytes"
   oldtxbytes="$txbytes"
  fi
  rxbytes=$(printrxbytes $interface)
  txbytes=$(printtxbytes $interface)
  if [ "$oldrxbytes" -a "$rxbytes" -a "$oldtxbytes" -a "$txbytes" ] ; then
    output=1
  fi
  
  if [ "$interface2" ] ; then
    if [ "$rxbytes2" ] ; then
      oldrxbytes2="$rxbytes2"
      oldtxbytes2="$txbytes2"
    fi
    rxbytes2=$(printrxbytes $interface2)
    txbytes2=$(printtxbytes $interface2)
  fi
  
  if [ "$interface3" ] ; then
    if [ "$rxbytes3" ] ; then
      oldrxbytes3="$rxbytes3"
      oldtxbytes3="$txbytes3"
    fi
    rxbytes3=$(printrxbytes $interface3)
    txbytes3=$(printtxbytes $interface3)
  fi
  
  if [ "$output" -eq 1 ] ; then
     printf "%6s: " $interface
     echo "RXbytes = $(bytestohumanreadable $(($rxbytes - $oldrxbytes))) TXbytes = $(bytestohumanreadable $(($txbytes - $oldtxbytes)))"
     if [ "$interface2" ] ; then
       printf "%6s: " $interface2
       echo "RXbytes = $(bytestohumanreadable $(($rxbytes2 - $oldrxbytes2))) TXbytes = $(bytestohumanreadable $(($txbytes2 - $oldtxbytes2)))"
     fi
     if [ "$interface3" ] ; then
       printf "%6s: " $interface3
       echo "RXbytes = $(bytestohumanreadable $(($rxbytes3 - $oldrxbytes3))) TXbytes = $(bytestohumanreadable $(($txbytes3 - $oldtxbytes3)))"
     fi
     echo "====================================================="
     sleep "$sleep"
  fi  
done
}

readargs "$@"
checkargs
printresults
