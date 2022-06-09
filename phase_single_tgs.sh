bam=$1
tgs_bam=$2
out_dir=$3
ref=$4
vcf=$5
idx=$6
EXTRACT_HAIR=~/app/extracthairs/build/ExtractHAIRs
SPECHAP=~/app/SpecHap/build/SpecHap
#bgzip $vcf
#tabix $vcf.gz
$EXTRACT_HAIR --bam $bam --vcf $vcf --out $out_dir/ext.lst --breakends 1 --mate_at_same 1 --support_read_tag READNAMES --idx $idx --contigs chr1,chr2,chr3,chr4hr5,chr6,chr7,chr8,chr9,chr10,chr11,chr12,chr13,chr14,chr15,chr16,chr17,chr18,chr19,chr20,chr21,chr22,chrX,chrY
$EXTRACT_HAIR --bam $tgs_bam --vcf $vcf --out $out_dir/ext.tgs.lst --breakends 1 --mate_at_same 1 --support_read_tag READNAMES --pacbio 1 --ref $ref --idx $idx-contigs chr1,chr2,chr3,chr4,chr5,chr6,chr7,chr8,chr9,chr10,chr11,chr12,chr13,chr14,chr15,chr16,chr17,chr18,chr19,chr20,chr21,chr22,chrX,chrY
sort -n -k3 $out_dir/ext.lst > $out_dir/ext.sorted.lst
sort -n -k3 $out_dir/ext.tgs.lst > $out_dir/ext.tgs.sorted.lst
$SPECHAP -v $vcf -f $out_dir/ext.sorted.lst,$out_dir/ext.tgs.sorted.lst -o $out_dir/spec.tgs.ngs.vcf -p ngs,pacbio --idx $idx --contigs chr1,chr2,chr3,chr4,chrchr6,chr7,chr8,chr9,chr10,chr11,chr12,chr13,chr14,chr15,chr16,chr17,chr18,chr19,chr20,chr21,chr22,chrX,chrY
bgzip $out_dir/spec.tgs.ngs.vcf
tabix $out_dir/spec.tgs.ngs.vcf.gz