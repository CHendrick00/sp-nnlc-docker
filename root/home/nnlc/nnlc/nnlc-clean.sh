#!/usr/bin/env bash

OP=/data/output/$VEHICLE
RLD=/data/output/$VEHICLE/rlogs
RVW=$OP/review
RLOGS_ROUTE=$RVW/rlogs_route

# nnlc-process
if [ -d $OP ]; then
  cd $OP
  echo
  FILES=$(find . -depth '(' -name "*.lat" -o -name "*.LAT" -o -name "*.csv" -o -name "*.feather" -o -name "*.txt" -o -name "*.png" -o -wholename "plots*/*" -o -wholename "*steer_cmd/*" -o -wholename "*torque_adjusted_eps/*" ')' -not -path "./review/*" | sort)
  if [[ -n $FILES ]]; then
    echo "NNLC-PROCESS OUTPUTS"
    echo "---------------------------"
    echo "$FILES"
    echo
    while true; do
      read -p "Clean nnlc-process outputs directory? This action is irreversable. (y/n) " yn
      case $yn in
          [Yy])
            echo
            rm -rf $OP/*.lat $OP/*.LAT $OP/*.csv $OP/*.feather $OP/*.txt $OP/*.png $OP/plots* $OP/*steer_cmd $OP/*torque_adjusted_eps
            FILES=$(find . -depth '(' -name "*.lat" -o -name "*.LAT" -o -name "*.csv" -o -name "*.feather" -o -name "*.txt" -o -name "*.png" -o -wholename "plots*/*" -o -wholename "*steer_cmd/*" -o -wholename "*torque_adjusted_eps/*" ')' -not -path "./review/*" | sort)
            if [[ -n $FILES ]]; then
              echo "An error occurred and some or all files could not be deleted. Please clean this directory manually."
            else
              echo "[$OP] cleaned."
            fi
            break;;
          [Nn])
            echo
            echo "Skipping [$OP]..."
            break;;
          *)
            echo "Invalid response. Please answer y or n.";;
      esac
    done
  else
    echo
    echo "[$OP] already clean. Nothing to do."
  fi
else
  echo
  echo "[$OP] doesn't exist. Nothing to do."
fi

# nnlc-process rlogs
if [ -d $RLD ]; then
  cd $RLD
  echo
  FILES=$(find . -depth '(' -name "*.zst" -o -name "*.ZST" ')' | sort)
  if [[ -n $FILES ]]; then
    echo "NNLC-PROCESS RLOGS"
    echo "---------------------------"
    echo "$FILES"
    echo
    while true; do
      read -p "Clean rlogs in nnlc-process processing directory? This action is irreversable. (y/n) " yn
      case $yn in
          [Yy])
            echo
            rm -rf $RLD/*.zst $RLD/*.ZST
            FILES=$(find . -depth '(' -name "*.zst" -o -name "*.ZST" ')' | sort)
            if [[ -n $FILES ]]; then
              echo "An error occurred and some or all files could not be deleted. Please clean this directory manually."
            else
              echo "[$RLD] cleaned."
            fi
            break;;
          [Nn])
            echo
            echo "Skipping [$RLD]..."
            break;;
          *)
            echo "Invalid response. Please answer y or n.";;
      esac
    done
  else
    echo
    echo "[$RLD] already clean. Nothing to do."
  fi
else
  echo
  echo "[$RLD] doesn't exist. Nothing to do."
fi

# nnlc-review
if [ -d $RVW ]; then
  cd $RVW
  echo
  FILES=$(find . -depth '(' -name "*.lat" -o -name "*.LAT" -o -name "*.csv" -o -name "*.feather" -o -name "*.txt" -o -name "*.png" -o -wholename "plots*/*" ')' | sort)
  if [[ -n $FILES ]]; then
    echo "NNLC-REVIEW OUTPUTS"
    echo "---------------------------"
    echo "$FILES"
    echo
    while true; do
      read -p "Clean nnlc-review outputs directory? This action is irreversable. (y/n) " yn
      case $yn in
          [Yy])
            echo
            rm -rf $RVW/*.lat $RVW/*.LAT $RVW/*.csv $RVW/*.feather $RVW/*.txt $RVW/*.png $RVW/*plots*
            FILES=$(find . -depth '(' -name "*.lat" -o -name "*.LAT" -o -name "*.csv" -o -name "*.feather" -o -name "*.txt" -o -name "*.png" -o -wholename "*plots*/*" ')' | sort)
            if [[ -n $FILES ]]; then
              echo "An error occurred and some or all files could not be deleted. Please clean this directory manually."
            else
              echo "[$RVW] cleaned."
            fi
            break;;
          [Nn])
            echo
            echo "Skipping [$RVW]..."
            break;;
          *)
            echo "Invalid response. Please answer y or n.";;
      esac
    done
  else
    echo
    echo "[$RVW] already clean. Nothing to do."
  fi
else
  echo
  echo "[$RVW] doesn't exist. Nothing to do."
fi

if [ -d $RLOGS_ROUTE ]; then
  cd $RLOGS_ROUTE
  echo
  FILES=$(find . -depth '(' -name "*.zst" -o -name "*.ZST" ')' | sort)
  if [[ -n $FILES ]]; then
    echo "NNLC-REVIEW RLOGS"
    echo "---------------------------"
    echo "$FILES"
    echo
    while true; do
      read -p "Clean rlogs in nnlc-review processing directory? This action is irreversable. (y/n) " yn
      case $yn in
          [Yy])
            echo
            rm -rf $RLOGS_ROUTE/*.zst $RLOGS_ROUTE/*.ZST
            FILES=$(find . -depth '(' -name "*.zst" -o -name "*.ZST" ')' | sort)
            if [[ -n $FILES ]]; then
              echo "An error occurred and some or all files could not be deleted. Please clean this directory manually."
            else
              echo "[$RLOGS_ROUTE] cleaned."
            fi
            break;;
          [Nn])
            echo
            echo "Skipping [$RLOGS_ROUTE]..."
            break;;
          *)
            echo "Invalid response. Please answer y or n.";;
      esac
    done
  else
    echo
    echo "[$RLOGS_ROUTE] already clean. Nothing to do."
  fi
else
  echo
  echo "[$RLOGS_ROUTE] doesn't exist. Nothing to do."
fi

echo
echo "Done!"
echo
exit 0