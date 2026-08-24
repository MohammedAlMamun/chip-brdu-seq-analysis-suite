# Troubleshooting

## The main script cannot be located

Open `Run_ChIPseq_BrDUseq_Project.R` in RStudio and execute Block 1, or use an explicit absolute path with `source()`. The run script also searches the working directory as a fallback.

## The support folder is incomplete

Keep `chip_brdu_support` beside `ChIPseq_BrDUseq_Project.R`. If the project came from a Git clone rather than the complete release ZIP, the large generated reference indexes will be absent. Download the matching complete release bundle.

## The run script starts an analysis unexpectedly

The examples in the run script are deliberately active and contain placeholder paths. Execute Block 1 and then only the desired edited call. Do not source the entire run script unchanged.

## A ratio or peak file is missing

Check that:

- `SampleDir` points to the completed sample directory rather than its parent;
- `Assay` matches the assay used during primary analysis;
- `Alignment` matches `generic` or `malign`; and
- result files have not been renamed or moved.

## Baselines look incorrect

`ip.score` has neutral baseline 0. Ratio metrics have neutral baseline 1 in raw space and 0 after log2 transformation. Confirm `Metric` and the relevant `Log2Profile`/`Log2Values` option before interpreting the axis.

## Strand-separated values appear below zero

Crick signal is deliberately mirrored below zero for visualization. This does not mean the underlying saved ratios are negative.

## External tools cannot be found

The RC expects the laboratory installation under `/Applications/ngsAnalyser.app`. Confirm that the application is installed in that location. Portability beyond that environment is planned but is not part of this release.

## Reporting a defect

Open a GitHub Issue and include:

- the function call with sensitive paths anonymized;
- assay, alignment and strand mode;
- complete error text;
- R and macOS versions;
- the relevant sample-directory tree or filenames; and
- `Analysis_Manifest.tsv` for complete-analysis failures.

Never attach raw sequencing reads or confidential experimental data.
