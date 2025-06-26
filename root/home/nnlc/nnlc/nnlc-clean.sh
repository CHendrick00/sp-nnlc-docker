#!/usr/bin/env bash

OP=/data/output/$VEHICLE
RLD=/data/output/$VEHICLE/rlogs
RVW=$OP/review
RLOGS_ROUTE=$RVW/rlogs_route

# nnlc-process
cd $OP
echo
echo "NNLC-PROCESS OUTPUTS"
echo "---------------------------"
find . '(' -name "*.lat" -o -name "*.csv" -o -name "*.feather" -o -name "*.txt" -o -name "*.png" -o -wholename "plots*/*" -o -wholename "*steer_cmd/*" -o -wholename "*torque_adjusted_eps/*" ')' -depth -not -path "./review/*" | sort
echo "Clean nnlc-process outputs directory? (y/n)"
read INP1

if [ $INP1 == 'y' ]; then
  rm -r $OP/*.lat $OP/*.csv $OP/*.feather $OP/*.txt $OP/*.png $OP/plots* $OP/*steer_cmd $OP/*torque_adjusted_eps 2>&1
  echo "$OP cleaned"
else
  echo
fi

cd $RLD
echo
echo "NNLC-PROCESS RLOGS"
echo "---------------------------"
find . -name "*.zst" -depth | sort
echo "Clean rlogs in nnlc-process processing directory? (y/n)"
read INP2

if [ $INP2 == 'y' ]; then
  rm $RLD/*.zst 2>&1
  echo "$RLD cleaned"
else
  echo
fi

# nnlc-review
cd $RVW
echo
echo "NNLC-REVIEW OUTPUTS"
echo "---------------------------"
find . '(' -name "*.lat" -o -name "*.csv" -o -name "*.feather" -o -name "*.txt" -o -name "*.png" -o -wholename "plots*/*" ')' -depth | sort
echo "Clean nnlc-review outputs directory? (y/n)"
read INP3

if [ $INP3 == 'y' ]; then
  rm -r $RVW/*.lat $RVW/*.csv $RVW/*.feather $RVW/latfiles.txt $RVW/plots* 2>&1
  echo "$RVW cleaned"
else
  echo
fi

cd $RLOGS_ROUTE
echo
echo "NNLC-PROCESS RLOGS"
echo "---------------------------"
find . -name "*.zst" -depth | sort
echo "Clean rlogs in nnlc-review processing directory? (y/n)"
read INP4

if [ $INP4 == 'y' ]; then
  rm $RLOGS_ROUTE/*.zst 2>&1
  echo "$RLOGS_ROUTE cleaned"
else
  echo
fi

echo
echo "Done!"
echo
exit 0