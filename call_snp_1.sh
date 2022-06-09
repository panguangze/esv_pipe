#!/bin/bash
#need google/deepvariant:deeptrio-1.4.0 and glnexus(conda),
#input dir is supported in such format:
  #INPUT_DIR/HG002.bam
  #INPUT_DIR/HG003.bam
  #INPUT_DIR/HG004.bam
  #INPUT_DIR/hg38.fa
  #bam need sorted and index
#modify tools to your path
BIN_VERSION=1.4.0 # set your version
cname=$1
fname=$2
mname=$3
INPUT_DIR=$4
OUTPUT_DIR=$5
REF=$6
nproc=$7
mkdir -p "${OUTPUT_DIR}"
sudo docker run \
  -v "${INPUT_DIR}":"/input" \
  -v "${OUTPUT_DIR}":"/output" \
  google/deepvariant:deeptrio-"${BIN_VERSION}" \
  /opt/deepvariant/bin/deeptrio/run_deeptrio \
  --model_type=WGS \
  --ref=/input/$REF \
  --reads_child=/input/${cname}.bam \
  --reads_parent1=/input/${fname}.bam \
  --reads_parent2=/input/${mname}.bam \
  --output_vcf_child /output/${cname}.output.vcf.gz \
  --output_vcf_parent1 /output/${fname}.output.vcf.gz \
  --output_vcf_parent2 /output/${mname}.output.vcf.gz \
  --sample_name_child ${cname} \
  --sample_name_parent1 ${fname} \
  --sample_name_parent2 ${mname} \
  --num_shards $nproc  \
  --intermediate_results_dir /output/intermediate_results_dir \
  --output_gvcf_child /output/${cname}.g.vcf.gz \
  --output_gvcf_parent1 /output/${fname}.g.vcf.gz \
  --output_gvcf_parent2 /output/${mname}.g.vcf.gz


glnexus_cli --config DeepVariantWGS --threads $nproc $OUTPUT_DIR/${cname}.g.vcf.gz $OUTPUT_DIR/${fname}.g.vcf.gz $OUTPUT_DIR/${mname}.g.vcf.gz > $OUTPUT_DIR/${cname}.trio.bcf
~/app/bcftools/bin/bcftools view $OUTPUT_DIR/${cname}.trio.bcf -Oz -o $OUTPUT_DIR/${cname}.trio.vcf.gz --threads  $nproc
tabix $OUTPUT_DIR/${cname}.trio.vcf.gz