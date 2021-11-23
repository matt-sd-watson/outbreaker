import os
import sys
import click

if not config["outdir"]: 
    config["outdir"] = os.getcwd() + "/outbreaker/"
    
def isFasta(input):
    return input.endswith(('.fa', '.fasta', '.FA', '.FASTA'))


rule all:
    input:
        os.path.join(config["outdir"], config["prefix"] + ".fa"),
        os.path.join(config["outdir"], config["prefix"] + "_filtered.fa") if config["filter"] else [],
        os.path.join(config["outdir"], config["prefix"] + "_renamed.fa") if config["rename"] else [],
        os.path.join(config["outdir"], config["prefix"] + "_aln.fasta"),
        os.path.join(config["outdir"], config["prefix"]+ "_tree.nwk"),
        os.path.join(config["outdir"], config["prefix"]+ "_snps_only.fasta") if config["snps_only"] else [],
        os.path.join(config["outdir"], config["prefix"]+ "_snps_only.contree") if config["snps_only"] else [],
        os.path.join(config["outdir"], config["prefix"] + "_snp_dists.csv"),
        os.path.join(config["outdir"], config["prefix"] + "_summary_report.html")
        

def absol_path(input): 
    return os.path.abspath(input)
        
        
rule create_subset:
    input:
        focal = config["focal_seqs"],
        master_fasta = config["master_fasta"] if not isFasta(str(config["background_seqs"])) and config["background_seqs"] or not isFasta(str(config["focal_seqs"])) else [],
        background = config["background_seqs"] if config["background_seqs"] else []
    
    output:
        sub_fasta = os.path.join(config["outdir"], config["prefix"] + ".fa")
     
    run:
        # if neither is a FASTA, create the subset
        if not isFasta(str(config["background_seqs"])) and not isFasta(str(config["focal_seqs"])):
            if config["background_seqs"]:
                shell("""
                mkdir -p {config[outdir]}
            
                fastafurious subset -f {input.master_fasta} -l {input.focal} \
                -o {config[outdir]}/only_focal.fa
            
                fastafurious subset -f {input.master_fasta} -l {input.background} \
                -o {config[outdir]}/only_background.fa
            
                cat {config[outdir]}/only_focal.fa {config[outdir]}/only_background.fa > {config[outdir]}/all.fa
                dup_sams=$(grep ">" {config[outdir]}/all.fa | sed 's/>//' | sort | uniq -d)
                original_lines=$(grep ">" {config[outdir]}/all.fa | wc -l)
                awk '/^>/{{f=!d[$1];d[$1]=1}}f' {config[outdir]}/all.fa > {output.sub_fasta}
                remaining_lines=$(grep ">" {output.sub_fasta} | wc -l)
                rm {config[outdir]}/all.fa
                echo "\n$(($original_lines-$remaining_lines)) duplicate samples were removed:\n"
                echo "\n$dup_sams"
                echo "\nmulti-FASTA created: {output.sub_fasta}\n"
                """)
            else:
                shell("""
                mkdir -p {config[outdir]}
                fastafurious subset -f {input.master_fasta} -l {input.focal} \
                -o {output.sub_fasta}
                echo "\nmulti-FASTA created: {output.sub_fasta}\n"
                """)
        else:
            # if one of them is a FASTA, create the subset for the other and cat
            if config["background_seqs"]:
                # if background is not FASTA but focal is
                if not isFasta(str(config["background_seqs"])) and isFasta(str(config["focal_seqs"])):
                    shell("""
                    mkdir -p {config[outdir]}
                    fastafurious subset -f {input.master_fasta} -l {input.background} \
                    -o {config[outdir]}/only_background.fa
                    cat {input.focal} {config[outdir]}/only_background.fa > {config[outdir]}/all.fa
                    dup_sams=$(grep ">" {config[outdir]}/all.fa | sed 's/>//' | sort | uniq -d)
                    original_lines=$(grep ">" {config[outdir]}/all.fa | wc -l)
                    awk '/^>/{{f=!d[$1];d[$1]=1}}f' {config[outdir]}/all.fa > {output.sub_fasta}
                    remaining_lines=$(grep ">" {output.sub_fasta} | wc -l)
                    rm {config[outdir]}/all.fa
                    echo "\n$(($original_lines-$remaining_lines)) duplicate samples were removed:\n"
                    echo "\n$dup_sams"
                    echo "\nmulti-FASTA created: {output.sub_fasta}\n"
                    """)
                # if background is FASTA but focal is not    
                elif isFasta(str(config["background_seqs"])) and not isFasta(str(config["focal_seqs"])):
                    shell("""
                    mkdir -p {config[outdir]}
                    fastafurious subset -f {input.master_fasta} -l {input.focal} \
                    -o {config[outdir]}/only_focal.fa
                    cat {input.background} {config[outdir]}/only_focal.fa > {config[outdir]}/all.fa
                    dup_sams=$(grep ">" {config[outdir]}/all.fa | sed 's/>//' | sort | uniq -d)
                    original_lines=$(grep ">" {config[outdir]}/all.fa | wc -l)
                    awk '/^>/{{f=!d[$1];d[$1]=1}}f' {config[outdir]}/all.fa > {output.sub_fasta}
                    remaining_lines=$(grep ">" {output.sub_fasta} | wc -l)
                    rm {config[outdir]}/all.fa
                    echo "\n$(($original_lines-$remaining_lines)) duplicate samples were removed:\n"
                    echo "\n$dup_sams"
                    echo "\nmulti-FASTA created: {output.sub_fasta}\n"
                    """)
                    
                 # if both are FASTA, concat and send to output
                else:
                    shell("""
                    cat {input.focal} {input.background} > {config[outdir]}/all.fa
                    dup_sams=$(grep ">" {config[outdir]}/all.fa | sed 's/>//' | sort | uniq -d)
                    original_lines=$(grep ">" {config[outdir]}/all.fa | wc -l)
                    awk '/^>/{{f=!d[$1];d[$1]=1}}f' {config[outdir]}/all.fa > {output.sub_fasta}
                    remaining_lines=$(grep ">" {output.sub_fasta} | wc -l)
                    rm {config[outdir]}/all.fa
                    echo "\n$(($original_lines-$remaining_lines)) duplicate samples were removed:\n"
                    echo "\n$dup_sams"
                    echo "\nmulti-FASTA created: {output.sub_fasta}\n"
                    """)       
            # if only using focal and not FASTA, copy into final output      
            else:
                shell("""
                cp {input.focal} {output.sub_fasta}
                echo "\nmulti-FASTA created: {output.sub_fasta}\n"
                """)
                                          
            
