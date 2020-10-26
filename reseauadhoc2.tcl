#options du lien
set opt(chan)           Channel/WirelessChannel    ;
set opt(prop)           Propagation/TwoRayGround   ;
set opt(netif)          Phy/WirelessPhy            ;
set opt(mac)            Mac/802_11                 ;
set opt(ifq)            Queue/DropTail/PriQueue    ;
set opt(ll)             LL                         ;
set opt(ant)            Antenna/OmniAntenna        ;
set opt(ifqlen)         50                         ;
set opt(nn)             6                          ;
set opt(adhocRouting)   DSDV                       ;
set opt(x)      500                            ;
set opt(y)      400                            ;
set opt(seed)   0.0                            ;
set opt(stop)   150                            ;


set opt(ftp1-start)      10.0
set opt(ftp2-start)      10.0
set num_wired_nodes      2
set num_bs_nodes         1

# creation simulateur
set ns_   [new Simulator]

# hierarchical routing
$ns_ node-config -addressType hierarchical
AddrParams set domain_num_ 2           ;# nbre de domaines
lappend cluster_num 2 2                ;# nbre  clusters dans chaque  domaine
AddrParams set cluster_num_ $cluster_num
lappend eilastlevel 1 1 4 3             ;# nbre des noeuds dans chaque cluster 
AddrParams set nodes_num_ $eilastlevel ;#

set tracefd  [open trace2.tr w]
set namtrace [open namtrace.nam w]

#fichier de trace de protocole TCP
set windowVsTime2 [open win.tr w] 

#fichier de trace débit
set f0            [open debit0.tr w]

#fichier de trace paquets perduess
set f1            [open packets_lost1.tr w]


$ns_ trace-all $tracefd
$ns_ namtrace-all-wireless $namtrace $opt(x) $opt(y)

#création topologie
set topo   [new Topography]
$topo load_flatgrid $opt(x) $opt(y)

# creation God
create-god [expr $opt(nn) + $num_bs_nodes]

#creation noeuds 
set temp {0.0.0 0.1.0}        ;
for {set i 0} {$i < $num_wired_nodes} {incr i} {
    set W($i) [$ns_ node [lindex $temp $i]] 
}

# configuration base-station 
$ns_ node-config -adhocRouting $opt(adhocRouting) \
                 -llType $opt(ll) \
                 -macType $opt(mac) \
                 -ifqType $opt(ifq) \
                 -ifqLen $opt(ifqlen) \
                 -antType $opt(ant) \
                 -propType $opt(prop) \
                 -phyType $opt(netif) \
                 -channelType $opt(chan) \
		 -topoInstance $topo \
                 -wiredRouting ON \
		 -agentTrace ON \
                 -routerTrace OFF \
                 -macTrace OFF 

#create base-station node
set temp {1.0.0 1.0.1 1.0.2 1.0.3 1.1.0 1.1.1 1.1.2}   ;
                                   ;
set BS(0) [$ns_ node [lindex $temp 0]]
$BS(0) random-motion 0               ;

#position base-station
$BS(0) set X_ 15.0
$BS(0) set Y_ 25.0
$BS(0) set Z_ 0.0

#configuration : mobilenodes
$ns_ node-config -wiredRouting OFF
#création des noeuds mobiles
  for {set j 0} {$j < $opt(nn)} {incr j} {
    set node_($j) [ $ns_ node [lindex $temp \
	    [expr $j+1]] ]
    $node_($j) base-station [AddrParams addr2id \
	    [$BS(0) node-addr]]
}
# postion initiales des noeuds
$node_(0) set X_ 15.0
$node_(0) set Y_ 520.0
$node_(0) set Z_ 0.0

$node_(1) set X_ 490.0
$node_(1) set Y_ 285.0
$node_(1) set Z_ 0.0

$node_(2) set X_ 150.0
$node_(2) set Y_ 240.0
$node_(2) set Z_ 0.0

$node_(3) set X_ 750.0
$node_(3) set Y_ 140.0
$node_(3) set Z_ 0.0

$node_(4) set X_ 350.0
$node_(4) set Y_ 470.0
$node_(4) set Z_ 0.0

