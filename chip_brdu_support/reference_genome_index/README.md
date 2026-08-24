# Reference genome indexes

This directory is populated in the complete release bundle with the S288C/sacCer3 and exact two-repeat rDNA FASTA/index files required by primary analysis.

Generated Bowtie2 and Rsubread index binaries are excluded from ordinary Git history because several exceed GitHub's file-size limit. A source-only clone is therefore suitable for code review and documentation, but not for primary analysis until the matching indexes are restored from the complete release bundle.

Keep this directory under `chip_brdu_support` and beside `genomic_elements`; the R functions resolve it relative to `ChIPseq_BrDUseq_Project.R`.
