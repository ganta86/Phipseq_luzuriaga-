#BSUB -J align_p1_9
#BSUB -o align_pep_p1_p9.%J.out
#BSUB -e align_pep_p1_p9.%J.err
#BSUB -n 36
#BSUB -M 4GB
#BSUB -q long

# Load necessary modules
module load bowtie/1.3.1
module load samtools/1.16.1

# Define the path for Trimmomatic and adapters
TRIMMOMATIC_JAR=/share/pkg/trimmomatic/0.32/trimmomatic-0.32.jar
ADAPTERS_PATH=/home/krishna.ganta-umw/miniconda3/envs/ngs_analysis/share/trimmomatic-0.39-2/adapters/TruSeq3-SE.fa

# Define Trimmomatic parameters for single-end reads, trimming to 50 bases
TRIM_PARAMS="ILLUMINACLIP:${ADAPTERS_PATH}:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:50 CROP:50"

# Define directories
INPUT_DIR="${PWD}"
OUTPUT_DIR="${PWD}/aligned_bam"
TRIMMED_DIR="${PWD}/trimmed_reads"
mkdir -p "${OUTPUT_DIR}" "${TRIMMED_DIR}"

# Process all FASTQ files in Krishna-P1_p9 directories
for DIR in Krishna-P{1..9}; do
    echo "Processing directory ${DIR}..."

    for fq in ${INPUT_DIR}/${DIR}/*.fastq.gz; do
        base_name=$(basename "${fq}" .fastq.gz)
        sample_index=$(echo "${base_name}" | grep -o -E '[0-9]{3}')
        plate=$(basename ${DIR})

        trimmed_fq="${TRIMMED_DIR}/${base_name}_trimmed.fastq"
        final_base_name="${plate}_${base_name}"

        # Run Trimmomatic for trimming
        zcat "${fq}" | java -jar ${TRIMMOMATIC_JAR} SE -threads 4 /dev/stdin "${trimmed_fq}" ${TRIM_PARAMS}

        # Align trimmed reads with Bowtie
        bowtie -a --chunkmbs 256 -n 3 -l 28 -I 0 -X 800 -p 4 -q -S pep2_ref50 "${trimmed_fq}" "${OUTPUT_DIR}/${final_base_name}.sam"

        # Convert SAM to BAM and delete the SAM file
        samtools view -bS "${OUTPUT_DIR}/${final_base_name}.sam" > "${OUTPUT_DIR}/${final_base_name}.bam"
        rm "${OUTPUT_DIR}/${final_base_name}.sam"

        echo "Processed ${fq} to ${OUTPUT_DIR}/${final_base_name}.bam"
    done
done

echo "Alignment process completed."

(ngs_analysis) [krishna.ganta-umw@hpcc04 phipseq]$
