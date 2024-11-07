#!/bin/bash
#BSUB -J dedup_samtools_job_long        # Job name
#BSUB -o dedup_samtools_%J.out          # Standard output file (%J expands to job ID)
#BSUB -e dedup_samtools_%J.err          # Standard error file
#BSUB -n 1                              # Number of cores
#BSUB -R "span[hosts=1]"                # Run on a single node
#BSUB -W 24:00                          # Extended wall time for a long run (24 hours; adjust as needed)
#BSUB -M 16000                          # Increase memory limit to 16 GB (adjust as needed)

# Load the Conda environment
source /home/krishna.ganta-umw/.bashrc
conda activate /home/krishna.ganta-umw/miniconda3/envs/ngs_analysis

# Define directories with descriptive names
INPUT_DIR="/home/krishna.ganta-umw/phipseq/aligned_bam"                # Location of original BAM files
DEDUP_DIR="/home/krishna.ganta-umw/phipseq/filtered_bam_dedup_phi"         # Directory for deduplicated BAM files
QC_DIR="/home/krishna.ganta-umw/phipseq/qc_files_dedup_phi"                # Directory for deduplication QC reports
MULTIQC_OUTPUT_DIR="/home/krishna.ganta-umw/phipseq/multiqc_report_phi"    # Directory for MultiQC output

# Ensure output directories exist
mkdir -p ${DEDUP_DIR}
mkdir -p ${QC_DIR}
mkdir -p ${MULTIQC_OUTPUT_DIR}

# Process each BAM file in the input directory
for BAM_FILE in ${INPUT_DIR}/*.bam; do
    # Extract filename without extension
    FILENAME=$(basename ${BAM_FILE} .bam)

    # Define output paths
    SORTED_BAM="${DEDUP_DIR}/${FILENAME}_sorted.bam"
    DEDUP_BAM="${DEDUP_DIR}/${FILENAME}_deduplicated.bam"
    QC_REPORT="${QC_DIR}/${FILENAME}_flagstat.txt"

    # Step 1: Sort the BAM file if not already sorted
    echo "Sorting BAM file: ${BAM_FILE}"
    samtools sort -o ${SORTED_BAM} ${BAM_FILE}

    # Step 2: Deduplicate using samtools markdup
    echo "Deduplicating BAM file: ${SORTED_BAM}"
    samtools markdup -r ${SORTED_BAM} ${DEDUP_BAM}

    # Step 3: Run QC on deduplicated BAM using samtools flagstat
    echo "Running QC on deduplicated BAM file: ${DEDUP_BAM}"
    samtools flagstat ${DEDUP_BAM} > ${QC_REPORT}

    echo "Completed processing for ${BAM_FILE}"
done

# Step 4: Run MultiQC to generate a combined HTML report
echo "Running MultiQC to create combined QC report."
multiqc ${QC_DIR} -o ${MULTIQC_OUTPUT_DIR}

echo "All BAM files processed and MultiQC report generated in ${MULTIQC_OUTPUT_DIR}."

# Deactivate the Conda environment
conda deactivate
