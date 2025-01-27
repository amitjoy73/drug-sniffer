#!/usr/bin/env nextflow

// Channels
// --------

// Processes
// ---------

// Stages 1 and 2 require manual intervention and are therefore excluded from the
// workflow definition.

// Stage 3

process denovo {
    container 'traviswheelerlab/03-denovo:latest'

    input:
    path receptor_pdb from params.receptor_pdb

    val center_x from params.receptor_center_x
    val center_y from params.receptor_center_y
    val center_z from params.receptor_center_z

    val size_x from params.box_size_x
    val size_y from params.box_size_y
    val size_z from params.box_size_z

    output:
    path "denovo.smi" into denovo_ligands_smi

    cpus 4

    """
    NUMBER_OF_PROCESSORS=4 \
    RECEPTOR_PATH="${receptor_pdb}" \
    CENTER_X="${center_x}" \
    CENTER_Y="${center_y}" \
    CENTER_Z="${center_z}" \
    SIZE_X="${size_x}" \
    SIZE_Y="${size_y}" \
    SIZE_Z="${size_z}" \
    run.sh
    """
}

// Stage 4

process similarity_search {
    container 'traviswheelerlab/04-similiarity_search:latest'

    input:
    path denovo_ligands_smi from denovo_ligands_smi

    output:
    path "db_ligands.smi" into db_ligands_smi

    cpus 1

    """
    DENOVO_LIGANDS_SMI="${denovo_ligands_smi}" \
    MOLECULE_DB="${params.molecule_db}" \
    TANIMOTO_CUTOFF="${params.tanimoto_cutoff}" \
    run.sh
    """
}

// Stage 5

process protein_ligand_docking {
    container 'traviswheelerlab/05-protein_ligand_docking:latest'

    input:
    path receptor_pdb from params.receptor_pdb
    path db_ligands_smi from db_ligands_smi
    val center_x from params.center_x
    val center_y from params.center_y
    val center_z from params.center_z
    val size_x from params.size_x
    val size_y from params.size_y
    val size_z from params.size_z
    val num_modes from params.autodock_vina_num_modes
    val exhaustiveness from params.autodock_vina_exhaustiveness

    output:
    path "docked_*.pdbqt" into docked_pdbqt

    cpus 4

    """
    RECEPTOR_PDBQT="${params.receptor_pdb}" \
    LIGANDS_SMI="${db_ligands_smi}" \
    CENTER_X="${params.center_x}" \
    CENTER_Y="${params.center_y}" \
    CENTER_Z="${params.center_z}" \
    SIZE_X="${params.size_x}" \
    SIZE_Y="${params.size_y}" \
    SIZE_Z="${params.size_z}" \
    run.sh
    """
}

// Stage 6

process activity_prediction {
    container 'traviswheelerlab/06-activity_prediction'

    input:
    path docked_pdbqt from docked_pdbqt

    output:
    path "ligand.score" into ligand_score

    """
    LIGAND_NAME=dummy \
    PROTEIN_PDB=${params.receptor_pdb} \
    DOCKED_PDBQT=${docked_pdbqt} \
    run.sh
    """
}

// Stage 7

process admet_filtering {
    input:
    path db_ligands_smi from db_ligands_smi

    output:
    path "output.txt" into admet_output

    """
    LIGAND_SMIS=${db_ligands_smi} \
    ADMET_CHECKS=${params.admet_checks} \
    run.sh
    """
}

