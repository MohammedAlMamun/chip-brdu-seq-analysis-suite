ChIP-seq and BrDU-seq support data: sacCer3 / S288C
===================================================

Purpose
-------
This directory documents the genomic features used by the combined ChIP-seq and
BrDU-seq analysis project. Original inputs are retained separately from the
analysis-ready BED files so that every conversion remains auditable.

Directory layout
----------------
chip_brdu_support/
  reference_genome_index/       Bowtie2 and Rsubread reference/index files
  genomic_elements/
    README_annotations.txt      This documentation
    raw_sources/                Untouched source workbooks and legacy BED files
    processed_bed/              Analysis-ready sacCer3 genomic-feature files

Recommended paths in the future R project
-----------------------------------------
SupportDir <- file.path(ProjectDir, "chip_brdu_support")
ReferenceGenomeIndexDir <- file.path(SupportDir, "reference_genome_index")
GenomicElementsDir <- file.path(SupportDir, "genomic_elements", "processed_bed")

Coordinate and schema conventions
---------------------------------
- Reference assembly: Saccharomyces cerevisiae sacCer3 / S288C.
- Chromosomes 1-16 are named chrI through chrXVI.
- Processed coordinates are BED-style: chromStart is 0-based and chromEnd is
  half-open.
- New feature tables use these BED7 columns:
    chrom, chromStart, chromEnd, name, score, strand, type
- The custom two-repeat rDNA table adds repeat_copy, part, and source_id after
  those BED7 fields. The part field records features split across a reference
  boundary (for example, 1/2 and 2/2).
- sacCer3_ARS.bed adds an eighth column, stat, to preserve the supplied early,
  late, or null classification.
- The four Excel sources used 1-based closed coordinates. Their processed BED
  files therefore use chromStart = Start - 1 and chromEnd = End.
- E_Rep.bed, L_Rep.bed, and OriginList_Full.bed were already BED-style; their
  coordinates were preserved exactly while standard columns were added.
- Raw source files were not edited.

Analysis-ready files
--------------------
Previously prepared annotations:
- sacCer3_S288C_ORFs.bed: 6,692 supplied ORFs in headerless BED6 format.
- sacCer3_TER.bed: 71 termination regions plus a BED7 header.
- sacCer3_TyElements.bed: 433 Ty/LTR features plus a BED7 header.
- sacCer3_tRNAs.bed: 299 tRNA features plus a BED7 header.
- sacCer3_centromeres.bed: 16 centromeres plus a BED7 header.

Newly processed annotations:
- Scer_2xrDNA_unit_Elements.bed: exact architecture of the custom 18,274-bp
  rDNA reference used by the mrdna primary analysis. It contains both 9,137-bp
  repeats; 35S, 25S, 5.8S, 18S, and 5S rRNA features; ETS1/ETS2; ITS1/ITS2;
  NTS1/NTS2; rARS and its ACS; and the canonical RFB interval. Custom copy 2
  is an exact +9,137-bp duplication of custom copy 1, matching RDNAx2.fasta;
  it is not an annotation of the native second repeat represented in SGD.
- sacCer3_CONVERGENT.bed: 1,312 convergent regions from
  CONVERGENT_list.xlsx; strand is not applicable (.).
- sacCer3_DIVERGENT.bed: 1,328 divergent regions from
  DIVERGENT_list.xlsx; strand is not applicable (.).
- sacCer3_CTrans.bed: 1,220 Crick-strand transcribed regions from
  CTrans_list.xlsx; strand is -.
- sacCer3_WTrans.bed: 1,245 Watson-strand transcribed regions from
  WTrans_list.xlsx; strand is +.
- sacCer3_EarlyFiringOrigins.bed: 147 records copied from E_Rep.bed and labeled
  early_firing_origin.
- sacCer3_LateFiringOrigins.bed: 83 records copied from L_Rep.bed and labeled
  late_firing_origin.
