#!/bin/bash

source ~/config/config.sh
path="$DEV_PATH/shellScript"

echo -e "===== LIST ====="
echo -e "1. marconi   10.2.10.85"
echo -e "2. marconi   10.2.10.87"
echo -e "3. lmc       10.2.10.71"
echo -e "4. root      10.2.10.20"
echo -e "5. root      10.2.10.51"
echo -e "6. builder   10.1.10.20"
echo -e "7. builder64 10.1.10.21"
echo -e "8. ethan"
echo -e ""

read -p "Input a choice : " ch

case "$ch" in
  [[:lower:]] )  echo "You MUST input a number." && exit 0 ;;
  [[:upper:]] )  echo "You MUST input a number." && exit 0 ;;
  1           )  eval "$path/login.sh -s -i 10.2.10.85" ;;
  2           )  eval "$path/login.sh -s -i 10.2.10.87" ;;
  3           )  eval "$path/login.sh -s --lmc -i 10.2.10.71" ;;
  4           )  eval "$path/login.sh -s -i 10.2.10.20 -u root -p $LILEE_PW" ;;
  5           )  eval "$path/login.sh -s -i 10.2.10.51 -u root -p $LILEE_PW3" ;;
  6           )  eval "$path/login.sh -s -i 10.1.10.20 -u builder -p $LILEE_PW4" ;;
  7           )  eval "$path/login.sh -s -i 10.1.10.21 -u root -p $LILEE_PW2" ;;
  8           )  eval "$path/login.sh -s -i ethan-yang.no-ip.org -u $CUSTOM_PW" ;;
  [0-9]       )  echo "Range 1-8" && exit 0 ;;
  *           )  echo "You MUST input a number." && exit 0 ;;
esac      #  Allows ranges of characters in [square brackets],


