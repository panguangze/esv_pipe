import argparse
import pysam
def main():
    parser = argparse.ArgumentParser("parse")
    parser.add_argument('-v', required=True)
    parser.add_argument('-b', required=False)
    parser.add_argument('--dump_file', required=False)
    parser.add_argument('-o', required=True)
    parser.add_argument('--lumpy', action='store_true')
    parser.add_argument('--manta', action='store_true')
    parser.add_argument('--delly', action='store_true')
    args = parser.parse_args()
    evidences = {}
    in_vcf = open(args.v)
    out_vcf = open(args.o,"w")
    support_reads = {}
    if args.lumpy:
        evids = []
        tag = True
        ev_tag = True
        for line in in_vcf.readlines():
            if line.startswith("#"):
                out_vcf.write(line)
                continue
            else:
                # out_vcf.write(line)
                tmp = line.strip().split("\t")
                tmp[8]=":".join(tmp[8].split(":")[0:2])
                tmp[9]=":".join(tmp[9].split(":")[0:2])
                out_vcf.write("\t".join(tmp)+"\n")
main()
