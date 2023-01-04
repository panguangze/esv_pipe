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
    prev_k = ""
    for line in open(args.d).readlines():
        if line.startswith("#"):
            continue
        ts = line.split("\t")
        if ts[0] != prev_k:
        # if ts[0] not in reads.keys():
            reads[ts[0]] = []
        reads[ts[0]].append(ts[2])
        prev_k = ts[0]
    for line in in_vcf.readlines():
        if line.startswith("#"):
            out_vcf.write(line)
            continue
        else:
            tmp = line.strip().split("\t")
            tmp[8] = tmp[8]+":READNAMES"
            lls = tmp[7].split(";")
            if "READNAMES" in tmp[7]:
                del lls[3]
            # if tmp[2] in reads.keys():
            try:
                if "READNAMES" not in lls:
                    tmp[9] = tmp[9].strip() +":"+",".join(reads[tmp[2]]).replace(":","_COLON_")
            except:
                continue
                    # tmp[9] = tmp[9] +":"+",".join(lls)
                # else:
                    # tmp[9] = tmp[9] +":"+",".join(reads[tmp[2]])
            if "BND" not in tmp[2]:
                out_vcf.write("\t".join(tmp) + "\n")
                continue
            tmp4 = re.split(r"[\]\[\:]",tmp[4])
            tmp[2]=tmp[2]+":1"
            out_vcf.write("\t".join(tmp)+ "\n")
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
                tmp[3] = refp

            tmp[0] = tmp4[1]
            tmp[1] = tmp4[2]
            out_vcf.write("\t".join(tmp)+ "\n")
if __name__ == '__main__':
    main()
