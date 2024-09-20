#!/usr/bin/env nextflow

nextflow.enable.dsl = 2


include { noroblast } from './modules/noroblast.nf'

// prints to the screen and to the log
        log.info """

                 Noroblast Pipeline
                 ===================================
                 projectDir    : ${projectDir}
                 launchDir     : ${launchDir}
                 database      : ${params.db}
                 fastqInputDir : ${params.fasta_input}
                 outdir        : ${params.outdir}
                 """
                 .stripIndent()

workflow{
    ch_db = Channel.fromPath(params.db)
    ch_fasta_input = Channel.fromPath(params.fasta_input + '/*.fasta').map{tuple(it.name.split('\\.')[0], it)}
    
    noroblast(ch_fasta_input.combine(ch_db))

    noroblast.out.top10.map{it -> it[1]}.collectFile(name: "${params.outdir}/collect_blast_result_top10.csv", skip: 1, keepHeader: true)
    noroblast.out.top1.map{it -> it[1]}.collectFile(name: "${params.outdir}/collect_blast_result_top1.csv", skip: 1, keepHeader: true)

}