rule filter:
    input: 
        fasta = rules.create_subset.output.sub_fasta
    output: 
        filtered = os.path.join(config["outdir"], config["prefix"] + "_filtered.fa")
    run:
        if config["filter"]: 
            shell("""
            fastafurious filter -i {input.fasta} -l {config[genome_length]} \
            -c {config[genome_completeness]} -o {output.filtered}
            """)
           
rule rename_headers: 
    input: 
        fasta = rules.filter.output.filtered if config["filter"] else rules.create_subset.output.sub_fasta,
        names_csv = config["names_csv"] if config["names_csv"] else []
    output: 
        renamed = os.path.join(config["outdir"], config["prefix"] + "_renamed.fa")
    run: 
        if config["rename"]: 
            if config["names_csv"]: 
                shell("""
                fastafurious rename -i {input.fasta} -s {input.names_csv} \
                -1 original_name -2 new_name -o {output.renamed}
                echo "\nrenamed multi-FASTA headers into: {output.renamed}\n"
                """)
            else:
                fasta_to_open = open(input.fasta)
                newfasta = open(output.renamed, 'w')
                for line in fasta_to_open: 
                    if line.startswith('>'):
                        line_cleaned = line.strip('>').strip()
                        try: 
                            replacement_name = "ON-PHL-" + line_cleaned.split("PHLON")[1].split("-SARS")[0] + "-" + line_cleaned.split("PHLON")[1].split("-SARS")[1]
                        except IndexError:
                            replacement_name = line_cleaned
                        newfasta.write(">" + replacement_name + "\n")
                    else:
                        newfasta.write(line)
                
                fasta_to_open.close()
                newfasta.close()
                sys.stderr.write(f'\nrenamed multi-FASTA headers into: {output.renamed}\n')
                
 
                
if config["rename"]: 
    INPUT_ALIGN = rules.rename_headers.output.renamed
elif not config["rename"] and config["filter"]:
    INPUT_ALIGN = rules.filter.output.filtered
else:
    INPUT_ALIGN = rules.create_subset.output.sub_fasta
        

rule align:
    input: 
        reference = config["reference"],
        fasta = INPUT_ALIGN
    
    output: 
        alignment = os.path.join(config["outdir"], config["prefix"] + "_aln.fasta")
        
    shell: 
        """
        augur align --sequences {input.fasta} \
        --reference-sequence {input.reference} \
        --output {output.alignment} \
        --nthreads {config[nthreads]} \
        --fill-gaps
        echo "\nmulti-FASTA alignment created using mafft: {output.alignment}\n"
        """

