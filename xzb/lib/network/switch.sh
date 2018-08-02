#!/bin/sh

restore6855Esw()
{
	echo "restore GSW to dump switch mode"
	#port matrix mode
	switch reg w 2004 ff0000 #port0
	switch reg w 2104 ff0000 #port1
	switch reg w 2204 ff0000 #port2
	switch reg w 2304 ff0000 #port3
	switch reg w 2404 ff0000 #port4
	switch reg w 2504 ff0000 #port5
	switch reg w 2604 ff0000 #port6
	switch reg w 2704 ff0000 #port7

	#LAN/WAN ports as transparent mode
	switch reg w 2010 810000c0 #port0
	switch reg w 2110 810000c0 #port1
	switch reg w 2210 810000c0 #port2
	switch reg w 2310 810000c0 #port3
	switch reg w 2410 810000c0 #port4
	switch reg w 2510 810000c0 #port5
	switch reg w 2610 810000c0 #port6
	switch reg w 2710 810000c0 #port7
	
	#clear mac table if vlan configuration changed
	switch clear
	switch vlan clear 
}

config6855Esw()
{
	if [ "$1" = "LLLLW" ]; then
		#VLAN member port
		switch vlan  set 1 1 11110011
		switch vlan  set 2 2 00001100
		#set PVID
		switch pvid 4 2
		switch pvid 5 2
		#LAN/WAN ports as security mode
		switch reg w 2004 ff0003 #port0
		switch reg w 2104 ff0003 #port1
		switch reg w 2204 ff0003 #port2
		switch reg w 2304 ff0003 #port3
		switch reg w 2404 ff0003 #port4
		switch reg w 2504 ff0003 #port5
		switch reg w 2604 ff0003 #port6
	elif [ "$1" = "WLLLL" ]; then
		#VLAN member port
		switch vlan  set 1 1 01111011
		switch vlan  set 2 2 10000100
		#set PVID
		switch pvid 0 2
		switch pvid 5 2
		#LAN/WAN ports as security mode
		switch reg w 2004 ff0003 #port0
		switch reg w 2104 ff0003 #port1
		switch reg w 2204 ff0003 #port2
		switch reg w 2304 ff0003 #port3
		switch reg w 2404 ff0003 #port4
		switch reg w 2504 ff0003 #port5
		switch reg w 2604 ff0003 #port6
	fi
}

setup_switch()
{
	echo "7621 use an independent gmac as lan, LLLLW"
	restore6855Esw
	#config6855Esw LLLLW
}

reset_switch()
{
	echo "7621 use an independent gmac as lan & wan"
	restore6855Esw
}
