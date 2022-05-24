import argparse
import pysam
import re
from pyfaidx import Fasta
def main():
    parser = argparse.ArgumentParser("parse")
    parser.add_argument('-v', required=True)
    parser.add_argument('-d', required=True)
    parser.add_argument('-r', required=True)
    parser.add_argument('-o', required=True)
    args = parser.parse_args()
    evidences = {}
    in_vcf = open(args.v)
    out_vcf = open(args.o,"w")
    ref = Fasta(args.r)
    evids = []
    reads = {}
    tag = True
    ev_tag = True
    for line in open(args.d).readlines():
        if line.startswith("#"):
            continue
        ts = line.split("\t")
        if ts[0] not in reads.keys():
            reads[ts[0]] = []
        reads[ts[0]].append(ts[2])
    for line in in_vcf.readlines():
        if line.startswith("#"):
            out_vcf.write(line)
            continue
        else:
            tmp = line.split("\t")
            lls = tmp[7].split(";")
            if tmp[2] in reads.keys():
                lls[3] = "READNAMES="+",".join(reads[tmp[2]])
                tmp[7] = ";".join(lls)
            if "BND" not in tmp[2]:
                out_vcf.write("\t".join(tmp))
                continue
            tmp4 = re.split(r"[\]\[\:]",tmp[4])
            tmp[2]=tmp[2]+":1"
            out_vcf.write("\t".join(tmp))
            tmp[2]=tmp[2][0:-1] + "2"
            p = int(tmp4[2])
            refp = str(ref[tmp4[1]][p:p+1])
            if tmp[4][0] == "[" and tmp[4][-2] == "[":
                tmp[4] ="["+tmp[0] +":"+tmp[1]+"["+refp
                tmp[3] = refp
            elif tmp[4][1] == "]" and tmp[4][-1] == "]":
                tmp[4] = refp+"]"+tmp[0] +":"+tmp[1]+"]"
                tmp[3] = refp
            elif tmp[4][0] == "]" and tmp[4][-2] == "]":
                tmp[4] = refp+"["+tmp[0] +":"+tmp[1]+"["
                tmp[3] = refp
            elif tmp[4][1] == "[" and tmp[4][-1] == "[":
                tmp[4] = "]"+tmp[0] +":"+tmp[1]+"]"+refp
                tmp[4] = refp

            tmp[0] = tmp4[1]
            tmp[1] = tmp4[2]
            out_vcf.write("\t".join(tmp))
if __name__ == '__main__':
    main()
