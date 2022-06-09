import sys

# arg 1: survivor_sorted.vcf (sorted SUVIVOR output file)
# arg 2: "${prefix}"
# arg 3: survivor_inputs (all files generated by SURVIVOR)
# arg 4: /all.phred.txt (phred thresholds of calls by various callers)

def main():
    headers = []

    written_additional_header = False

    sample = sys.argv[2]
    # get all SV callers used to generate this file
    with open(sys.argv[3]) as survivor_input_list:
        for line in survivor_input_list:
            if "svaba" in line:
                headers.append("svaba")
            elif "breakdancer" in line:
                headers.append("BREAKDANCER")
            elif "breakseq" in line:
                headers.append("BREAKSEQ")
            elif "manta" in line:
                headers.append("MANTA")
            elif "lumpy" in line:
                headers.append("LUMPY")
            elif "delly" in line:
                headers.append("DELLY")
            else:
                headers.append(line.strip())
            
    quality_mappings = { "lt300": {}, "300to1000": {}, "1kbplus": {}, "all": {}, "ins": {} }

    # parse all phred file
    with open(sys.argv[4]) as all_phred_values:
        for line in all_phred_values:
            size_split = line.split("_")
            size_class = size_split[0]
            entry_split = size_split[1].strip().split("=")
            caller_technologies = entry_split[0].split("&")
            caller_technologies.sort()
            if int(entry_split[1]) == 0: 
                quality_mappings[size_class][",".join(caller_technologies)] = 0
            else:
                quality_mappings[size_class]["-".join(caller_technologies)] = int(entry_split[1])

    with open(sys.argv[1]) as survivor_output:
        for line in survivor_output:
            # modify header
            if line.startswith("##"):
                if "FORMAT" in line and not written_additional_header:
                    print "##INFO=<ID=SUPP,Number=.,Type=String,Description=\"Number of callers that support an ALT call. This count is based on the presence of a call, whether it could be confirmed by SVTyper. Due to differences in the breakpoints, this number may differ from the sum of all callers in the CALLERS field\">"
                    print "##INFO=<ID=CALLERS,Number=.,Type=String,Description=\"Callers that support an ALT call at this position. To be included, the caller must have been confirmed by separate genotyping with SVTyper\">"
                    print "##FILTER=<ID=LowQual,Description=\"Variant calls with this profile of supporting calls typically have a low overall precision\">"
                    print "##FILTER=<ID=Unknown,Description=\"Insufficient quality evidence exists for calls of this type and support\">"
                    print "##FILTER=<ID=Unconfirmed,Description=\"It was not possible to confirm this event by genotyping\">"
                    print "##FILTER=<ID=Reference,Description=\"When genotyped, this event was called as homozygous reference\">"
                    sys.stdout.write(line)
                    written_additional_header = True
                else:
                    sys.stdout.write(line)
            # add sample to line describing VCF fields
            elif line[0] == "#" and line[1] != "#":
                tab_split = line.strip().split("\t")
                print "\t".join(tab_split[:9]) + "\t%s" % sample
            # VCF entries
            else:
                tab_split = line.strip().split("\t")
                position = int(tab_split[1])
                end = tab_split[7].replace("CIEND","XXXXX").split("END=")[-1].split(";")[0].split("\t")[0]
                end_position = int(end)
                if ']' in tab_split[4] or '[' in tab_split[4]:
                    continue
                else:
                    svlen = end_position - position
                    tab_split[7]=tab_split[7].replace("SVLEN=.","SVLEN="+str(svlen))
                # possibly same as correct_max_position?
                #if end_position < position:
                #    new_end = str(position)
                #    new_start = end
                #    tab_split[1] = new_start
                #    tab_split[7].replace("END=%s" % end, "END=%s" % new_end)

                # adds "chr"
                if "chr" not in tab_split[0]:
                    tab_split[0] = "chr" + tab_split[0]
                support = ""
                het = 0
                hom = 0
                ref = 0
                # counts support for het/hom/ref
                for i in range(len(tab_split[9:])):
                    if "0/1" in tab_split[9+i] or "1/1" in tab_split[9+i] or "./1" in tab_split[9+i]:
                        if "0/1" in tab_split[9+i] or "./1" in tab_split[9+i]:
                            het += 1
                        if "1/1" in tab_split[9+i] or "./1" in tab_split[9+i]:
                            hom += 1
                        if "0/0" in tab_split[9+i] or "./." in tab_split[9+i]:
                            ref += 1
                        # adds SV caller to "support" string if not there already
                        if headers[i] not in support:
                            support += ",%s" % headers[i]
                # if caller(s) supports variant, adds this to string at end
                if len(support) > 0:
                    tab_split[7] += ";CALLERS=%s" % support.lstrip(",")
                else:
                    support = "."
                # parses hom/het/ref into short genotype strings
                tab_split[8] = "GT"
                if het == 0 and hom == 0:
                    if ref > 0:
                        tab_split[9] = "0/0"
                        tab_split[5] = "0"
                        tab_split[6] = "Reference"
                    else:
                        tab_split[9] = "0/0"
                        tab_split[5] = "0"
                        tab_split[6] = "Unconfirmed"
                elif hom > het:
                    tab_split[9] = "1/1"
                else:
                    tab_split[9] = "0/1"

                #tab_split[9] += support.lstrip(",")

                # adding size range for SVs
                # deletions:
                if "SVTYPE=DEL" in line:
                    #try:
                    size = end_position - position
                    if size < 300:
                        size_range = "lt300"
                    elif size < 1000:
                        size_range = "300to1000"
                    else:
                        size_range = "1kbplus"
                    #except:
                    #    size_range = "all"
                # insertions:
                if "SVTYPE=INS" in line:
                    size_range="ins"

                # adds quality mappings if deletion
                if "SVTYPE=DEL" in line:
                    callers = support.lstrip(",").split(",")
                    callers.sort()
                    while len(callers) > 0:
                        if quality_mappings[size_range].get(",".join(callers)) != None:
                            if int(quality_mappings[size_range].get(",".join(callers))) <= 3:
                                tab_split[6] = "LowQual"
                            tab_split[5] = str(quality_mappings[size_range].get(",".join(callers)))
                            break
                        else:
                            callers.pop(0)
                if "SVTYPE=DUP" in line and (tab_split[9] == "0/1" or tab_split[9] == "1/1"):
                    tab_split[6] = "Unknown"

                # prints final line
                print "\t".join(tab_split[:10])

main()
