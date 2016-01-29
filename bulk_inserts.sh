#!/bin/bash
origin=$(pwd)

cd $1

FILES=*

if [ ! -d log ]; then mkdir log; fi

for f in $FILES
do
    echo "Processing $f file..."
    
    # take action on each file. $f store current file name
    curl -H "Content-Type:application/json" -X POST -d @$f http://localhost:5984/dde2_production/_bulk_docs > log/$f
    
done

cd $origin
