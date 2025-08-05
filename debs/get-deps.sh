#!/bin/bash
input="debs-to-download.txt"
######################################
# $IFS removed to allow the trimming #
#####################################
while read -r line
do
  echo "$line"
  for i in $(apt-cache depends "$line" | grep -E 'Depends' | cut -d ':' -f 2,3 | sed -e s/'<'/''/ -e s/'>'/''/); do echo $i; done
  echo ""
  echo ""
done < "$input"
