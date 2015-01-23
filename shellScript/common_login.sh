#!/bin/bash

source ~/config/config.sh
path="$DEV_PATH/shellScript"

List=("marconi   10.2.10.100" "$path/login.sh -I 100"
      "wms       10.2.10.102" "$path/login.sh -I 102"
      "lmc       10.2.10.71"  "$path/login.sh -I 71"
      "root      10.2.10.18"  "$path/login.sh -I 18 -u root -p $LILEE_PW6"
      "root      10.2.10.19"  "$path/login.sh -I 19 -u root -p $CUSTOM_PW2"
      "root      10.2.10.20"  "$path/login.sh -I 20 -u root -p $LILEE_PW"
#      "root      10.2.10.51"  "$path/login.sh -s -i 10.2.10.51 -u root -p $LILEE_PW3"
      "builder   10.1.10.20"  "$path/login.sh -i 10.1.10.20 -u root -p $LILEE_PW2"
      "builder64 10.1.10.21"  "$path/login.sh -i 10.1.10.21 -u root -p $LILEE_PW2"
      "builder32 10.1.10.40"  "$path/login.sh -i 10.1.10.40 -u root -p $LILEE_PW5"
      "root      gozilla"     "$path/login.sh -i gozilla -u root"
      "root      gamera"      "$path/login.sh -i gamera -u root"
      "ethan"                 "$path/login.sh -i ethan-yang.no-ip.org -u $CUSTOM_PW -p $LILEE_PW"
      "ethan console"         "$path/login.sh -s -i ethan-yang.no-ip.org --port 3001")

display() {
	echo "console: $CONSOLE_IP $CONSOLE_PORT"
	echo -e "     ===== LIST ====="
	for ((i=0, j=1; i<${#List[@]}; i++, i++, j++)); do
		printf "%2d. %s\n      %s\n" $j "${List[$i]}" "${List[(($i+1))]}"
	done
	echo -e ""
}

while getopts "s" OPTION
do
	case ${OPTION} in
		s)
			display
			exit 0
			;;
	esac
done


echo -e "     ===== LIST ====="
for ((i=0, j=1; i<${#List[@]}; i++, i++, j++)); do
	printf "%2d. %s\n" $j "${List[$i]}"
done
echo -e ""

read -p "Input a choice : " ch

case "$ch" in
  [[:lower:]] )  echo "You MUST input a number." && exit 0 ;;
  [[:upper:]] )  echo "You MUST input a number." && exit 0 ;;
  [[:digit:]]*)  ;;
  *           )  echo "You MUST input a number." && exit 0 ;;
esac      #  Allows ranges of characters in [square brackets],


if [ $ch -ge $j ]; then
	echo "It should be in range 1-$(($j-1))" && exit 0
fi

eval ${List[$(($ch*2-1))]}



