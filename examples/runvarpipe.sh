#!/usr/bin/bash

if [ -z "$1" ]; then
    THREADS=4
else
    THREADS="$1"
fi

# Check if files follow the new naming pattern (e.g., sample_1.fastq.gz, sample_2.fastq.gz)
if ls *_1.fastq.gz >/dev/null 2>&1; then
    echo "Found files with _1.fastq.gz pattern, processing..."
    
    # Create symbolic links or rename files to match expected pattern for Varpipeline
    for file in *_1.fastq.gz; do
        base_name=$(basename "$file" _1.fastq.gz)
        
        # Create R1 file (forward reads)
        if [ ! -e "${base_name}_R1_001.fastq.gz" ]; then
            ln -s "$file" "${base_name}_R1_001.fastq.gz"
        fi
        
        # Create R2 file (reverse reads) if it exists
        if [ -e "${base_name}_2.fastq.gz" ]; then
            if [ ! -e "${base_name}_R2_001.fastq.gz" ]; then
                ln -s "${base_name}_2.fastq.gz" "${base_name}_R2_001.fastq.gz"
            fi
        fi
    done
    
# Original logic for Illumina lane-based naming
elif ls *_L001_R2_001* >/dev/null 2>&1; then
    echo "Found files with Illumina lane pattern, processing..."
    
    if [ -n '*_L001_R2_001*' ]
    then
       ls *_L001_R2_001* | sed 's/_L001_R2_001.fastq.gz//g' | awk '{print "cat "$0"_L001_R2_001.fastq.gz "$0"_L002_R2_001.fastq.gz "$0"_L003_R2_001.fastq.gz "$0"_L004_R2_001.fastq.gz >> "$0"_R2_001.fastq.gz"}' > run_2.sh
    fi

    if [ -n '*_L001_R2_001*' ]
    then
        ls *_L001_R1_001* | sed 's/_L001_R1_001.fastq.gz//g' | awk '{print "cat "$0"_L001_R1_001.fastq.gz "$0"_L002_R1_001.fastq.gz "$0"_L003_R1_001.fastq.gz "$0"_L004_R1_001.fastq.gz >> "$0"_R1_001.fastq.gz"}' > run_1.sh
    fi

    if [ -e run_1.sh ]
    then
       sh run_1.sh
    fi

    if [ -e run_2.sh ]
    then
       sh run_2.sh
    fi

    if [ -n '*_L001_R1*' ]
    then
       rm *_L00*
    fi
fi

# Check if we have the expected R1 files to process
if ls *_R1_001.fastq.gz >/dev/null 2>&1; then
    echo "Processing files with Varpipeline..."
    ls *_R1_001.fastq.gz | sed 's/_R1_001.fastq.gz//g' | awk '{print "../tools/Varpipeline -q "$0"_R1_001.fastq.gz -r ../tools/ref2.fa -n "$0" -q2 "$0"_R2_001.fastq.gz -a -v -t '${THREADS}' "}' > run_3.sh

    cat run_3.sh
    sh run_3.sh
    
    # Clean up symbolic links if they were created
    for file in *_1.fastq.gz; do
        if [ -e "$file" ]; then
            base_name=$(basename "$file" _1.fastq.gz)
            if [ -L "${base_name}_R1_001.fastq.gz" ]; then
                rm "${base_name}_R1_001.fastq.gz"
            fi
            if [ -L "${base_name}_R2_001.fastq.gz" ]; then
                rm "${base_name}_R2_001.fastq.gz"
            fi
        fi
    done
    
    rm run_3.sh
else
    echo "No suitable input files found. Expected either:"
    echo "  - Files ending with _1.fastq.gz and _2.fastq.gz (e.g., sample_1.fastq.gz)"
    echo "  - Files ending with _L001_R1_001.fastq.gz and _L001_R2_001.fastq.gz"
fi

if [ -e run_1.sh ]
then
   rm run_1.sh   
fi

if [ -e run_2.sh ]
then
   rm run_2.sh
fi
