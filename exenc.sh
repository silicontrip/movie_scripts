#!/bin/sh

# a really old version of my eyetv tool

endwrite() {

fn=$1
sleep 2
nfs=`ls -la $fn | awk '{print $5}'`
#echo $nfs
while [ "$nfs" != "$ofs" ]
do
ofs=$nfs
sleep 2
nfs=`ls -la $fn | awk '{print $5}'`
#echo $nfs
/bin/echo -n "."
done
echo ""

}

path=`pwd`
macpath=`echo $path | sed 's,/,:,g;s/^:Volumes://'`

echo $macpath

for id in $@
do
tcmd="tell application \"eyetv\" to get title of recording id $id" 
ecmd="tell application \"eyetv\" to get episode of recording id $id" 
dcmd="tell application \"eyetv\" to get start time of recording id $id"

t=`osascript -e "$tcmd" | sed 's/ //g'`
e=`osascript -e "$ecmd" | sed 's/[ \&\?:]//g;s,/,_,g'`

d=`osascript -e "$dcmd" | awk '{print $4 $3 $2}' | sed 's/January/01/;s/February/02/;s/March/03/;s/April/04/;s/May/05/;s/June/06/;s/July/07/;s/August/08/;s/September/09/;s/October/10/;s/November/11/;s/December/12/'`
m="$t-$d-$e"

#or MPEGES
cmd="tell application \"eyetv\" to export from  recording id $id to \"$macpath:$m.mpg\" as MPEGPS"

echo "$m"
echo "$cmd"
osascript -e "$cmd"

echo "end osascript"

endwrite $m.mpg

#mplex -f 8 -o ${m}.mpg $$.mpa $$.mpv


#rm $$.mp[av]

done
