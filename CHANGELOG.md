# Changelog

All notable changes to this project will be documented here.

## [1.0.0-rc1] - 2026-08-24

### Added

- Unified ChIP-seq and BrDU-seq primary-analysis entry point.
- Complete-analysis wrapper and concise stage manifest.
- Whole-genome, regional and rDNA profile plotters.
- Peak and genomic-element average enrichment reports.
- Early/Late origin profiles and comparative boxplot page.
- Genomic-element boxplot and viridis heatmap reports.
- Paired ChIP–BrDU regional and element-enrichment comparisons.
- Strand-collapsed and strand-separated displays where scientifically appropriate.
- Curated S288C genomic elements and exact custom two-repeat rDNA annotation.
- Five calculated peak classes usable as element cohorts.
- Transferable script-relative support-path resolution.
- Five-block laboratory run script.

### Release-candidate limitations

- Primary executable paths target the laboratory macOS `ngsAnalyser.app` installation.
- Reference and element support are specific to S288C/sacCer3.
- Automated end-to-end tests with distributable FASTQs are not yet included.
