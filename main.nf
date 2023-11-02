#!/usr/bin/env nextflow

nextflow.enable.dsl = 2


include { seq_qc }           from './modules/noroblast.nf'
include { blastn }           from './modules/noroblast.nf'
include { find_top_results } from './modules/noroblast.nf'

// prints to the screen and to the log
        log.info """

                 Noroblast Pipeline
                 ===================================
                 projectDir    : ${projectDir}
                 launchDir     : ${launchDir}
                 database      : ${params.db}
                 fasta_input   : ${params.fasta_input}
                 outdir        : ${params.outdir}
                 """
                 .stripIndent()

workflow{
    ch_db = Channel.fromPath(params.db)
    ch_fasta = Channel.fromPath(params.fasta_search_path).map{ it -> [it.name.split('\\.')[0], it] }
    ch_seqs = ch_fasta.splitFasta(record: [id: true, seqString: true])

    seq_qc(ch_seqs)
    ch_blast = blastn(ch_seqs.combine(ch_db))
    find_top_results(ch_blast)

    if (params.collect_outputs) {
	seq_qc.out.map{ it -> it[1] }.collectFile(keepHeader: true, sort: { it.text }, name: "${params.collected_outputs_prefix}_seq_qc.csv", storeDir: "${params.outdir}")
	find_top_results.out.top_result_by_region.map{ it -> it[1] }.collectFile(keepHeader: true, sort: { it.text }, name: "${params.collected_outputs_prefix}_top_result_by_region.csv", storeDir: "${params.outdir}")
    }
}
