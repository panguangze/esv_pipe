out_dir=$1
sample=$2
bcftools view $out_dir/trio.sv.sort.vcf.gz -i "(FORMAT/GT[0]='0/1' || FORMAT/GT[0]='1/1') && (FORMAT/GT[1]='./.' || FORMAT/GT[1]='0/0') && (FORMAT/GT[2]='./.' || FORMAT/GT[2]='0/0')" -Oz -o $out_dir/trio.denovo.vcf.gz
bcftools view $out_dir/trio.denovo.vcf.gz --samples $sample -o $out_dir/trio.child.denovo.vcf
