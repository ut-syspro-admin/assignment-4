#!/bin/bash
# Test code for syspro2023 kadai4
# Written by Shinichi Awamoto and Daichi Morita
# Edited by PENG AO

state=0
warn() { echo $1; state=1; }
dir=$(mktemp -d)
trap "rm -rf $dir" 0

check-report() {
    if [ ! -f report-$1.txt ]; then
        $2 "kadai-$1: Missing report-$1.txt."
    elif [ `cat report-$1.txt | wc -l` -eq 0 ]; then
        $2 "kadai-$1: 'report-$1.txt' is empty!"
    fi
}

kadai-a() {
    if [ -d kadai-a ]; then
        cp -r kadai-a $dir
        pushd $dir/kadai-a > /dev/null 2>&1

        local client=udpechoclient
        local server=udpechoserver

        if [ ! -f Makefile ]; then
            warn "kadai-a: Missing Makefile"
        fi

        make $client $server > /dev/null 2>&1

        for bin in $client $server; do
            if [ -f $bin ]; then continue; fi
            warn "kadai-a: Failed to generate the binary($bin) with '$ make $client $server'"
        done

        local port=$(($RANDOM % 100 + 25555))

        man open > __before.txt
        ./$server $port > /dev/null 2>&1 &
        sleep 0.2
        ./$client 127.0.0.1 $port < __before.txt > __after.txt &

        sleep 1

        disown -a
        pkill -Kill $client
        pkill -Kill $server

        if [ ! -z `diff __before.txt __after.txt` ]; then
            warn "kadai-a: Diff detected between clientinput and output"
        fi

        make clean > /dev/null 2>&1

        for bin in $client $server; do
            if [ ! -f $bin ]; then continue; fi
            warn "kadai-a: Failed to remove the binary with '$ make clean'."
        done

        if [ ! -z "`find . -name \*.o`" ]; then
            warn "kadai-a: Failed to remove object files(*.o) with '$ make clean'."
        fi

        if [ `grep '\-Wall' Makefile | wc -l` -eq 0 ]; then
            warn "kadai-a: Missing '-Wall' option."
        fi

        check-report a warn

        popd > /dev/null 2>&1
    else
        warn "kadai-a: No 'kadai-a' directory!"
    fi
}

kadai-b() {
    if [ -d kadai-b ]; then
        cp -r kadai-b $dir
        pushd $dir/kadai-b > /dev/null 2>&1

        local client=tcpechoclient
        local server1=tcpechoserver1
        local server2=tcpechoserver2

        if [ ! -f Makefile ]; then
            warn "kadai-b: Missing Makefile"
        fi

        make $client $server1 $server2 > /dev/null 2>&1

        for bin in $client $server1 $server2; do
            if [ -f $bin ]; then continue; fi
            warn "kadai-b: Failed to generate the binary($bin) with '$ make $client $server1 $server2'"
        done

        if ! check-tcp $client $server1; then
            warn "kadai-b: diff detected between client input and output (tcpechoserver1)"
        fi

        if ! check-tcp $client $server2; then
            warn "kadai-b: diff detected between client input and output (tcpechoserver2)"
        fi

        make clean > /dev/null 2>&1

        for bin in $client $server1 $server2; do
            if [ ! -f $bin ]; then continue; fi
            warn "kadai-b: Failed to remove the binary with '$ make clean'."
        done

        if [ ! -z "`find . -name \*.o`" ]; then
            warn "kadai-b: Failed to remove object files(*.o) with '$ make clean'."
        fi

        if [ `grep '\-Wall' Makefile | wc -l` -eq 0 ]; then
            warn "kadai-b: Missing '-Wall' option."
        fi

        check-report b warn

        popd > /dev/null 2>&1
    else
        warn "kadai-b: No 'kadai-b' directory!"
    fi
}

check-tcp() {
    local port=$(($RANDOM % 100 + 25555))
    local before=__before
    local after1=__after1
    local after2=__after2

    yes "some text" | head -n 10000 > $before	
        
    ./$2 $port > /dev/null 2>&1 &
    sleep 0.2
    ./$1 127.0.0.1 $port < $before > $after1 &
    ./$1 127.0.0.1 $port < $before > $after2 &

    sleep 2

    disown -a
    pkill -Kill $1
    pkill -Kill $2

    diff $before $after1 > /dev/null 2>&1 && diff $before $after2 > /dev/null 2>&1
    local RET=$?
    rm -f $before $after1 $after2 
    return $RET
}

kadai-c() {
    if [ -d kadai-c ]; then
        cp -r kadai-c $dir
        pushd $dir/kadai-c > /dev/null 2>&1

        local client=iperfc
        local server=iperfs

        if [ ! -f Makefile ]; then
            warn "kadai-c: Missing Makefile"
        fi

        make $client $server > /dev/null 2>&1

        for bin in $client $server; do
            if [ -f $bin ]; then continue; fi
            warn "kadai-c: Failed to generate the binary($bin) with '$ make $client $server'"
        done

        local port=$(($RANDOM % 100 + 25555))
        ./$server $port > /dev/null 2>&1 &
        sleep 0.2

        iperfc_result=$(./$client 127.0.0.1 $port)
        if [ $(echo $iperfc_result | wc -l) -ne 1 ]; then
            warn "kadai-c: the output must be one line and the format is: (data size) (elapsed time) (throughput)"
        fi

        disown -a
        pkill -Kill $client
        pkill -Kill $server

        make clean > /dev/null 2>&1

        for bin in $client $server; do
            if [ ! -f $bin ]; then continue; fi
            warn "kadai-c: Failed to remove the binary with '$ make clean'."
        done

        if [ ! -z "`find . -name \*.o`" ]; then
            warn "kadai-c: Failed to remove object files(*.o) with '$ make clean'."
        fi

        if [ `grep '\-Wall' Makefile | wc -l` -eq 0 ]; then
            warn "kadai-c: Missing '-Wall' option."
        fi

        check-report c warn

        popd > /dev/null 2>&1
    else
        warn "kadai-c: No 'kadai-c' directory!"
    fi
}

if [ $# -eq 0 ]; then
    echo "#############################################"
    echo "Running tests..."
fi
for arg in {a..c}; do
    if [ $# -eq 0 ] || [[ "$@" == *"$arg"* ]]; then kadai-$arg; fi
done
if [ $# -eq 0 ]; then
    if [ $state -eq 0 ]; then echo "All tests have passed!"; fi
    echo "#############################################"
fi
exit $state
