#!/bin/bash

# assumes first argument is an XCF file

num_layers=`identify "$1" | wc -l`

for (( layer_id=0; layer_id <$num_layers; layer_id ++ ))
do
	out_file="$1" 
	out_file+="$layer_id"
	out_file+=".png"

	echo "."

	convert "$1"[$layer_id] "$out_file"

	echo $out_file
done