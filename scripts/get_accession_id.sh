set -euo pipefall

INPUT_FILE="datasets.txt"
OUTPUT_FILE="../accession_IDs.txt"

esearch -db sra -query GSM1275862 | efetch -format runinfo
