#!/usr/bin/env bash

set -e

# Required parameters:
#
# LIGANDS_SMI
#
# Optional parameters:
#
# ADMET_CHECKS
# OUTPUT_FILE
#

OUTPUT_FILE=${OUTPUT_FILE:-output.txt}

rm -f headers.txt
for check in $ADMET_CHECKS; do
    echo -n "${check}_predicted,${check}_confidence,${check}_credibility," >> headers.txt
done
echo "jlogp" >> headers.txt

rm -f data.txt
cat "$LIGANDS_SMI" | while read smi
do
    echo "$smi" > ligand.smi
    for check in $ADMET_CHECKS; do
        runadmet.sh -f ligand.smi -p "$check" -a
        awk 'NR!=1 {printf "%s,%s,%s,",2,3,4}' /opt/fpadmet/RESULTS/predicted.txt >> data.txt
    done

    rm -f jlogp.txt
    java -jar /opt/JLogP/build/JLogP.jar ligand.smi jlogp.txt
    awk '{print $2}' jlogp.txt >> data.txt
done

cat headers.txt data.txt > "$OUTPUT_FILE"

rm -f data.txt headers.txt ligand.smi jlogp.txt