- sacCer3_ARS.bed: 409 ARS records copied from OriginList_Full.bed. The stat
  column contains 142 early, 73 late, and 194 null classifications.

Known source inconsistencies (preserved, not silently corrected)
---------------------------------------------------------------
The independent origin files are not exact partitions of OriginList_Full.bed.
Downstream code should choose an explicit authority rather than assuming that
the three files reconcile automatically.

E_Rep.bed contains four unnamed intervals absent from OriginList_Full.bed:
- chrVIII  115683-117257
- chrXII   139293-140447
- chrXV    463698-464877
- chrXVI   552403-554287

L_Rep.bed contains ten unnamed intervals absent from OriginList_Full.bed:
- chrII    810493-813067
- chrIV    1530848-1531802
- chrVII   23-778
- chrVII   1089548-1090902
- chrIX    23-2400
- chrXI    23-2746
- chrXII   23-2077
- chrXII   1077198-1078102
- chrXIV   781453-784287
- chrXV    1089998-1091252

ARS1516 (chrXV:566409-566643) occurs in both E_Rep.bed and L_Rep.bed, while
OriginList_Full.bed labels it late. Each processed file preserves its own source.

rDNA annotation provenance
--------------------------
- Custom reference: reference_genome_index/RDNAx2.fasta, sequence name
  Scer_2xrDNA_unit, length 18,274 bp.
- RDNAx2.fasta consists of two identical 9,137-bp units. Its first unit is an
  exact sequence match to S288C chromosome XII positions 451,418-460,554
  (1-based closed) in reference_genome_index/S288C_genome_new.fa.
- The second 9,137-bp half of RDNAx2.fasta is a literal duplicate of that first
  custom unit. It must therefore be annotated by adding 9,137 bp to the custom
  copy-1 coordinates. Native SGD features RDN37-2, NTS2-2, ARS1200-2, and
  RDN5-2 must not be substituted for custom copy 2. In particular, native
  RDN5-2 is a 119-bp variant rather than the 121-bp RDN5-1 sequence duplicated
  in RDNAx2.fasta, and SGD has no following complete NTS1 feature row there.
- SGD source: Saccharomyces Genome Database weekly GFF3, assembly R64-4-1,
  produced 2026-08-13. Source URL:
  http://sgd-archive.yeastgenome.org/curation/chromosomal_feature/saccharomyces_cerevisiae.gff.gz
- SGD GFF coordinates are 1-based closed. They were projected onto the custom
  reference as BED coordinates with custom_start = SGD_start - 451418 and
  custom_end = SGD_end - 451417, then duplicated by +9,137 bp.
- The mapped SGD features are RDN37-1, ETS2-1, RDN25-1, ITS2-1, RDN58-1,
  ITS1-1, RDN18-1, ETS1-1, NTS2-1, ARS1200-1, its ARS consensus sequence,
  RDN5-1, and NTS1-2. Copy-1 BED rows retain their SGD source identifiers;
  copy-2 rows prefix those identifiers with custom_copy1_duplicate.
- The custom unit boundary lies inside NTS1. Therefore NTS1 is represented by
  two BED intervals per repeat; together the two parts preserve the exact
  continuous 915-bp source feature.
- SGD does not provide an RFB feature row. The RFB rows represent the canonical
  129-bp HindIII-HpaI RFB interval defined by Kobayashi et al. (2001), mapped by
  its restriction sites in RDNAx2.fasta. The interval crosses the custom unit
  boundary and is therefore represented by two BED intervals per repeat.
- The old rDNA.R plotting labels were approximate graphical offsets and were
  not used to construct this annotation.

Naming strategy
---------------
Processed filenames begin with sacCer3_, followed by a stable descriptive
feature name, and end in .bed. Raw filenames remain unchanged for provenance.
The custom rDNA annotation instead begins with its reference sequence name,
Scer_2xrDNA_unit_, because its coordinates are not chromosome-level sacCer3
coordinates.
