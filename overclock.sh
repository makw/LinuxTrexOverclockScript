#!/bin/sh

  # Check if clock modifier was included as a parameter.
  if [ $1 ]
  then
    clkmod=$(awk 'BEGIN {print '$1'/100}')
  else
    clkmod=1
  fi

  # Enable persistence mode.
  sudo nvidia-smi -pm ENABLED

  # List cards.
  nvidia-smi -L

  # Reset gpu clocks -- must do as sudo.
  echo "Resetting gpu clocks..."
  sudo nvidia-smi -rgc

  # Set color variables.
  colour1='\033[0;32m' # green
  colour2='\033[0;31m' # red
  clear='\033[0m'

  # Location of csv
  gpudb="/etc/trex/example.csv"  # put exact path here ex: /etc/trex/example.csv

  # For loop to assign overclock values.
  for card in $(nvidia-smi -L | sed 's/GPU / /;s/TX /:/;s/ (UUID: /:/;s/)/ /g' | awk -F':' '{print $1"," $3"," $4}'); do
    slot=$(echo $card | awk -F',' '{print $1}')
    model=$(echo $card | awk -F',' '{print $2}')
    uuid=$(echo $card | awk -F',' '{print $3}')

    gpucheck=$(awk -F',' '{if ($1 == "'${uuid}'") {print 1}}' ${gpudb})

    if [ -n ${gpucheck} ]
    then
      title=$(awk -F',' '{if ($1 == "'${uuid}'") {print $2}}' ${gpudb})
      perf=$(awk -F',' '{if ($1 == "'${uuid}'") {print $3}}' ${gpudb})
      pl=$(awk -F',' '{if ($1 == "'${uuid}'") {print $4}}' ${gpudb})
      cclock=$(awk -F',' '{if ($1 == "'${uuid}'") {print $5}}' ${gpudb})
      mclock=$(awk -F',' '{if ($1 == "'${uuid}'") {print $6*'$clkmod'}}' ${gpudb})

      echo ">>> Setting ${colour1}${title}${clear} GPU Slot: ${slot}"
      sudo nvidia-smi -pl ${pl} -i ${slot}
      nvidia-settings -c :0 -a [gpu:${slot}]/GPUGraphicsClockOffset[${perf}]=${cclock} -a [gpu:${slot}]/GPUMemoryTransferRateOffset[${perf}]=${mclock}

    else
      echo ">>> ${colour2}No Match${clear} for $model UUID: ${uuid} Slot: ${slot}"

    fi

  done