rule tree: 
    input:
        alignment = rules.align.output.alignment
    
    output: 
        tree = os.path.join(config["outdir"], config["prefix"]+ "_tree.nwk")
    
    shell: 
        """
        augur tree --alignment {input.alignment} \
        --output {output.tree} \
        --nthreads {config[nthreads]}
        echo "\nNewick tree created using iqtree: {output.tree}\n"
        """

rule snps_only: 
    input: 
        alignment = rules.align.output.alignment
    output: 
        snps_only = os.path.join(config["outdir"], config["prefix"]+ "_snps_only.fasta")
    run: 
        if config["snps_only"]:
            shell("""
            snp-sites -m -c -o {output.snps_only} {input.alignment}
            echo "\nSNPS only multi-FASTA created using snp-sites: {output.snps_only}\n"
            """)


rule snps_only_tree: 
    input: 
        snps_fasta = rules.snps_only.output.snps_only,
        full_fasta = INPUT_ALIGN
    output: 
        snps_only_tree = os.path.join(config["outdir"], config["prefix"] + "_snps_only.contree")
    run: 
        if config["snps_only"]:
            if config["const_sites"]:
                if os.path.isfile(os.path.join(config["outdir"], config["prefix"] + "_snps_only.ckp.gz")):
                    if click.confirm('Previous SNPs only tree detected. Confirm overwriting file?', default=True):
                        shell("""
                        sites=$(snp-sites -C {input.full_fasta})
                        iqtree2 -alrt 1000 -bb 1000 -pre {config[outdir]}/{config[prefix]}_snps_only -s {input.snps_fasta} -fconst $sites -mfreq F -mrate G,R -redo
                        echo "\nNewick tree created using SNPs only multi-FASTA and constant sites with iqtree2: {output.snps_only_tree}\n"
                        """)
                    else:
                        sys.stderr.write(f'ERROR: Please confirm overwriting the existing SNPS only tree.\n')
                        sys.exit(-1)
                else:
                    shell("""
                    sites=$(snp-sites -C {input.full_fasta})
                    iqtree2 -alrt 1000 -bb 1000 -pre {config[outdir]}/{config[prefix]}_snps_only -s {input.snps_fasta} -fconst $sites -mfreq F -mrate G,R
                    echo "\nNewick tree created using SNPs only multi-FASTA and constant sites with iqtree2: {output.snps_only_tree}\n"
                    """)
            else:
                if os.path.isfile(os.path.join(config["outdir"], config["prefix"] + "_snps_only.ckp.gz")):
                    if click.confirm('Previous SNPs only tree detected. Confirm overwriting file?', default=True):
                        shell(
                        """
                        iqtree2 -alrt 1000 -bb 1000 -pre {config[outdir]}/{config[prefix]}_snps_only -s {input.snps_fasta} -redo
                        echo "\nNewick tree created using SNPs only multi-FASTA with iqtree2: {output.snps_only_tree}\n"
                        """)
                    else:
                        sys.stderr.write(f'ERROR: Please confirm overwriting the existing SNPS only tree.\n')
                        sys.exit(-1)
                else:
                    shell(
                    """
                    iqtree2 -alrt 1000 -bb 1000 -pre {config[outdir]}/{config[prefix]}_snps_only -s {input.snps_fasta}
                    echo "\nNewick tree created using SNPs only multi-FASTA with iqtree2: {output.snps_only_tree}\n"
                    """)
                        
rule snp_dists: 
    input: 
        fasta = rules.align.output.alignment
    output: 
        snp_dists = os.path.join(config["outdir"], config["prefix"] + "_snp_dists.csv")
    shell:
        """
        snp-dists -m -c {input.fasta} > {output.snp_dists}
        echo "\nMolten SNP distance matrix created using snp-dists: {output.snp_dists}\n"
        """

rule summary_report: 
    input: 
        snp_read = rules.snp_dists.output.snp_dists
    output:
        report = os.path.join(config["outdir"], config["prefix"] + "_summary_report.html")
    params: 
        script = srcdir("outbreaker_summary_report.Rmd"),
        output = absol_path(os.path.join(config["outdir"], config["prefix"] + "_summary_report.html")),
        focal_read = str(config["focal_seqs"]),
        background_read = str(config["background_seqs"]),
        snp_read = absol_path(os.path.join(config["outdir"], config["prefix"] + "_snp_dists.csv"))
    shell: 
        """
        Rscript -e \"rmarkdown::render(input = '{params.script}', params = list(focal_list = '{params.focal_read}', background_list = '{params.background_read}', snp_dists = '{params.snp_read}'), output_file = '{params.output}')\"
        """
  
        
        


