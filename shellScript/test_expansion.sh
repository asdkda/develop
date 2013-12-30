#!/bin/bash

# test for Shell Parameter Expansion
# Ref: http://www.gnu.org/software/bash/manual/bashref.html#Shell-Parameter-Expansion

word="word.git"
#parameter="parameter"
printf "%25s: %s\n" "\${parameter}" ${parameter}
printf "%25s: %s\n" "\${parameter:-111}" ${parameter:-111}
printf "%25s: %s\n" "\${parameter:=test_value}" ${parameter:=test_value}
printf "%25s: %s\n" "\${parameter:-111}" ${parameter:-""}
printf "%25s: %s\n" "\${parameter:+111}" ${parameter:+111}
printf "%25s: %s\n" "\${parameter:2}" ${parameter:2}
printf "%25s: %s\n" "\${parameter:2:5}" ${parameter:2:5}
printf "%25s: %s\n" "\${parameter%lue}" ${parameter%lue}
printf "%25s: %s\n" "\${parameter/test/kkk}" ${parameter/test/kkk}
printf "aaa %25s: %s\n" "\${word/.git/}" ${word/.git/}

#${parameter//substring/replacement}
#${parameter##remove_matching_prefix}
#${parameter%%remove_matching_suffix}

echo "for i in /etc/rc4.d/K*"
echo -n "  \${i#/etc/rc4.d/K??}: "
for i in /etc/rc4.d/K* ; do
	subsys=${i#/etc/rc4.d/K??}
	printf "%s " $subsys
done
echo ""



