#!/bin/sh

# Base parameters for launching server
  servertest0="dapltest -T S -d -D ofa-v2-ib0"
  servertest1="dapltest -T S -d -D ofa-v2-mlx4_0-1s"

  parameterT="-i 1000 client SR 409600 1 server SR 409600 1"
  parameterP="-i 1000 RW 409600 2"


  if [ '1'=='1' ]; then
  server="smic005h"
  clients="smic006h"
  clienttest0="dapltest -T P -D ofa-v2-ib0 -s $server $parameterP"
  clienttest1="dapltest -T P -D ofa-v2-mlx4_0-1s -s $server $parameterP"
  servertest="$servertest0"
  clienttest="$clienttest0"
  fi

  if [ '0' == '1' ]; then
  server="smic199"
  clients="smic200"
  clienttest0="dapltest -T T -D ofa-v2-ib0 -s $server $parameterP"
  clienttest1="dapltest -T P -D ofa-v2-mlx4_0-1s -s $server $parameterP"
  servertest="$servertest1"
  clienttest="$clienttest1"
  fi


# Clear Logs

  top=$(pwd)
  log=$top/log
  if [ ! -d "$log" ]; then
    mkdir -v $log
  fi

# Start the server on a smic001
  #server="smic003"

   if [ -f "$log/server-$server.log" ]; then
    echo "Clear old logs"
    rm -v $log/server-$server.log
    touch  $log/server-$server.log
  fi
  ssh $server "nohup $servertest >& $log/server-$server.log  &"


# Run tests on clients
  for client in $clients; do
    # Clean up earlier log
    if [ -f "$log/client-$client.log" ]; then
      rm $log/client-$client.log
      touch  $log/client-$client.log
    fi
    # Run differents tests for the client
    for ctest in "$clienttest"; do
      ssh $client "$ctest" >> $log/client-$client.log 2>&1
      echo "$(if [ $? -eq 0 ]; then echo  Success; else echo  Failure; fi) $server -> $client"
    done
 done

# Cleanup server
  #dapltest -T Q -s $server -D ofa-v2-mlx4_0-1s >> $log/server-$server.log 
  ssh $server 'pkill dapltest'
  echo "Check log directory for,
        $log/client-$client.log"
  sleep 3

