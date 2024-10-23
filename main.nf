#!/usr/bin/env nextflow

nextflow.enable.dsl = 2


include { hash_files            } from './modules/hash_files.nf'
include { noroblast             } from './modules/noroblast.nf'
include { split_blast_outputs   } from './modules/noroblast.nf'
include { pipeline_provenance   } from './modules/provenance.nf'
include { collect_provenance    } from './modules/provenance.nf'


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

    ch_workflow_metadata = Channel.value([
        workflow.sessionId,
        workflow.runName,
        workflow.manifest.name,
        workflow.manifest.version,
        workflow.start,
    ])

    ch_pipeline_provenance = pipeline_provenance(ch_workflow_metadata)

    ch_db = Channel.fromPath(params.db)
    ch_fasta_input = Channel.fromPath(params.fasta_input + '/*.fasta').map{tuple(it.name.split('\\.')[0], it)}

    hash_files(ch_fasta_input.combine(Channel.of("fasta_input")))

    
    noroblast(ch_fasta_input.combine(ch_db))

    ch_blast_collect_top1 = noroblast.out.top1.map{it -> it[1]}.collectFile(name: "${params.outdir}/${params.run_name}_top1_combined_blast.csv", sort: {file -> file.text}, skip: 1, keepHeader: true)
    ch_blast_collect_top10 = noroblast.out.top10.map{it -> it[1]}.collectFile(name: "${params.outdir}/${params.run_name}_top10_combined_blast.csv", sort: {file -> file.text}, skip: 1, keepHeader: true)

    split_blast_outputs(ch_blast_collect_top1, ch_blast_collect_top10 )

    ch_provenance = ch_fasta_input.map{ it -> it[0] }
    ch_provenance = ch_provenance.combine(ch_pipeline_provenance).map{ it ->      [it[0], [it[1]]] }
    ch_provenance = ch_provenance.join(hash_files.out.provenance).map{ it ->      [it[0], it[1] << it[2]] }
    ch_provenance = ch_provenance.join(noroblast.out.provenance).map{ it ->      [it[0], it[1] << it[2]] }
    collect_provenance(ch_provenance)
}