$node_(5) set X_ 501.0
$node_(5) set Y_ 420.0
$node_(5) set Z_ 0.0

#creation des liens entre wired et BS 

$ns_ duplex-link $W(0) $W(1) 5Mb 2ms DropTail
$ns_ duplex-link $W(1) $BS(0) 5Mb 2ms DropTail

$ns_ duplex-link-op $W(0) $W(1) orient down
$ns_ duplex-link-op $W(1) $BS(0) orient left-down

#  TCP connections
set tcp1 [new Agent/TCP]
$tcp1 set class_ 2
set sink1 [new Agent/LossMonitor]
$ns_ attach-agent $node_(0) $tcp1
$ns_ attach-agent $W(0) $sink1
$ns_ connect $tcp1 $sink1
set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1
$ns_ at $opt(ftp1-start) "$ftp1 start"

set tcp2 [new Agent/TCP]
$tcp2 set class_ 2
set sink2 [new Agent/LossMonitor]
$ns_ attach-agent $W(1) $tcp2
$ns_ attach-agent $node_(5) $sink2
$ns_ connect $tcp2 $sink2
set ftp2 [new Application/FTP]
$ftp2 attach-agent $tcp2
$ns_ at $opt(ftp2-start) "$ftp2 start"

#nommer les noeuds
$ns_ at 0.0 "$BS(0) label BASE-STATION"

#generation des mouvements
$ns_ at 10.0 "$node_(0) setdest 250.0 250.0 3.0"
$ns_ at 20.0 "$node_(1) setdest 450.0 285.0 5.0"
$ns_ at 10.0 "$node_(2) setdest 480.0 300.0 5.0" 
$ns_ at 10.0 "$node_(3) setdest 300.0 87.0 3.0"
$ns_ at 20.0 "$node_(4) setdest 96.0 25.0 5.0"
$ns_ at 10.0 "$node_(5) setdest 40.0 80.0 5.0"

#connection TCP entre les noeuds node_(2) et node_(5)
set tcp [new Agent/TCP/Newreno]
$tcp set class_ 2
set sink [new Agent/LossMonitor]
$ns_ attach-agent $node_(2) $tcp
$ns_ attach-agent $node_(5) $sink
$ns_ connect $tcp $sink
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ns_ at 10.0 "$ftp start" 

# fenetre de protocole TCP
proc plotWindow {tcpSource file} {
global ns_
set time 0.01
set now [$ns_ now]
set cwnd [$tcpSource set cwnd_]
puts $file "$now $cwnd"
$ns_ at [expr $now+$time] "plotWindow $tcpSource $file" }
$ns_ at 10.1 "plotWindow $tcp $windowVsTime2"  

#fonction pour enregistrer les statistiques (débit,paquet perdues)
proc record {} {
  global sink  f0 f1 
   set ns [Simulator instance]
   set time 0.05
   set bw0 [$sink set npkts_]
   set bw1 [$sink set nlost_]
  
   set now [$ns now]
   puts $f0 "$now [expr $bw0]"
   puts $f1 "$now [expr $bw1]"
  
   
   $ns at [expr $now+$time] "record"
  }


# taille des noeuds dans nam

for {set i 0} {$i < $opt(nn)} {incr i} {
    $ns_ initial_node_pos $node_($i) 50
} 
    
#fin de la simulation pour les noeuds 
for {set i } {$i < $opt(nn) } {incr i} {
    $ns_ at $opt(stop).0 "$node_($i) reset";
}
$ns_ at $opt(stop).0 "$BS(0) reset";

#fin de la simulation
$ns_ at 0.0 "record"
$ns_ at $opt(stop).0002 "puts \"NS EXITING...\" ; $ns_ halt"
$ns_ at $opt(stop).0001 "stop"
proc stop {} {
    global ns_ tracefd namtrace f0 f1 
    close $f0
    close $f1
    $ns_ flush-trace
    exec xgraph win.tr &
    exec xgraph debit0.tr &
    exec xgraph packets_lost1.tr &
    close $tracefd
    close $namtrace
    exec nam namtrace.nam &
}
$ns_ run


