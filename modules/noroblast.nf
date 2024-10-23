process noroblast {

    tag {sample_id}

    publishDir "${params.outdir}/${sample_id}", pattern: "${sample_id}/${sample_id}*", mode: 'copy', saveAs: { filename -> filename.split("/").last() }
    publishDir "${params.outdir}/${sample_id}", pattern: "${sample_id}/logs",          mode: 'copy', saveAs: { filename -> filename.split("/").last() }


    input:
    tuple val(sample_id), path(sequences), path(database)

    output:
    tuple val(sample_id), path("${sample_id}/${sample_id}_blast_results.tsv"), emit: blast_report, optional: true
    tuple val(sample_id), path("${sample_id}/${sample_id}*_top10_*.csv"),      emit: top10,        optional: true
    tuple val(sample_id), path("${sample_id}/${sample_id}*_top1_*.csv"),       emit: top1,         optional: true
    tuple val(sample_id), path("${sample_id}_noroblast_provenance.yml"),       emit: provenance,   optional: true
    tuple val(sample_id), path("${sample_id}/logs"), emit: logs

    """
    printf -- "- process_name: noroblast\\n"                                                  >> ${sample_id}_noroblast_provenance.yml
    printf -- "  tools:\\n"                                                                   >> ${sample_id}_noroblast_provenance.yml
    printf -- "    - tool_name: blast\\n"                                                     >> ${sample_id}_noroblast_provenance.yml
    printf -- "      tool_version: \$(blastn -version | head -n1 | cut -d' ' -f2)\\n"         >> ${sample_id}_noroblast_provenance.yml
    printf -- "  databases:\\n"                                                               >> ${sample_id}_noroblast_provenance.yml
    printf -- "    - database_name: ${database}\\n"                                           >> ${sample_id}_noroblast_provenance.yml
    printf -- "      database_path: \$(readlink -f ${database}) \\n"                          >> ${sample_id}_noroblast_provenance.yml
    printf -- "      database_sha256: \$(shasum -a 256 ${database} | awk '{print \$1}')\\n"   >> ${sample_id}_noroblast_provenance.yml
  

    noroblast.py --input ${sequences} -o ${sample_id} --db ${database}

    """

}

process split_blast_outputs {

    publishDir "${params.outdir}", pattern: "*csv", mode:'copy'


    input:
    path(top1_results)
    path(top10_results)

    output:
    path("${params.run_name}_top1_*csv")                  , emit: top1, optional: true
    path("${params.run_name}_top10_*csv")                 , emit: top10, optional: true

    """
    split_blast.py --input ${top1_results} --outname ${params.run_name}_top1

    split_blast.py --input ${top10_results} --outname ${params.run_name}_top10
    """

}