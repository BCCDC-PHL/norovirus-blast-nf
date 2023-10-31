# norovirus-blast-nf

Nextflow pipeline to run blast for norovirus

## Input

.fasta contig files after assembly and contig correction on Genieous. 

## Usage

Note the `-profile` and `--cache` switches, essential for proper operation of Conda.

Example command:
```
nextflow run BCCDC-PHL/norovirus-blast-nf --db <path/to/ref.fa> --fastq_input <path/to/input/fasta> --outdir <output_folder> -profile conda --cache ~/.conda/envs
```
