#!/usr/bin/env nextflow

nextflow.enable.dsl = 2


include { noroblast             } from './modules/noroblast.nf'
include { split_blast_outputs   } from './modules/noroblast.nf'


// prints to the screen and to the log
        log.info """

                 Noroblast Pipeline
                 ===================================
                 projectDir    : ${projectDir}
                 launchDir     : ${launchDir}
                 database      : ${params.db}
                 fastaInputDir : ${params.fasta_input}
                 run_name      : ${params.run_name}
                 outdir        : ${params.outdir}
                 """
                 .stripIndent()

workflow{
    ch_db = Channel.fromPath(params.db)
    ch_fasta_input = Channel.fromPath(params.fasta_input + '/*.fasta').map{tuple(it.name.split('\\.')[0], it)}
    
    noroblast(ch_fasta_input.combine(ch_db))

    ch_blast_collect_top1 = noroblast.out.top1.map{it -> it[1]}.collectFile(name: "${params.outdir}/${params.run_name}_top1_combined_blast.csv", skip: 1, keepHeader: true)
    ch_blast_collect_top10 = noroblast.out.top10.map{it -> it[1]}.collectFile(name: "${params.outdir}/${params.run_name}_top10_combined_blast.csv", skip: 1, keepHeader: true)

    split_blast_outputs(ch_blast_collect_top1, ch_blast_collect_top10 )

}