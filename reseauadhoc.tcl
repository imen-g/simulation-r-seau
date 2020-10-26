
# Definition les options
set val(chan)           Channel/WirelessChannel    ;# channel type
set val(prop)           Propagation/TwoRayGround   ;# radio-propagation model
set val(netif)          Phy/WirelessPhy            ;# network interface type
set val(mac)            Mac/802_11                 ;# MAC type
set val(ifq)            Queue/DropTail/PriQueue    ;# interface queue type
set val(ll)             LL                         ;# link layer type
set val(ant)            Antenna/OmniAntenna        ;# antenna model
set val(ifqlen)         50                         ;# max packet in ifq
set val(nn)             3                          ;# number of mobilenodes
set val(rp)             DSDV                       ;# routing protocol
set val(x)              500   			   ;# X dimension of topography
set val(y)              400   			   ;# Y dimension of topography  
set val(stop)		150			   ;# time of simulation end


set ns		  [new Simulator]
set tracefd       [open simple.tr w]
set windowVsTime2 [open win.tr w] 
set namtrace      [open simwrls.nam w]    
set f0            [open debit.tr w]
set f1            [open packets_lost.tr w]

$ns trace-all $tracefd
$ns namtrace-all-wireless $namtrace $val(x) $val(y)

# création de la topologie
set topo       [new Topography]

$topo load_flatgrid $val(x) $val(y)

#création  General Operations Director (pour le stockage des informations globales sur le réseau ou noeuds)GOD
create-god $val(nn)



# configuration des noeuds
        $ns node-config -adhocRouting $val(rp) \
			 -llType $val(ll) \
			 -macType $val(mac) \
			 -ifqType $val(ifq) \
			 -ifqLen $val(ifqlen) \
			 -antType $val(ant) \
			 -propType $val(prop) \
			 -phyType $val(netif) \
			 -channelType $val(chan) \
			 -topoInstance $topo \
			 -agentTrace ON \
			 -routerTrace ON \
			 -macTrace OFF \
			 -movementTrace ON
			 
	for {set i 0} {$i < $val(nn) } { incr i } {
		set node_($i) [$ns node]	
	}

# postion initiales des noeuds
$node_(0) set X_ 5.0
$node_(0) set Y_ 5.0
$node_(0) set Z_ 0.0

$node_(1) set X_ 490.0
$node_(1) set Y_ 285.0
$node_(1) set Z_ 0.0

$node_(2) set X_ 150.0
$node_(2) set Y_ 240.0
$node_(2) set Z_ 0.0

#nommer les noeuds
$ns at 0.0 "$node_(0) label SOURCE"
$ns at 0.0 "$node_(1) label DESTINATION"

#coloration des noeuds
$node_(0) color red
$ns at 0.0 "$node_(0) color red"
$node_(1) color green
$ns at 0.0 "$node_(1) color green"


#generation des mouvements
$ns at 10.0 "$node_(0) setdest 250.0 250.0 3.0"
$ns at 20.0 "$node_(1) setdest 45.0 285.0 5.0"
$ns at 10.0 "$node_(2) setdest 480.0 300.0 5.0" 

#connection TCP entre les noeuds node_(0) et node_(1)
set tcp [new Agent/TCP/Newreno]
$tcp set class_ 2
set sink [new Agent/LossMonitor]
$ns attach-agent $node_(0) $tcp
$ns attach-agent $node_(1) $sink
$ns connect $tcp $sink
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ns at 10.0 "$ftp start" 

# fenetre de protocole TCP
proc plotWindow {tcpSource file} {
global ns
set time 0.01
set now [$ns now]
set cwnd [$tcpSource set cwnd_]
puts $file "$now $cwnd"
$ns at [expr $now+$time] "plotWindow $tcpSource $file" }
$ns at 10.1 "plotWindow $tcp $windowVsTime2"  

#defition les tailles des noeuds dans nam
for {set i 0} {$i < $val(nn)} { incr i } {
$ns initial_node_pos $node_($i) 50
}

#fonction pour enregistrer les statistiques (débit,retard)
proc record {} {
  global sink f0 f1 
   set ns [Simulator instance]
   set time 0.05
   set bw0 [$sink set npkts_]
   set bw1 [$sink set nlost_]
   set now [$ns now]
   puts $f0 "$now [expr $bw0]"
   puts $f1 "$now [expr $bw1]"
   $ns at [expr $now+$time] "record"
  }

# la fin de simulation pour les noeuds
for {set i 0} {$i < $val(nn) } { incr i } {
    $ns at $val(stop) "$node_($i) reset";
}

# fin nam et fin simulation 
$ns at 0.0 "record"
$ns at $val(stop) "$ns nam-end-wireless $val(stop)"
$ns at $val(stop) "stop"
$ns at 150.01 "puts \"end simulation\" ; $ns halt"
proc stop {} {
    global ns tracefd namtrace f0 f1
    close $f0
    close $f1
    exec xgraph packets_lost.tr win.tr debit.tr &
    exec xgraph win.tr &
    exec xgraph debit.tr &
    $ns flush-trace
    close $tracefd
    close $namtrace
exec nam simwrls.nam &
}
$ns run

