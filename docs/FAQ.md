# Frequently asked questions

## Should `ExpTitle` include `ChIP` or `BrDU`?

No. Use the biological sample name, such as `ExpTitle="SampleName"`, and specify the assay separately. The pipeline adds the assay marker where relevant.

## Does every ChIP sample require a sister BrDU sample?

No. ChIP and BrDU can be processed and plotted independently. Both sample directories are required only for the two explicit comparison functions.

## Do plotters repeat noise filtering or peak calling?

No. They read the ratio tables and peak files produced by primary analysis. Average-profile spline smoothing changes only the plotted curve.

## When should I use strand-separated mode?

Use it to inspect Watson and Crick signals separately. Watson is positive and Crick is mirrored negative. Collapsed peak highlighting is not applied because peak calls come from collapsed data.

## Can calculated peaks be analysed like genomic elements?

Yes. Use one of the five selectors ending in `Peaks`. The selected peak summits become the common element centres for profiles, boxplots, heatmaps or paired enrichment comparison.

## Can I manually set the y-axis?

Yes. Use `y_val` in single-assay plotters that expose it. Paired comparison functions provide `y_val_chip` and `y_val_brdu` for their independent axes. Leave these arguments as `NULL` for automatic scaling.

## Why is the reference-index directory absent from a Git clone?

Several generated index files exceed GitHub's ordinary Git limit. Use the complete release ZIP for a runnable installation.

## Should I install the suite from GitHub Packages?

No. GitHub Packages does not provide an R package registry, and this suite is delivered as a transferable folder with R scripts, annotations and generated indexes. Download the versioned complete ZIP from GitHub Releases instead.

## Is the pipeline suitable for another organism?

Not without adaptation. The current indexes, chromosome conventions and curated element files are specific to S288C/sacCer3.

## Is a graphical application available?

Not yet. A future application is planned around Complete, ChIP, BrDU and Comparative analysis modes. The current release uses the five-block R run script.
