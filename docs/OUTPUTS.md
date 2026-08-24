# Outputs

## Primary analysis

The primary function creates a sample directory named from `ExpTitle`. Relevant outputs include alignment products, binned coverage, ratio tables, noise estimates and peak-class BED files. Folder names distinguish generic and multi-alignment results, including `Ratios`/`Peaks` and `Ratios_ma`/`Peaks_ma` where appropriate.

Do not rename primary ratio or peak files inside a completed sample directory. Downstream functions discover them from the established sample name, assay and alignment conventions.

## Ratio tables

Downstream plotting uses four columns from the saved ratio tables:

- `ip.score`
- `ratio.ipin`
- `ratio.ipnoise`
- `ratio.ipin.noise`

Collapsed, Watson and Crick tables are selected according to `StrandMode`. Plotting does not recalculate these values.

## Peak classes

Primary analysis produces five classes used by the enrichment reports:

- Genome-wide peaks
- Non-origin peaks
- Origin-associated peaks
- Early-origin peaks
- Late-origin peaks

When a peak class is used as an element cohort, windows are centred on the saved `peakSummit` coordinates.

## PDF reports

Most report functions generate multi-page PDFs with four standard metric panels per row. Element reports place up to three element rows on a page. Heatmaps use a single, taller element row per page so panels can be reused in publication figures.

The early/late report includes a fourth page containing Early and Late boxplots together in each of the four metric panels. Boxplot outlier symbols are suppressed so extreme points do not visually compress the boxes.

## Complete-analysis report directory

`ChIP_BrDU_Complete_Analysis()` creates `Complete_Analysis_Reports` by default, with report-specific subdirectories and a concise `Analysis_Manifest.tsv`. Each manifest row records the analysis stage, mode, status, output and an error note when relevant.

The wrapper intentionally excludes:

- whole-genome plotting;
- the standalone assay-specific early/late report; and
- paired ChIP–BrDU comparison functions.

These functions require experiment-specific choices and remain explicit calls in the run script.
