## Project-local support paths
##
## Expected transferable layout:
##   project_folder/
##     ChIPseq_BrDUseq_Project.R
##     chip_brdu_support/
##       reference_genome_index/
##       genomic_elements/
##
## Paths are anchored to this main script, not to getwd(), the user's home
## directory, or the location of the run script that sources this file.

.ChIPBrDU_Main_Script <- local({
  frame_files <- vapply(
    sys.frames(),
    function(frame){
      source_file <- frame$ofile
      if(is.null(source_file) || length(source_file) == 0){
        NA_character_
      } else {
        as.character(source_file[[1]])
      }
    },
    character(1)
  )
  frame_files <- frame_files[!is.na(frame_files) & nzchar(frame_files)]

  if(length(frame_files) > 0){
    source_file <- frame_files[[length(frame_files)]]
  } else {
    file_argument <- grep("^--file=", commandArgs(trailingOnly=FALSE), value=TRUE)
    source_file <- if(length(file_argument) > 0){
      sub("^--file=", "", file_argument[[1]])
    } else {
      NA_character_
    }
  }

  if(is.na(source_file) || !nzchar(source_file)){
    stop(
      "Could not determine the path of ChIPseq_BrDUseq_Project.R. ",
      "Load it with source('/full/path/ChIPseq_BrDUseq_Project.R').",
      call.=FALSE
    )
  }

  normalizePath(source_file, winslash="/", mustWork=TRUE)
})

ChIP_BrDU_Project_Paths <- function(check=TRUE){
  ProjectDir <- dirname(.ChIPBrDU_Main_Script)
  SupportDir <- file.path(ProjectDir, "chip_brdu_support")
  ReferenceGenomeIndexDir <- file.path(SupportDir, "reference_genome_index")
  GenomicElementsDir <- file.path(SupportDir, "genomic_elements")
  RawSourcesDir <- file.path(GenomicElementsDir, "raw_sources")
  ProcessedBedDir <- file.path(GenomicElementsDir, "processed_bed")

  Indexes <- list(
    bowtie2_s288c=file.path(ReferenceGenomeIndexDir, "S288C_Ref"),
    rsubread_s288c=file.path(ReferenceGenomeIndexDir, "subread_ref"),
    rsubread_rdna=file.path(ReferenceGenomeIndexDir, "rDNA_2nts1"),
    s288c_fasta=file.path(ReferenceGenomeIndexDir, "S288C_genome_new.fa"),
    rdna_fasta=file.path(ReferenceGenomeIndexDir, "RDNAx2.fasta")
  )

  Elements <- list(
    orfs=file.path(ProcessedBedDir, "sacCer3_S288C_ORFs.bed"),
    rdna_elements=file.path(ProcessedBedDir, "Scer_2xrDNA_unit_Elements.bed"),
    ars=file.path(ProcessedBedDir, "sacCer3_ARS.bed"),
    early_origins=file.path(ProcessedBedDir, "sacCer3_EarlyFiringOrigins.bed"),
    late_origins=file.path(ProcessedBedDir, "sacCer3_LateFiringOrigins.bed"),
    termination_regions=file.path(ProcessedBedDir, "sacCer3_TER.bed"),
    ty_elements=file.path(ProcessedBedDir, "sacCer3_TyElements.bed"),
    trnas=file.path(ProcessedBedDir, "sacCer3_tRNAs.bed"),
    centromeres=file.path(ProcessedBedDir, "sacCer3_centromeres.bed"),
    convergent_regions=file.path(ProcessedBedDir, "sacCer3_CONVERGENT.bed"),
    divergent_regions=file.path(ProcessedBedDir, "sacCer3_DIVERGENT.bed"),
    crick_transcribed_regions=file.path(ProcessedBedDir, "sacCer3_CTrans.bed"),
    watson_transcribed_regions=file.path(ProcessedBedDir, "sacCer3_WTrans.bed")
  )

  ## Legacy origin files remain the compatibility inputs for existing bedtools
  ## peak-intersection code because E_Rep.bed and L_Rep.bed are headerless BED6.
  SourceFiles <- list(
    all_origins=file.path(RawSourcesDir, "OriginList_Full.bed"),
    early_origins=file.path(RawSourcesDir, "E_Rep.bed"),
    late_origins=file.path(RawSourcesDir, "L_Rep.bed"),
    convergent_regions=file.path(RawSourcesDir, "CONVERGENT_list.xlsx"),
    divergent_regions=file.path(RawSourcesDir, "DIVERGENT_list.xlsx"),
    crick_transcribed_regions=file.path(RawSourcesDir, "CTrans_list.xlsx"),
    watson_transcribed_regions=file.path(RawSourcesDir, "WTrans_list.xlsx")
  )

  Paths <- list(
    main_script=.ChIPBrDU_Main_Script,
    project_dir=ProjectDir,
    support_dir=SupportDir,
    reference_genome_index_dir=ReferenceGenomeIndexDir,
    genomic_elements_dir=GenomicElementsDir,
    raw_sources_dir=RawSourcesDir,
    processed_bed_dir=ProcessedBedDir,
    indexes=Indexes,
    elements=Elements,
    source_files=SourceFiles
  )

  if(isTRUE(check)){
    RequiredDirectories <- c(
      SupportDir,
      ReferenceGenomeIndexDir,
      GenomicElementsDir,
      RawSourcesDir,
      ProcessedBedDir
    )
    MissingDirectories <- RequiredDirectories[!dir.exists(RequiredDirectories)]

    IndexFiles <- c(
      paste0(Indexes$bowtie2_s288c, c(".1.bt2", ".2.bt2", ".3.bt2", ".4.bt2",
                                     ".rev.1.bt2", ".rev.2.bt2")),
      paste0(Indexes$rsubread_s288c, ".00.b.array"),
      paste0(Indexes$rsubread_s288c, ".00.b.tab"),
      paste0(Indexes$rsubread_rdna, ".00.b.array"),
      paste0(Indexes$rsubread_rdna, ".00.b.tab"),
      Indexes$s288c_fasta,
      Indexes$rdna_fasta
    )
    RequiredFiles <- c(IndexFiles, unlist(Elements, use.names=FALSE),
                       unlist(SourceFiles, use.names=FALSE))
    MissingFiles <- RequiredFiles[!file.exists(RequiredFiles)]

    if(length(MissingDirectories) > 0 || length(MissingFiles) > 0){
      ProblemLines <- c(
        if(length(MissingDirectories) > 0){
          paste0("Missing directory: ", MissingDirectories)
        },
        if(length(MissingFiles) > 0){
          paste0("Missing support file: ", MissingFiles)
        }
      )
      stop(
        "The chip_brdu_support folder is incomplete or is not beside the main script:\n",
        paste(ProblemLines, collapse="\n"),
        call.=FALSE
      )
    }
  }

  Paths
}


## Whole-genome plotting function. This is one self-contained public block;
## a separate run script can source this main script and call it directly.
## Plot the primary-analysis ratio output as the legacy 50-kb whole-genome map.
## Assay selects one independent ChIP or BrDU result; no sister assay is required.
## StrandMode="collapsed" reads the collapsed table, while "separated" reads
## Watson and Crick tables and mirrors Crick below zero in the same profile panel.
## Peak-based colouring and peak annotations are used only for collapsed plots;
## separated plots ignore PeakFile and use WatsonColor and CrickColor directly.
## Log2Profile applies only to collapsed plots. Separated plots always use the
## untransformed non-negative ratios so Watson stays above zero and Crick below.
## y_val=NULL keeps automatic y-axis calculation. A positive y_val sets the
## collapsed upper limit or symmetric -y_val/+y_val separated-strand limits.
## This function does not estimate noise, filter signal, calculate ratios, call
## peaks, or apply p-value thresholds. Those operations belong to the primary
## analysis. Spline smoothing is applied only to the plotted profile as a
## graphical arrangement; it does not alter the ratio tables. Other documented
## display transforms are log2 for collapsed profiles and mirroring Crick below
## zero for separated profiles.
##
## Example:
## ChIP_BrDU_WholeGenome_Plotter(
##   SampleDir="/path/to/sample-ChIP",
##   Assay="ChIP",
##   StrandMode="collapsed"
## )
ChIP_BrDU_WholeGenome_Plotter <- function(
    SampleDir,
    Assay=c("ChIP", "BrDU"),
    Alignment=c("generic", "malign"),
    StrandMode=c("collapsed", "separated"),
    Metric=c("ratio.ipin.noise", "ratio.ipin", "ratio.ipnoise", "ip.score"),
    Chromosomes="all",
    WindowSizeKb=50,
    PlotStyle=c("hist", "lines"),
    y_val=NULL,
    OutputDir=NULL){

  ## Fixed plotting contract. These are implementation details rather than
  ## user-facing choices, which keeps the public function concise and stable.
  SampleName <- NULL
  RatioDir <- NULL
  RatioFile <- NULL
  PeakFile <- NULL
  PanelsPerPage <- 3
  Log2Profile <- TRUE
  Step <- NULL
  Log2YMin <- -1
  YAxisScale <- 8
  SmoothSignal <- TRUE
  SmoothingSpar <- NULL
  ShowBaseline <- TRUE
  PlotPeaks <- TRUE
  ShowARSLabels <- TRUE
  ARSLabelCex <- 0.75
  ARSLabelMinGap <- 350
  ARSLabelLevels <- 5
  ShowFeatureLegend <- TRUE
  FeatureTracks <- c("ORF", "Ty", "TER", "tRNA")
  CollapsedSignalColor <- "gray25"
  PositiveSignalColor <- "red"
  NegativeSignalColor <- "gray70"
  WatsonColor <- "brown3"
  CrickColor <- "cornflowerblue"
  PeakColor <- "firebrick2"
  ProfileLineLwd <- 1.15
  ProfileBarLwd <- 0.35
  ORFLwd <- 2.5
  PdfWidth <- 11
  PdfHeight <- 11
  ProfileMar <- c(0.55, 4.3, 1.75, 1.0)
  AnnotationMar <- c(1.6, 4.3, 0.35, 1.0)
  OuterMar <- c(3.2, 2.8, 2.8, 1.4)
  PanelGapHeight <- 0.45

  Assay <- match.arg(Assay)
  Alignment <- match.arg(Alignment)
  StrandMode <- match.arg(StrandMode)
  Metric <- match.arg(Metric)
  PlotStyle <- match.arg(PlotStyle)
  if(PlotStyle == "hist") PlotStyle <- "bars"

  ValidateLogical <- function(x, name){
    if(!is.logical(x) || length(x) != 1 || is.na(x)){
      stop(name, " must be TRUE or FALSE.")
    }
  }
  ValidatePositive <- function(x, name){
    if(!is.numeric(x) || length(x) != 1 || !is.finite(x) || x <= 0){
      stop(name, " must be one positive number.")
    }
  }
  ValidateNonnegative <- function(x, name){
    if(!is.numeric(x) || length(x) != 1 || !is.finite(x) || x < 0){
      stop(name, " must be zero or a positive number.")
    }
  }
  ValidateMargin <- function(x, name){
    if(!is.numeric(x) || length(x) != 4 || any(!is.finite(x)) || any(x < 0)){
      stop(name, " must contain four non-negative numbers.")
    }
  }

  ValidateLogical(Log2Profile, "Log2Profile")
  ValidateLogical(SmoothSignal, "SmoothSignal")
  ValidateLogical(ShowBaseline, "ShowBaseline")
  ValidateLogical(PlotPeaks, "PlotPeaks")
  ValidateLogical(ShowARSLabels, "ShowARSLabels")
  ValidateLogical(ShowFeatureLegend, "ShowFeatureLegend")
  DisplayPeaks <- PlotPeaks && StrandMode == "collapsed"
  DisplayLog2 <- Log2Profile && StrandMode == "collapsed"
  if(StrandMode == "separated" && Log2Profile){
    message("Strand-separated profiles use untransformed ratios; Log2Profile is ignored.")
  }
  ValidatePositive(WindowSizeKb, "WindowSizeKb")
  ValidatePositive(PanelsPerPage, "PanelsPerPage")
  ValidatePositive(YAxisScale, "YAxisScale")
  ValidatePositive(PdfWidth, "PdfWidth")
  ValidatePositive(PdfHeight, "PdfHeight")
  ValidatePositive(ProfileLineLwd, "ProfileLineLwd")
  ValidatePositive(ProfileBarLwd, "ProfileBarLwd")
  ValidatePositive(ORFLwd, "ORFLwd")
  ValidatePositive(ARSLabelCex, "ARSLabelCex")
  ValidatePositive(ARSLabelMinGap, "ARSLabelMinGap")
  ValidatePositive(ARSLabelLevels, "ARSLabelLevels")
  ValidateNonnegative(PanelGapHeight, "PanelGapHeight")
  ValidateMargin(ProfileMar, "ProfileMar")
  ValidateMargin(AnnotationMar, "AnnotationMar")
  ValidateMargin(OuterMar, "OuterMar")
  if(!is.numeric(Log2YMin) || length(Log2YMin) != 1 || !is.finite(Log2YMin)){
    stop("Log2YMin must be one finite number.")
  }
  if(!is.null(y_val)) ValidatePositive(y_val, "y_val")
  if(!is.null(Step)) ValidatePositive(Step, "Step")

  PanelsPerPage <- as.integer(PanelsPerPage)
  ARSLabelLevels <- as.integer(ARSLabelLevels)
  FeatureTracks <- intersect(FeatureTracks, c("ORF", "Ty", "TER", "tRNA"))

  if(!requireNamespace("data.table", quietly=TRUE)){
    stop("The data.table package is required to read whole-genome ratio tables efficiently.")
  }

  SampleDir <- normalizePath(path.expand(SampleDir), winslash="/", mustWork=TRUE)
  if(is.null(SampleName) || !nzchar(as.character(SampleName)[1])){
    SampleName <- basename(SampleDir)
  } else {
    SampleName <- as.character(SampleName)[1]
  }

  RatioFolder <- if(Alignment == "generic") "Ratios" else "Ratios_ma"
  PeakFolder <- if(Alignment == "generic") "Peaks" else "Peaks_ma"
  if(is.null(RatioDir)) RatioDir <- file.path(SampleDir, RatioFolder)
  RatioDir <- normalizePath(path.expand(RatioDir), winslash="/", mustWork=TRUE)

  if(is.null(OutputDir)) OutputDir <- SampleDir
  OutputDir <- path.expand(OutputDir)
  dir.create(OutputDir, recursive=TRUE, showWarnings=FALSE)
  OutputDir <- normalizePath(OutputDir, winslash="/", mustWork=TRUE)

  ExpectedRatioFiles <- if(StrandMode == "collapsed"){
    c(collapsed=file.path(
      RatioDir, paste0(SampleName, "_", Assay, "_collapsed.bed")
    ))
  } else {
    c(
      watson=file.path(RatioDir, paste0(SampleName, "_", Assay, "_watson.bed")),
      crick=file.path(RatioDir, paste0(SampleName, "_", Assay, "_crick.bed"))
    )
  }

  if(!is.null(RatioFile)){
    RatioFile <- path.expand(as.character(RatioFile))
    if(StrandMode == "collapsed"){
      if(length(RatioFile) != 1){
        stop("Collapsed plotting requires exactly one RatioFile.")
      }
      ExpectedRatioFiles <- c(collapsed=RatioFile[[1]])
    } else {
      if(length(RatioFile) != 2){
        stop("Separated plotting requires Watson and Crick RatioFile paths.")
      }
      if(is.null(names(RatioFile)) ||
         !all(c("watson", "crick") %in% tolower(names(RatioFile)))){
        names(RatioFile) <- c("watson", "crick")
      } else {
        RatioFile <- RatioFile[match(c("watson", "crick"), tolower(names(RatioFile)))]
        names(RatioFile) <- c("watson", "crick")
      }
      ExpectedRatioFiles <- RatioFile
    }
  }

  MissingRatioFiles <- ExpectedRatioFiles[!file.exists(ExpectedRatioFiles)]
  if(length(MissingRatioFiles) > 0){
    stop(
      "Required ", Assay, " ratio table(s) are missing for ", StrandMode, " mode:\n",
      paste(MissingRatioFiles, collapse="\n")
    )
  }

  ReadRatio <- function(file){
    header <- names(data.table::fread(file, nrows=0, data.table=FALSE,
                                     showProgress=FALSE))
    required <- c("chrom", "chromStart", "chromEnd", Metric)
    missing <- setdiff(required, header)
    if(length(missing) > 0){
      stop("Ratio table is missing required column(s) ",
           paste(missing, collapse=", "), ": ", file)
    }
    ratio <- data.table::fread(
      file,
      select=required,
      data.table=FALSE,
      showProgress=FALSE
    )
    names(ratio)[names(ratio) == Metric] <- "metric_value"
    ratio$chrom <- as.character(ratio$chrom)
    ratio$chromStart <- as.numeric(ratio$chromStart)
    ratio$chromEnd <- as.numeric(ratio$chromEnd)
    ratio$metric_value <- as.numeric(ratio$metric_value)
    ratio <- ratio[
      is.finite(ratio$chromStart) & is.finite(ratio$chromEnd) &
        ratio$chromEnd > ratio$chromStart,
      , drop=FALSE
    ]
    ratio
  }

  TransformSignal <- function(values){
    values <- suppressWarnings(as.numeric(values))
    if(DisplayLog2){
      values[!is.finite(values) | values <= 0] <- 1
      values <- log2(values)
    } else {
      values[!is.finite(values)] <- 0
    }
    values
  }

  message("Reading ", Assay, " ratio table(s) for ", StrandMode, " plotting...")
  if(StrandMode == "collapsed"){
    ProfileTable <- ReadRatio(ExpectedRatioFiles[["collapsed"]])
    ProfileTable$plot_signal <- TransformSignal(ProfileTable$metric_value)
  } else {
    Watson <- ReadRatio(ExpectedRatioFiles[["watson"]])
    Crick <- ReadRatio(ExpectedRatioFiles[["crick"]])
    CoordinatesMatch <- nrow(Watson) == nrow(Crick) &&
      identical(Watson$chrom, Crick$chrom) &&
      identical(Watson$chromStart, Crick$chromStart) &&
      identical(Watson$chromEnd, Crick$chromEnd)
    if(!CoordinatesMatch){
      stop("Watson and Crick ratio-table coordinates do not match.")
    }
    ProfileTable <- data.frame(
      chrom=Watson$chrom,
      chromStart=Watson$chromStart,
      chromEnd=Watson$chromEnd,
      watson_signal=TransformSignal(Watson$metric_value),
      crick_signal=TransformSignal(Crick$metric_value),
      stringsAsFactors=FALSE
    )
    rm(Watson, Crick)
    gc(verbose=FALSE)
  }

  InferStep <- function(profile_table){
    first_chrom <- profile_table$chrom[[1]]
    starts <- profile_table$chromStart[profile_table$chrom == first_chrom]
    starts <- sort(unique(starts[is.finite(starts)]))
    differences <- diff(utils::head(starts, 10000))
    differences <- differences[is.finite(differences) & differences > 0]
    if(length(differences) == 0){
      stop("Could not infer the ratio-table step size; provide Step explicitly.")
    }
    as.numeric(names(which.max(base::table(differences))))
  }
  if(is.null(Step)) Step <- InferStep(ProfileTable)

  if(DisplayPeaks){
    if(is.null(PeakFile)){
      PeakFile <- file.path(
        SampleDir, PeakFolder, paste0(SampleName, "_Genomewide_Peaks.bed")
      )
    } else {
      PeakFile <- path.expand(PeakFile)
    }
  } else {
    PeakFile <- NA_character_
  }

  EmptyPeakTable <- data.frame(
    chrom=character(), peakStart=numeric(), peakEnd=numeric(),
    peakSummit=numeric(), stringsAsFactors=FALSE
  )
  ReadPeaks <- function(file){
    if(!file.exists(file)) return(EmptyPeakTable)
    peaks <- data.table::fread(file, data.table=FALSE, showProgress=FALSE)
    lower <- tolower(names(peaks))
    chrom_col <- match(TRUE, lower %in% c("chrom", "chr"))
    start_col <- match(TRUE, lower %in% c("peakstart", "start"))
    end_col <- match(TRUE, lower %in% c("peakend", "end"))
    summit_col <- match(TRUE, lower %in% c("peaksummit", "summit", "abs_summit"))
    if(any(is.na(c(chrom_col, start_col, end_col)))){
      stop("Peak table does not contain chromosome, start, and end columns: ", file)
    }
    out <- data.frame(
      chrom=as.character(peaks[[chrom_col]]),
      peakStart=as.numeric(peaks[[start_col]]),
      peakEnd=as.numeric(peaks[[end_col]]),
      peakSummit=if(is.na(summit_col)){
        (as.numeric(peaks[[start_col]]) + as.numeric(peaks[[end_col]]))/2
      } else {
        as.numeric(peaks[[summit_col]])
      },
      stringsAsFactors=FALSE
    )
    out <- out[
      is.finite(out$peakStart) & is.finite(out$peakEnd) &
        out$peakEnd > out$peakStart,
      , drop=FALSE
    ]
    out[order(out$chrom, out$peakStart, out$peakEnd), , drop=FALSE]
  }
  Peaks <- if(DisplayPeaks) ReadPeaks(PeakFile) else EmptyPeakTable
  if(DisplayPeaks && nrow(Peaks) == 0){
    warning("No genomewide peak table was found; peak overlays will be skipped.")
  }

  ReadFeature <- function(file, default_type){
    if(!file.exists(file)) stop("Missing genomic-element file: ", file)
    first_line <- readLines(file, n=1, warn=FALSE)
    fields <- strsplit(trimws(first_line), "\\s+")[[1]]
    has_header <- length(fields) >= 3 &&
      (is.na(suppressWarnings(as.numeric(fields[2]))) ||
       is.na(suppressWarnings(as.numeric(fields[3]))))
    features <- data.table::fread(
      file,
      header=has_header,
      data.table=FALSE,
      showProgress=FALSE
    )
    if(ncol(features) < 3) stop("Genomic-element file has fewer than 3 columns: ", file)
    if(has_header){
      lower <- tolower(names(features))
      chrom_col <- match(TRUE, lower %in% c("chrom", "chr"))
      start_col <- match(TRUE, lower %in% c("chromstart", "start"))
      end_col <- match(TRUE, lower %in% c("chromend", "end"))
      name_col <- match(TRUE, lower %in% c("name", "orf", "gene", "feature"))
      score_col <- match(TRUE, lower %in% "score")
      strand_col <- match(TRUE, lower %in% "strand")
      type_col <- match(TRUE, lower %in% c("type", "featuretype"))
      stat_col <- match(TRUE, lower %in% c("stat", "status", "timing"))
    } else {
      chrom_col <- 1L
      start_col <- 2L
      end_col <- 3L
      name_col <- if(ncol(features) >= 4) 4L else NA_integer_
      score_col <- if(ncol(features) >= 5) 5L else NA_integer_
      strand_col <- if(ncol(features) >= 6) 6L else NA_integer_
      type_col <- if(ncol(features) >= 7) 7L else NA_integer_
      stat_col <- NA_integer_
    }
    if(any(is.na(c(chrom_col, start_col, end_col)))){
      stop("Could not identify genomic-element coordinates in: ", file)
    }
    out <- data.frame(
      chrom=as.character(features[[chrom_col]]),
      chromStart=as.numeric(features[[start_col]]),
      chromEnd=as.numeric(features[[end_col]]),
      name=if(is.na(name_col)) paste0(default_type, "_", seq_len(nrow(features)))
           else as.character(features[[name_col]]),
      score=if(is.na(score_col)) 0 else as.numeric(features[[score_col]]),
      strand=if(is.na(strand_col)) "." else as.character(features[[strand_col]]),
      type=if(is.na(type_col)) default_type else as.character(features[[type_col]]),
      stat=if(is.na(stat_col)) "" else as.character(features[[stat_col]]),
      stringsAsFactors=FALSE
    )
    out$strand[out$strand %in% c("1", "plus", "Plus", "Watson", "W")] <- "+"
    out$strand[out$strand %in% c("-1", "minus", "Minus", "Crick", "C")] <- "-"
    out$strand[!out$strand %in% c("+", "-", ".")] <- "."
    out <- out[
      is.finite(out$chromStart) & is.finite(out$chromEnd) &
        out$chromEnd > out$chromStart,
      , drop=FALSE
    ]
    out
  }

  ProjectPaths <- ChIP_BrDU_Project_Paths(check=TRUE)
  Annotations <- list(
    ORFs=ReadFeature(ProjectPaths$elements$orfs, "ORF"),
    ARS=ReadFeature(ProjectPaths$elements$ars, "ARS"),
    TER=ReadFeature(ProjectPaths$elements$termination_regions, "TER"),
    Ty=ReadFeature(ProjectPaths$elements$ty_elements, "Ty"),
    tRNA=ReadFeature(ProjectPaths$elements$trnas, "tRNA"),
    Centromeres=ReadFeature(ProjectPaths$elements$centromeres, "centromere")
  )

  ChromosomeInfo <- data.frame(
    chrom=c("chrI", "chrII", "chrIII", "chrIV", "chrV", "chrVI", "chrVII",
            "chrVIII", "chrIX", "chrX", "chrXI", "chrXII", "chrXIII",
            "chrXIV", "chrXV", "chrXVI", "chrM"),
    length=c(230218, 813184, 316620, 1531933, 576874, 270161, 1090940,
             562643, 439888, 745751, 666816, 1078177, 924431, 784333,
             1091291, 948066, 85779),
    stringsAsFactors=FALSE
  )

  ResolveChromosomes <- function(request){
    if(is.null(request) || length(request) == 0 ||
       (length(request) == 1 &&
        tolower(as.character(request)) %in% c("all", "genome", "whole_genome", "whole genome"))){
      result <- ChromosomeInfo[seq_len(16), , drop=FALSE]
      result$k <- seq_len(nrow(result))
      return(result[, c("k", "chrom", "length")])
    }
    indexes <- vapply(request, function(item){
      if(is.numeric(item) || grepl("^[0-9]+$", as.character(item))){
        index <- as.integer(item)
      } else {
        stripped <- sub("^chr", "", as.character(item), ignore.case=TRUE)
        index <- match(toupper(stripped),
                       toupper(sub("^chr", "", ChromosomeInfo$chrom)))
      }
      if(is.na(index) || index < 1 || index > nrow(ChromosomeInfo)){
        stop("Could not resolve chromosome: ", item)
      }
      index
    }, integer(1))
    indexes <- indexes[!duplicated(indexes)]
    result <- ChromosomeInfo[indexes, , drop=FALSE]
    result$k <- indexes
    result[, c("k", "chrom", "length")]
  }
  PlotChromosomes <- ResolveChromosomes(Chromosomes)

  MetricLabels <- c(
    "ip.score"=paste0(Assay, " coverage"),
    "ratio.ipin"=paste0(Assay, " / Input"),
    "ratio.ipnoise"=paste0(Assay, " / Noise"),
    "ratio.ipin.noise"=paste0("(", Assay, " / Noise) / (Input / Noise)")
  )
  MetricShortLabels <- c(
    "ip.score"=paste0(Assay, " coverage"),
    "ratio.ipin"=paste0(Assay, "/Input"),
    "ratio.ipnoise"=paste0(Assay, "/Noise"),
    "ratio.ipin.noise"=paste0(Assay, " clean enrichment")
  )
  TitleMetricLabel <- unname(MetricLabels[[Metric]])
  YLabel <- unname(MetricShortLabels[[Metric]])
  if(DisplayLog2){
    TitleMetricLabel <- paste0("log2(", TitleMetricLabel, ")")
    YLabel <- paste0("log2 ", YLabel)
  }
  if(StrandMode == "separated"){
    TitleMetricLabel <- paste0(TitleMetricLabel, " | W(+), C(-)")
    YLabel <- paste0(YLabel, " | W(+), C(-)")
  }

  MetricIsRatio <- Metric != "ip.score"
  BaselineValue <- if(DisplayLog2) 0 else if(MetricIsRatio) 1 else 0

  GetThreshold <- function(values){
    values <- values[is.finite(values)]
    if(length(values) == 0) return(1)
    quantiles <- stats::quantile(values, probs=c(0.01, 0.99), na.rm=TRUE)
    iqr <- stats::IQR(values, na.rm=TRUE)
    trimmed <- values[values > quantiles[1] - 1.5*iqr &
                        values < quantiles[2] + 1.5*iqr]
    threshold <- if(length(trimmed) < 2){
      max(abs(values), na.rm=TRUE)
    } else {
      mean(trimmed, na.rm=TRUE) + YAxisScale*stats::sd(trimmed, na.rm=TRUE)
    }
    if(!is.finite(threshold) || threshold <= 0){
      threshold <- max(abs(values), na.rm=TRUE)
    }
    if(!is.finite(threshold) || threshold <= 0) threshold <- 1
    threshold
  }

  ChromosomeRows <- ProfileTable$chrom %in% PlotChromosomes$chrom
  if(!is.null(y_val)){
    if(StrandMode == "collapsed"){
      if(DisplayLog2 && y_val <= Log2YMin){
        stop("For a collapsed log2 plot, y_val must be greater than Log2YMin.")
      }
      Ylim <- if(DisplayLog2) c(Log2YMin, y_val) else c(0, y_val)
    } else {
      Ylim <- c(-y_val, y_val)
    }
    YLimitSource <- "y_val"
  } else {
    if(StrandMode == "collapsed"){
      values <- ProfileTable$plot_signal[ChromosomeRows]
      y_max <- max(1, GetThreshold(values), na.rm=TRUE)
      if(DisplayLog2){
        Ylim <- c(Log2YMin, ceiling(y_max))
      } else {
        if(ShowBaseline) y_max <- max(y_max, BaselineValue*1.05)
        Ylim <- c(0, y_max)
      }
    } else {
      values <- c(
        ProfileTable$watson_signal[ChromosomeRows],
        ProfileTable$crick_signal[ChromosomeRows]
      )
      y_max <- ceiling(max(1, GetThreshold(abs(values)), na.rm=TRUE))
      if(!DisplayLog2 && MetricIsRatio) y_max <- max(y_max, 1.05)
      Ylim <- c(-y_max, y_max)
    }
    YLimitSource <- "internal"
  }
  YAxisTicks <- pretty(Ylim, n=5)
  YAxisTicks <- YAxisTicks[YAxisTicks >= min(Ylim) & YAxisTicks <= max(Ylim)]

  SafeSmooth <- function(x, y){
    ok <- is.finite(x) & is.finite(y)
    if(sum(ok) < 4 || length(unique(x[ok])) < 4 || length(unique(y[ok])) < 2){
      return(y)
    }
    model <- tryCatch(
      if(is.null(SmoothingSpar)) stats::smooth.spline(x[ok], y[ok])
      else stats::smooth.spline(x[ok], y[ok], spar=SmoothingSpar),
      error=function(e) NULL
    )
    if(is.null(model)) return(y)
    stats::predict(model, x)$y
  }

  WindowFeatures <- function(features, chrom, start, end){
    features[
      features$chrom == chrom & features$chromEnd >= start &
        features$chromStart <= end,
      , drop=FALSE
    ]
  }

  ARSLabelLevelsFunction <- function(x){
    if(length(x) == 0) return(integer())
    levels <- integer(length(x))
    last_x <- rep(-Inf, ARSLabelLevels)
    for(index in order(x)){
      available <- which((x[index] - last_x) >= ARSLabelMinGap)
      level <- if(length(available) == 0) which.min(last_x) else available[1]
      levels[index] <- level - 1L
      last_x[level] <- x[index]
    }
    levels
  }

  DrawARS <- function(window, baseline){
    origins <- WindowFeatures(
      Annotations$ARS, window$chrom, window$S, window$E
    )
    if(nrow(origins) == 0) return(invisible(NULL))
    y_range <- diff(Ylim)
    origin_x <- ((origins$chromStart + origins$chromEnd)/2 - window$S)/Step
    origin_y <- if(is.finite(baseline) && baseline >= min(Ylim) && baseline <= max(Ylim)){
      baseline
    } else {
      0
    }
    points(origin_x, rep(origin_y, length(origin_x)), pch=21,
           bg="yellow", col="purple", lwd=1.4, cex=1.05)
    if(!ShowARSLabels) return(invisible(NULL))
    label_levels <- ARSLabelLevelsFunction(origin_x)
    label_y <- max(Ylim) + (0.16 + 0.12*label_levels)*y_range
    triangle_y <- max(Ylim) + (0.055 + 0.12*label_levels)*y_range
    label_col <- rep("gray10", nrow(origins))
    status <- tolower(origins$stat)
    label_col[status == "early"] <- "red"
    label_col[status == "late"] <- "blue"
    segments(origin_x, max(Ylim), origin_x, triangle_y,
             col=grDevices::adjustcolor("purple", alpha.f=0.35),
             lwd=1.2, xpd=NA)
    points(origin_x, triangle_y, pch=24, bg="yellow", col="purple",
           lwd=1.3, cex=0.95, xpd=NA)
    text(origin_x, label_y, labels=origins$name, xpd=NA,
         cex=ARSLabelCex, col=label_col)
    invisible(NULL)
  }

  PeakSupportedBars <- function(coverage, y_values, chrom){
    qualified <- rep(FALSE, nrow(coverage))
    positive <- is.finite(y_values) & y_values > 0
    if(!any(positive) || nrow(Peaks) == 0) return(qualified)
    peaks <- Peaks[
      Peaks$chrom == chrom &
        Peaks$peakEnd >= min(coverage$chromStart) - 500 &
        Peaks$peakStart <= max(coverage$chromEnd) + 500,
      , drop=FALSE
    ]
    if(nrow(peaks) == 0) return(qualified)
    for(index in seq_len(nrow(peaks))){
      overlap <- positive & coverage$chromEnd >= peaks$peakStart[index] &
        coverage$chromStart <= peaks$peakEnd[index]
      if(!any(overlap)) next
      peak_height <- max(y_values[overlap], na.rm=TRUE)
      candidate <- positive &
        coverage$chromEnd >= peaks$peakStart[index] - 500 &
        coverage$chromStart <= peaks$peakEnd[index] + 500 &
        y_values >= peak_height*0.35
      if(!any(candidate)) next
      runs <- rle(candidate)
      run_end <- cumsum(runs$lengths)
      run_start <- run_end - runs$lengths + 1L
      for(run_index in seq_along(runs$values)){
        if(runs$values[run_index]){
          positions <- run_start[run_index]:run_end[run_index]
          if(any(overlap[positions])) qualified[positions] <- TRUE
        }
      }
    }
    qualified
  }

  PlotProfileWindow <- function(window, full_window_bp, title_text){
    coverage <- ProfileTable[
      ProfileTable$chrom == window$chrom &
        ProfileTable$chromStart >= window$S &
        ProfileTable$chromStart < window$E,
      , drop=FALSE
    ]
    x_max <- full_window_bp/Step
    y_range <- diff(Ylim)
    par(mar=ProfileMar)
    plot(NA, xlim=c(0, x_max), ylim=Ylim, ylab="", xlab="",
         xaxt="n", yaxt="n", bty="n", xaxs="i")

    if(nrow(coverage) > 0){
      x <- (coverage$chromStart - window$S)/Step
      x_end <- (coverage$chromEnd - window$S)/Step
      if(StrandMode == "collapsed"){
        y <- coverage$plot_signal
        if(SmoothSignal) y <- SafeSmooth(x, y)
        if(PlotStyle == "lines"){
          lines(x, y, col=CollapsedSignalColor, lwd=ProfileLineLwd)
        } else {
          positive <- PeakSupportedBars(coverage, y, window$chrom)
          colors <- ifelse(positive, PositiveSignalColor, NegativeSignalColor)
          segments(x, 0, x, y, col=colors, lwd=ProfileBarLwd)
        }
      } else {
        watson <- coverage$watson_signal
        crick <- coverage$crick_signal
        if(SmoothSignal){
          watson <- SafeSmooth(x, watson)
          crick <- SafeSmooth(x, crick)
        }
        watson[!is.finite(watson)] <- 0
        crick[!is.finite(crick)] <- 0
        watson <- pmax(watson, 0)
        crick <- -pmax(crick, 0)
        if(PlotStyle == "lines"){
          lines(x, watson, col=WatsonColor, lwd=ProfileLineLwd)
          lines(x, crick, col=CrickColor, lwd=ProfileLineLwd)
        } else {
          segments(x, 0, x, watson, col=WatsonColor, lwd=ProfileBarLwd)
          segments(x, 0, x, crick, col=CrickColor, lwd=ProfileBarLwd)
        }
        legend("topright", legend=c("Watson", "Crick"),
               col=c(WatsonColor, CrickColor), lwd=2, bty="n", cex=0.72)
      }
      segments(x, 0, x_end, 0, lwd=0.25,
               col=grDevices::adjustcolor("gray40", alpha.f=0.35))
    }

    axis(2, at=YAxisTicks, labels=signif(YAxisTicks, 3), line=0,
         tick=TRUE, lwd.ticks=1.2, las=2, cex.axis=0.8)
    abline(h=YAxisTicks, lwd=0.05,
           col=grDevices::rgb(112, 128, 144, alpha=150, maxColorValue=255))
    if(ShowBaseline){
      if(StrandMode == "separated"){
        abline(h=0, lwd=0.9, lty=3, col="gray20")
        if(!DisplayLog2 && MetricIsRatio){
          abline(h=c(-1, 1), lwd=0.7, lty=3, col="gray45")
        }
      } else if(BaselineValue >= min(Ylim) && BaselineValue <= max(Ylim)){
        abline(h=BaselineValue, lwd=0.9, lty=3, col="gray20")
      }
    }

    if(DisplayPeaks && nrow(Peaks) > 0){
      window_peaks <- Peaks[
        Peaks$chrom == window$chrom & Peaks$peakEnd >= window$S &
          Peaks$peakStart <= window$E,
        , drop=FALSE
      ]
      if(nrow(window_peaks) > 0){
        peak_x0 <- (pmax(window_peaks$peakStart, window$S) - window$S)/Step
        peak_x1 <- (pmin(window_peaks$peakEnd, window$E) - window$S)/Step
        rect(peak_x0, max(Ylim) - 0.08*y_range,
             peak_x1, max(Ylim) - 0.015*y_range,
             col=grDevices::adjustcolor(PeakColor, alpha.f=0.35), border=NA)
      }
    }

    DrawARS(window, if(StrandMode == "separated") 0 else BaselineValue)
    centromeres <- WindowFeatures(
      Annotations$Centromeres, window$chrom, window$S, window$E
    )
    if(nrow(centromeres) > 0){
      centromere_x <- ((centromeres$chromStart + centromeres$chromEnd)/2 -
                         window$S)/Step
      segments(centromere_x, min(Ylim), centromere_x, max(Ylim),
               lwd=1.6, col="darkgreen")
      text(centromere_x, max(Ylim) - 0.11*y_range, labels="CEN",
           cex=0.65, col="darkgreen", pos=4)
    }
    title(main=title_text, col="gray35", adj=0, cex.main=0.95, line=0.25)
    mtext(side=2, line=2.75, at=mean(Ylim), cex=0.85, YLabel)
    box(col="gray45")
  }

  DrawBlocks <- function(features, window, y, height, color, border){
    selected <- WindowFeatures(features, window$chrom, window$S, window$E)
    if(nrow(selected) == 0) return(invisible(NULL))
    x0 <- (pmax(selected$chromStart, window$S) - window$S)/Step
    x1 <- (pmin(selected$chromEnd, window$E) - window$S)/Step
    too_small <- (x1 - x0) < 0.6
    mid <- (x0 + x1)/2
    x0[too_small] <- mid[too_small] - 0.3
    x1[too_small] <- mid[too_small] + 0.3
    rect(x0, y-height, x1, y+height, col=color, border=border, lwd=0.4)
    invisible(NULL)
  }

  PlotAnnotationWindow <- function(window, full_window_bp, show_x_label){
    x_max <- full_window_bp/Step
    par(mar=AnnotationMar)
    plot(NA, xlim=c(0, x_max), ylim=c(0, 1), ylab="", xlab="",
         xaxt="n", yaxt="n", bty="n", xaxs="i", yaxs="i")
    abline(h=c(0.16, 0.30, 0.48, 0.66, 0.82), lwd=0.05,
           col=grDevices::rgb(112, 128, 144, alpha=150, maxColorValue=255))

    if("ORF" %in% FeatureTracks){
      orfs <- WindowFeatures(Annotations$ORFs, window$chrom, window$S, window$E)
      if(nrow(orfs) > 0){
        orfs$plotStart <- pmax(orfs$chromStart, window$S)
        orfs$plotEnd <- pmin(orfs$chromEnd, window$E)
        orfs <- orfs[orfs$plotEnd > orfs$plotStart, , drop=FALSE]
        for(index in seq_len(nrow(orfs))){
          x0 <- (orfs$plotStart[index] - window$S)/Step
          x1 <- (orfs$plotEnd[index] - window$S)/Step
          plus <- orfs$strand[index] == "+"
          y <- if(plus) 0.82 else 0.66
          color <- if(plus) "brown3" else "cornflowerblue"
          if(!is.finite(x0) || !is.finite(x1) || x1 <= x0) next
          if((x1 - x0) < 0.5){
            segments(x0, y, x1, y, lwd=ORFLwd, col=color)
            next
          }
          if(plus){
            suppressWarnings(
              arrows(x0, y, x1, y, length=0.04, angle=25, code=2,
                     lwd=ORFLwd, col=color)
            )
          } else {
            suppressWarnings(
              arrows(x1, y, x0, y, length=0.04, angle=25, code=2,
                     lwd=ORFLwd, col=color)
            )
          }
        }
      }
    }
    if("Ty" %in% FeatureTracks){
      DrawBlocks(Annotations$Ty, window, 0.48, 0.055,
                 grDevices::adjustcolor("mediumpurple3", alpha.f=0.75),
                 "mediumpurple4")
    }
    if("TER" %in% FeatureTracks){
      DrawBlocks(Annotations$TER, window, 0.30, 0.055,
                 grDevices::adjustcolor("orange2", alpha.f=0.65), "orange4")
    }
    if("tRNA" %in% FeatureTracks){
      DrawBlocks(Annotations$tRNA, window, 0.16, 0.045,
                 grDevices::adjustcolor("seagreen3", alpha.f=0.75), "seagreen4")
    }
    axis(2, at=c(0.82, 0.66, 0.48, 0.30, 0.16),
         labels=c("ORF+", "ORF-", "Ty", "TER", "tRNA"),
         line=0, tick=TRUE, lwd.ticks=1, las=2, cex.axis=0.75)
    tick_by <- max(10000, round(full_window_bp/5, -3))
    ticks_bp <- seq(ceiling(window$S/tick_by)*tick_by, window$E, by=tick_by)
    ticks_x <- (ticks_bp - window$S)/Step
    axis(1, at=ticks_x, labels=round(ticks_bp/1000),
         line=0, tick=FALSE, cex.axis=0.8)
    if(show_x_label){
      title(xlab="Chromosomal Coordinates (Kbp)", col="gray",
            cex.lab=0.9, line=0.75)
    }
    box(col="gray45")
  }

  PlotSpacer <- function(show_legend){
    par(mar=c(0, 0, 0, 0))
    plot(NA, xlim=c(0, 1), ylim=c(0, 1), axes=FALSE,
         xlab="", ylab="", bty="n", xaxs="i", yaxs="i")
    if(show_legend){
      y <- 0.55
      x_ars <- if(DisplayPeaks) 0.40 else 0.46
      points(x_ars, y, pch=21, bg=grDevices::adjustcolor("yellow", alpha.f=0),
             col="purple", lwd=1.4, cex=1.1)
      text(x_ars + 0.035, y, "ARS", adj=0, cex=0.8, col="gray25")
      if(DisplayPeaks){
        x_peak <- 0.56
        rect(x_peak, y-0.035, x_peak+0.035, y+0.035,
             col=grDevices::adjustcolor(PeakColor, alpha.f=0.35), border=NA)
        text(x_peak+0.055, y, "Peaks", adj=0, cex=0.8, col="gray25")
      }
    }
  }

  PlotBlankWindow <- function(show_legend){
    par(mar=ProfileMar)
    plot(NA, xlim=c(0, 1), ylim=c(0, 1), axes=FALSE,
         xlab="", ylab="", bty="n")
    par(mar=AnnotationMar)
    plot(NA, xlim=c(0, 1), ylim=c(0, 1), axes=FALSE,
         xlab="", ylab="", bty="n")
    PlotSpacer(show_legend)
  }

  metric_suffix <- gsub("\\.", "_", Metric)
  log_suffix <- if(DisplayLog2) "log2_" else ""
  chromosome_suffix <- if(nrow(PlotChromosomes) == 16 &&
                          identical(PlotChromosomes$chrom, ChromosomeInfo$chrom[1:16])){
    "whole_genome"
  } else {
    paste(PlotChromosomes$chrom, collapse="_")
  }
  OutputFile <- file.path(
    OutputDir,
    paste0(SampleName, "_", Assay, "_", Alignment, "_", StrandMode, "_",
           chromosome_suffix, "_", log_suffix, metric_suffix, ".pdf")
  )

  full_window_bp <- WindowSizeKb*1000
  grDevices::pdf(OutputFile, width=PdfWidth, height=PdfHeight, useDingbats=FALSE)
  on.exit(grDevices::dev.off(), add=TRUE)

  for(chromosome_index in seq_len(nrow(PlotChromosomes))){
    chromosome <- PlotChromosomes[chromosome_index, , drop=FALSE]
    starts <- seq(0, chromosome$length-1, by=full_window_bp)
    Windows <- data.frame(
      chrom=chromosome$chrom,
      S=starts,
      E=pmin(starts+full_window_bp, chromosome$length),
      stringsAsFactors=FALSE
    )
    page_count <- ceiling(nrow(Windows)/PanelsPerPage)
    for(page in seq_len(page_count)){
      page_start <- (page-1)*PanelsPerPage+1
      page_end <- min(page*PanelsPerPage, nrow(Windows))
      PageWindows <- Windows[page_start:page_end, , drop=FALSE]
      layout(matrix(seq_len(PanelsPerPage*3), ncol=1),
             heights=rep(c(3.2, 1.35, max(PanelGapHeight, 0.001)), PanelsPerPage))
      par(oma=OuterMar)
      for(panel in seq_len(PanelsPerPage)){
        if(panel > nrow(PageWindows)){
          PlotBlankWindow(ShowFeatureLegend && panel == PanelsPerPage)
          next
        }
        window <- PageWindows[panel, ]
        title_text <- paste0(
          SampleName, " ", Assay, " ", StrandMode, " ", window$chrom, ":",
          format(window$S, scientific=FALSE, trim=TRUE), "-",
          format(window$E, scientific=FALSE, trim=TRUE)
        )
        PlotProfileWindow(window, full_window_bp, title_text)
        PlotAnnotationWindow(
          window,
          full_window_bp,
          show_x_label=panel == nrow(PageWindows)
        )
        PlotSpacer(ShowFeatureLegend && panel == PanelsPerPage)
      }
      title_prefix <- if(nrow(PlotChromosomes) == 1) "Whole chromosome " else "Whole genome "
      mtext(
        paste0(title_prefix, TitleMetricLabel, " | ", chromosome$chrom,
               " | page ", page, "/", page_count),
        outer=TRUE, side=3, line=1.5, cex=0.95, col="gray35"
      )
    }
  }

  message("Whole-genome plot saved: ", OutputFile)
  invisible(list(
    pdf=OutputFile,
    sample_dir=SampleDir,
    sample_name=SampleName,
    assay=Assay,
    alignment=Alignment,
    strand_mode=StrandMode,
    metric=Metric,
    ratio_files=ExpectedRatioFiles,
    peak_file=if(DisplayPeaks && file.exists(PeakFile)) PeakFile else NA_character_,
    peak_visualization=DisplayPeaks,
    log2_profile=DisplayLog2,
    chromosomes=PlotChromosomes$chrom,
    step=Step,
    y_val=y_val,
    y_limits=Ylim,
    y_limit_source=YLimitSource,
    primary_output_only=TRUE,
    plotter_operations=c(
      simulation=FALSE,
      noise_estimation=FALSE,
      signal_filtering=FALSE,
      ratio_recalculation=FALSE,
      peak_calling=FALSE,
      pvalue_thresholding=FALSE
    ),
    display_operations=c(
      spline_smoothing=SmoothSignal,
      collapsed_log2=DisplayLog2,
      crick_mirroring=StrandMode == "separated"
    )
  ))
}





## Regional ChIP/BrDU enrichment plotter.
##
## SampleDir accepts one sample directory or a vector of directories. Multiple
## samples are drawn as vertically stacked panels with one common y-axis scale
## and one shared genomic-element track. Assay and Alignment may each be one
## value shared by every sample or one value per sample.
##
## RegionStart and RegionEnd use the same zero-based, half-open coordinates as
## the primary-analysis BED ratio tables. Collapsed profiles may be shown with
## or without log2 transformation. Separated profiles always use untransformed
## Watson and Crick ratios, with Crick mirrored below zero. Spline smoothing is
## a display-only operation and never changes the source ratio tables.
##
## Example:
## ChIP_BrDU_Region_Plotter(
##   SampleDir=c("/path/sample_A-ChIP", "/path/sample_B-ChIP"),
##   Chromosome="chrIV",
##   RegionStart=400000,
##   RegionEnd=500000,
##   Assay="ChIP",
##   StrandMode="collapsed",
##   Log2Profile=TRUE
## )
ChIP_BrDU_Region_Plotter <- function(
    SampleDir,
    Chromosome,
    RegionStart,
    RegionEnd,
    Assay="ChIP",
    Alignment="generic",
    StrandMode="collapsed",
    Metric="ratio.ipin.noise",
    Log2Profile=TRUE,
    SampleLabels=NULL,
    PlotStyle="hist",
    y_val=NULL,
    OutputDir=NULL){

  ## Fixed graphical contract. These settings remain internal so the run-script
  ## call stays concise and comparisons remain visually consistent.
  PanelsPerPage <- 4L
  Log2YMin <- -1
  YAxisScale <- 8
  SmoothSignal <- TRUE
  SmoothingSpar <- NULL
  ShowBaseline <- TRUE
  FeatureTracks <- c("ORF", "Ty", "TER", "tRNA")
  CollapsedSignalColor <- "gray25"
  PositiveSignalColor <- "red"
  NegativeSignalColor <- "gray70"
  WatsonColor <- "brown3"
  CrickColor <- "cornflowerblue"
  PeakColor <- "firebrick2"
  ProfileLineLwd <- 1.15
  ProfileBarLwd <- 0.35
  ORFLwd <- 2.5
  PdfWidth <- 11
  ProfileMar <- c(0.45, 4.5, 1.55, 1.0)
  AnnotationMar <- c(2.05, 4.5, 0.35, 1.0)
  OuterMar <- c(2.4, 2.5, 2.8, 1.2)

  ValidateLogical <- function(x, name){
    if(!is.logical(x) || length(x) != 1 || is.na(x)){
      stop(name, " must be TRUE or FALSE.")
    }
  }
  ValidatePositive <- function(x, name){
    if(!is.numeric(x) || length(x) != 1 || !is.finite(x) || x <= 0){
      stop(name, " must be one positive number.")
    }
  }
  RecycleChoice <- function(x, n, choices, name){
    x <- as.character(x)
    if(length(x) == 1L) x <- rep(x, n)
    if(length(x) != n){
      stop(name, " must contain one value or one value per SampleDir.")
    }
    invalid <- !x %in% choices
    if(any(invalid)){
      stop(
        name, " contains unsupported value(s): ",
        paste(unique(x[invalid]), collapse=", "),
        ". Allowed values: ", paste(choices, collapse=", "), "."
      )
    }
    x
  }

  if(is.null(SampleDir) || length(SampleDir) == 0){
    stop("SampleDir must contain at least one sample directory.")
  }
  SampleDir <- as.character(SampleDir)
  if(any(is.na(SampleDir) | !nzchar(SampleDir))){
    stop("Every SampleDir entry must be a non-empty path.")
  }
  SampleDir <- vapply(
    SampleDir,
    function(path) normalizePath(path.expand(path), winslash="/", mustWork=TRUE),
    character(1)
  )
  NumberOfSamples <- length(SampleDir)

  Assay <- RecycleChoice(Assay, NumberOfSamples, c("ChIP", "BrDU"), "Assay")
  Alignment <- RecycleChoice(
    Alignment, NumberOfSamples, c("generic", "malign"), "Alignment"
  )
  StrandMode <- match.arg(as.character(StrandMode)[1], c("collapsed", "separated"))
  Metric <- match.arg(
    as.character(Metric)[1],
    c("ratio.ipin.noise", "ratio.ipin", "ratio.ipnoise", "ip.score")
  )
  PlotStyle <- match.arg(as.character(PlotStyle)[1], c("hist", "lines"))
  if(PlotStyle == "hist") PlotStyle <- "bars"
  ValidateLogical(Log2Profile, "Log2Profile")
  if(!is.null(y_val)) ValidatePositive(y_val, "y_val")

  DisplayLog2 <- StrandMode == "collapsed" && Log2Profile
  DisplayPeaks <- StrandMode == "collapsed"
  if(StrandMode == "separated" && Log2Profile){
    message("Strand-separated regional profiles use untransformed ratios; Log2Profile is ignored.")
  }

  SampleNames <- basename(SampleDir)
  if(is.null(SampleLabels)){
    SampleLabels <- SampleNames
  } else {
    SampleLabels <- as.character(SampleLabels)
    if(length(SampleLabels) != NumberOfSamples){
      stop("SampleLabels must contain one label per SampleDir.")
    }
    if(any(is.na(SampleLabels) | !nzchar(SampleLabels))){
      stop("Every SampleLabels entry must be non-empty.")
    }
  }

  ChromosomeInfo <- data.frame(
    chrom=c("chrI", "chrII", "chrIII", "chrIV", "chrV", "chrVI", "chrVII",
            "chrVIII", "chrIX", "chrX", "chrXI", "chrXII", "chrXIII",
            "chrXIV", "chrXV", "chrXVI", "chrM"),
    length=c(230218, 813184, 316620, 1531933, 576874, 270161, 1090940,
             562643, 439888, 745751, 666816, 1078177, 924431, 784333,
             1091291, 948066, 85779),
    stringsAsFactors=FALSE
  )
  ResolveChromosome <- function(chromosome){
    if(length(chromosome) != 1 || is.na(chromosome)){
      stop("Chromosome must identify exactly one chromosome.")
    }
    chromosome <- as.character(chromosome)
    if(grepl("^[0-9]+$", chromosome)){
      index <- as.integer(chromosome)
    } else {
      stripped <- sub("^chr", "", chromosome, ignore.case=TRUE)
      index <- match(
        toupper(stripped),
        toupper(sub("^chr", "", ChromosomeInfo$chrom))
      )
    }
    if(is.na(index) || index < 1 || index > nrow(ChromosomeInfo)){
      stop("Could not resolve chromosome: ", chromosome)
    }
    ChromosomeInfo[index, , drop=FALSE]
  }
  ChromosomeRecord <- ResolveChromosome(Chromosome)
  Chromosome <- ChromosomeRecord$chrom[[1]]
  ChromosomeLength <- ChromosomeRecord$length[[1]]

  if(!is.numeric(RegionStart) || length(RegionStart) != 1 ||
     !is.finite(RegionStart) || RegionStart < 0){
    stop("RegionStart must be one finite, non-negative coordinate.")
  }
  if(!is.numeric(RegionEnd) || length(RegionEnd) != 1 ||
     !is.finite(RegionEnd) || RegionEnd <= RegionStart){
    stop("RegionEnd must be one finite coordinate greater than RegionStart.")
  }
  if(RegionEnd > ChromosomeLength){
    stop(
      "RegionEnd exceeds ", Chromosome, " length (", ChromosomeLength, " bp)."
    )
  }
  RegionStart <- as.numeric(RegionStart)
  RegionEnd <- as.numeric(RegionEnd)
  RegionWidth <- RegionEnd - RegionStart

  if(is.null(OutputDir)){
    OutputDir <- if(NumberOfSamples == 1L) SampleDir[[1]] else dirname(SampleDir[[1]])
  }
  OutputDir <- path.expand(as.character(OutputDir)[1])
  dir.create(OutputDir, recursive=TRUE, showWarnings=FALSE)
  OutputDir <- normalizePath(OutputDir, winslash="/", mustWork=TRUE)

  if(!requireNamespace("data.table", quietly=TRUE)){
    stop("The data.table package is required to read regional ratio tables efficiently.")
  }

  TransformSignal <- function(values){
    values <- suppressWarnings(as.numeric(values))
    if(DisplayLog2){
      values[!is.finite(values) | values <= 0] <- 1
      values <- log2(values)
    } else {
      values[!is.finite(values)] <- 0
    }
    values
  }

  ReadRatio <- function(file, sample_label){
    header <- names(data.table::fread(
      file, nrows=0, data.table=FALSE, showProgress=FALSE
    ))
    required <- c("chrom", "chromStart", "chromEnd", Metric)
    missing <- setdiff(required, header)
    if(length(missing) > 0){
      stop(
        "Ratio table for ", sample_label, " is missing required column(s) ",
        paste(missing, collapse=", "), ": ", file
      )
    }
    ratio <- data.table::fread(
      file, select=required, data.table=FALSE, showProgress=FALSE
    )
    names(ratio)[names(ratio) == Metric] <- "metric_value"
    ratio$chrom <- as.character(ratio$chrom)
    ratio$chromStart <- as.numeric(ratio$chromStart)
    ratio$chromEnd <- as.numeric(ratio$chromEnd)
    ratio$metric_value <- as.numeric(ratio$metric_value)
    ratio <- ratio[
      ratio$chrom == Chromosome &
        is.finite(ratio$chromStart) & is.finite(ratio$chromEnd) &
        ratio$chromEnd > RegionStart & ratio$chromStart < RegionEnd,
      , drop=FALSE
    ]
    ratio <- ratio[order(ratio$chromStart, ratio$chromEnd), , drop=FALSE]
    if(nrow(ratio) == 0){
      stop(
        "No ratio-table rows overlap ", Chromosome, ":", RegionStart, "-",
        RegionEnd, " for ", sample_label, "."
      )
    }
    ratio
  }

  EmptyPeakTable <- data.frame(
    chrom=character(), peakStart=numeric(), peakEnd=numeric(),
    peakSummit=numeric(), stringsAsFactors=FALSE
  )
  ReadPeaks <- function(file, sample_label){
    if(!file.exists(file)){
      warning(
        "No genomewide peak table was found for ", sample_label,
        "; collapsed peak overlays will be skipped."
      )
      return(EmptyPeakTable)
    }
    peaks <- data.table::fread(file, data.table=FALSE, showProgress=FALSE)
    lower <- tolower(names(peaks))
    chrom_col <- match(TRUE, lower %in% c("chrom", "chr"))
    start_col <- match(TRUE, lower %in% c("peakstart", "start"))
    end_col <- match(TRUE, lower %in% c("peakend", "end"))
    summit_col <- match(TRUE, lower %in% c("peaksummit", "summit", "abs_summit"))
    if(any(is.na(c(chrom_col, start_col, end_col)))){
      stop("Peak table does not contain chromosome, start, and end columns: ", file)
    }
    out <- data.frame(
      chrom=as.character(peaks[[chrom_col]]),
      peakStart=as.numeric(peaks[[start_col]]),
      peakEnd=as.numeric(peaks[[end_col]]),
      peakSummit=if(is.na(summit_col)){
        (as.numeric(peaks[[start_col]]) + as.numeric(peaks[[end_col]]))/2
      } else {
        as.numeric(peaks[[summit_col]])
      },
      stringsAsFactors=FALSE
    )
    out <- out[
      out$chrom == Chromosome & is.finite(out$peakStart) &
        is.finite(out$peakEnd) & out$peakEnd > RegionStart &
        out$peakStart < RegionEnd,
      , drop=FALSE
    ]
    out[order(out$peakStart, out$peakEnd), , drop=FALSE]
  }

  InferStep <- function(profile){
    starts <- sort(unique(profile$chromStart[is.finite(profile$chromStart)]))
    differences <- diff(utils::head(starts, 10000))
    differences <- differences[is.finite(differences) & differences > 0]
    if(length(differences) == 0) return(NA_real_)
    as.numeric(names(which.max(base::table(differences))))
  }

  message("Reading primary-analysis ratio table(s) for regional plotting...")
  Samples <- vector("list", NumberOfSamples)
  for(index in seq_len(NumberOfSamples)){
    ratio_folder <- if(Alignment[index] == "generic") "Ratios" else "Ratios_ma"
    peak_folder <- if(Alignment[index] == "generic") "Peaks" else "Peaks_ma"
    ratio_dir <- file.path(SampleDir[index], ratio_folder)
    if(!dir.exists(ratio_dir)){
      stop("Required ratio directory is missing for ", SampleLabels[index], ": ", ratio_dir)
    }

    if(StrandMode == "collapsed"){
      ratio_files <- c(collapsed=file.path(
        ratio_dir,
        paste0(SampleNames[index], "_", Assay[index], "_collapsed.bed")
      ))
    } else {
      ratio_files <- c(
        watson=file.path(
          ratio_dir, paste0(SampleNames[index], "_", Assay[index], "_watson.bed")
        ),
        crick=file.path(
          ratio_dir, paste0(SampleNames[index], "_", Assay[index], "_crick.bed")
        )
      )
    }
    missing_ratio_files <- ratio_files[!file.exists(ratio_files)]
    if(length(missing_ratio_files) > 0){
      stop(
        "Required ratio table(s) are missing for ", SampleLabels[index], ":\n",
        paste(missing_ratio_files, collapse="\n")
      )
    }

    if(StrandMode == "collapsed"){
      profile <- ReadRatio(ratio_files[["collapsed"]], SampleLabels[index])
      profile$plot_signal <- TransformSignal(profile$metric_value)
    } else {
      watson <- ReadRatio(ratio_files[["watson"]], SampleLabels[index])
      crick <- ReadRatio(ratio_files[["crick"]], SampleLabels[index])
      coordinates_match <- nrow(watson) == nrow(crick) &&
        identical(watson$chrom, crick$chrom) &&
        identical(watson$chromStart, crick$chromStart) &&
        identical(watson$chromEnd, crick$chromEnd)
      if(!coordinates_match){
        stop("Watson and Crick ratio-table coordinates do not match for ", SampleLabels[index], ".")
      }
      profile <- data.frame(
        chrom=watson$chrom,
        chromStart=watson$chromStart,
        chromEnd=watson$chromEnd,
        watson_signal=TransformSignal(watson$metric_value),
        crick_signal=TransformSignal(crick$metric_value),
        stringsAsFactors=FALSE
      )
    }

    peak_file <- if(DisplayPeaks){
      file.path(
        SampleDir[index], peak_folder,
        paste0(SampleNames[index], "_Genomewide_Peaks.bed")
      )
    } else {
      NA_character_
    }
    peaks <- if(DisplayPeaks){
      ReadPeaks(peak_file, SampleLabels[index])
    } else {
      EmptyPeakTable
    }

    Samples[[index]] <- list(
      sample_dir=SampleDir[index],
      sample_name=SampleNames[index],
      sample_label=SampleLabels[index],
      assay=Assay[index],
      alignment=Alignment[index],
      ratio_files=ratio_files,
      peak_file=peak_file,
      peaks=peaks,
      profile=profile,
      step=InferStep(profile)
    )
  }

  ReadFeature <- function(file, default_type){
    if(!file.exists(file)) stop("Missing genomic-element file: ", file)
    first_line <- readLines(file, n=1, warn=FALSE)
    fields <- strsplit(trimws(first_line), "\\s+")[[1]]
    has_header <- length(fields) >= 3 &&
      (is.na(suppressWarnings(as.numeric(fields[2]))) ||
       is.na(suppressWarnings(as.numeric(fields[3]))))
    features <- data.table::fread(
      file, header=has_header, data.table=FALSE, showProgress=FALSE
    )
    if(ncol(features) < 3){
      stop("Genomic-element file has fewer than 3 columns: ", file)
    }
    if(has_header){
      lower <- tolower(names(features))
      chrom_col <- match(TRUE, lower %in% c("chrom", "chr"))
      start_col <- match(TRUE, lower %in% c("chromstart", "start"))
      end_col <- match(TRUE, lower %in% c("chromend", "end"))
      name_col <- match(TRUE, lower %in% c("name", "orf", "gene", "feature"))
      score_col <- match(TRUE, lower %in% "score")
      strand_col <- match(TRUE, lower %in% "strand")
      type_col <- match(TRUE, lower %in% c("type", "featuretype"))
      stat_col <- match(TRUE, lower %in% c("stat", "status", "timing"))
    } else {
      chrom_col <- 1L
      start_col <- 2L
      end_col <- 3L
      name_col <- if(ncol(features) >= 4) 4L else NA_integer_
      score_col <- if(ncol(features) >= 5) 5L else NA_integer_
      strand_col <- if(ncol(features) >= 6) 6L else NA_integer_
      type_col <- if(ncol(features) >= 7) 7L else NA_integer_
      stat_col <- NA_integer_
    }
    if(any(is.na(c(chrom_col, start_col, end_col)))){
      stop("Could not identify genomic-element coordinates in: ", file)
    }
    out <- data.frame(
      chrom=as.character(features[[chrom_col]]),
      chromStart=as.numeric(features[[start_col]]),
      chromEnd=as.numeric(features[[end_col]]),
      name=if(is.na(name_col)) paste0(default_type, "_", seq_len(nrow(features)))
           else as.character(features[[name_col]]),
      score=if(is.na(score_col)) 0 else as.numeric(features[[score_col]]),
      strand=if(is.na(strand_col)) "." else as.character(features[[strand_col]]),
      type=if(is.na(type_col)) default_type else as.character(features[[type_col]]),
      stat=if(is.na(stat_col)) "" else as.character(features[[stat_col]]),
      stringsAsFactors=FALSE
    )
    out$strand[out$strand %in% c("1", "plus", "Plus", "Watson", "W")] <- "+"
    out$strand[out$strand %in% c("-1", "minus", "Minus", "Crick", "C")] <- "-"
    out$strand[!out$strand %in% c("+", "-", ".")] <- "."
    out <- out[
      out$chrom == Chromosome & is.finite(out$chromStart) &
        is.finite(out$chromEnd) & out$chromEnd > RegionStart &
        out$chromStart < RegionEnd,
      , drop=FALSE
    ]
    out[order(out$chromStart, out$chromEnd), , drop=FALSE]
  }

  ProjectPaths <- ChIP_BrDU_Project_Paths(check=TRUE)
  Annotations <- list(
    ORFs=ReadFeature(ProjectPaths$elements$orfs, "ORF"),
    ARS=ReadFeature(ProjectPaths$elements$ars, "ARS"),
    TER=ReadFeature(ProjectPaths$elements$termination_regions, "TER"),
    Ty=ReadFeature(ProjectPaths$elements$ty_elements, "Ty"),
    tRNA=ReadFeature(ProjectPaths$elements$trnas, "tRNA"),
    Centromeres=ReadFeature(ProjectPaths$elements$centromeres, "centromere")
  )

  MetricIsRatio <- Metric != "ip.score"
  BaselineValue <- if(DisplayLog2) 0 else if(MetricIsRatio) 1 else 0
  MetricLabels <- c(
    "ip.score"="IP coverage",
    "ratio.ipin"="IP / Input",
    "ratio.ipnoise"="IP / Noise",
    "ratio.ipin.noise"="(IP / Noise) / (Input / Noise)"
  )
  MetricShortLabels <- c(
    "ip.score"="IP coverage",
    "ratio.ipin"="IP/Input",
    "ratio.ipnoise"="IP/Noise",
    "ratio.ipin.noise"="clean enrichment"
  )
  TitleMetricLabel <- unname(MetricLabels[[Metric]])
  YLabel <- unname(MetricShortLabels[[Metric]])
  if(DisplayLog2){
    TitleMetricLabel <- paste0("log2(", TitleMetricLabel, ")")
    YLabel <- paste0("log2 ", YLabel)
  }
  if(StrandMode == "separated"){
    TitleMetricLabel <- paste0(TitleMetricLabel, " | W(+), C(-)")
    YLabel <- paste0(YLabel, " | W(+), C(-)")
  }

  GetThreshold <- function(values){
    values <- values[is.finite(values)]
    if(length(values) == 0) return(1)
    quantiles <- stats::quantile(values, probs=c(0.01, 0.99), na.rm=TRUE)
    iqr <- stats::IQR(values, na.rm=TRUE)
    trimmed <- values[
      values > quantiles[1] - 1.5*iqr & values < quantiles[2] + 1.5*iqr
    ]
    threshold <- if(length(trimmed) < 2){
      max(abs(values), na.rm=TRUE)
    } else {
      mean(trimmed, na.rm=TRUE) + YAxisScale*stats::sd(trimmed, na.rm=TRUE)
    }
    if(!is.finite(threshold) || threshold <= 0){
      threshold <- max(abs(values), na.rm=TRUE)
    }
    if(!is.finite(threshold) || threshold <= 0) threshold <- 1
    threshold
  }

  if(!is.null(y_val)){
    if(StrandMode == "collapsed"){
      if(DisplayLog2 && y_val <= Log2YMin){
        stop("For a collapsed log2 plot, y_val must be greater than Log2YMin.")
      }
      Ylim <- if(DisplayLog2) c(Log2YMin, y_val) else c(0, y_val)
    } else {
      Ylim <- c(-y_val, y_val)
    }
    YLimitSource <- "y_val"
  } else if(StrandMode == "collapsed"){
    values <- unlist(lapply(Samples, function(sample) sample$profile$plot_signal))
    y_max <- max(1, GetThreshold(values), na.rm=TRUE)
    if(DisplayLog2){
      Ylim <- c(Log2YMin, ceiling(y_max))
    } else {
      if(ShowBaseline) y_max <- max(y_max, BaselineValue*1.05)
      Ylim <- c(0, y_max)
    }
    YLimitSource <- "shared_internal"
  } else {
    values <- unlist(lapply(
      Samples,
      function(sample){
        c(sample$profile$watson_signal, sample$profile$crick_signal)
      }
    ))
    y_max <- ceiling(max(1, GetThreshold(abs(values)), na.rm=TRUE))
    if(MetricIsRatio) y_max <- max(y_max, 1.05)
    Ylim <- c(-y_max, y_max)
    YLimitSource <- "shared_internal"
  }
  YAxisTicks <- pretty(Ylim, n=5)
  YAxisTicks <- YAxisTicks[YAxisTicks >= min(Ylim) & YAxisTicks <= max(Ylim)]

  SafeSmooth <- function(x, y){
    ok <- is.finite(x) & is.finite(y)
    if(sum(ok) < 4 || length(unique(x[ok])) < 4 || length(unique(y[ok])) < 2){
      return(y)
    }
    model <- tryCatch(
      if(is.null(SmoothingSpar)) stats::smooth.spline(x[ok], y[ok])
      else stats::smooth.spline(x[ok], y[ok], spar=SmoothingSpar),
      error=function(e) NULL
    )
    if(is.null(model)) return(y)
    stats::predict(model, x)$y
  }

  PeakSupportedBars <- function(coverage, y_values, peaks){
    qualified <- rep(FALSE, nrow(coverage))
    positive <- is.finite(y_values) & y_values > 0
    if(!any(positive) || nrow(peaks) == 0) return(qualified)
    for(index in seq_len(nrow(peaks))){
      overlap <- positive & coverage$chromEnd >= peaks$peakStart[index] &
        coverage$chromStart <= peaks$peakEnd[index]
      if(!any(overlap)) next
      peak_height <- max(y_values[overlap], na.rm=TRUE)
      candidate <- positive &
        coverage$chromEnd >= peaks$peakStart[index] - 500 &
        coverage$chromStart <= peaks$peakEnd[index] + 500 &
        y_values >= peak_height*0.35
      if(!any(candidate)) next
      runs <- rle(candidate)
      run_end <- cumsum(runs$lengths)
      run_start <- run_end - runs$lengths + 1L
      for(run_index in seq_along(runs$values)){
        if(runs$values[run_index]){
          positions <- run_start[run_index]:run_end[run_index]
          if(any(overlap[positions])) qualified[positions] <- TRUE
        }
      }
    }
    qualified
  }

  PlotProfilePanel <- function(sample, show_strand_legend=FALSE){
    coverage <- sample$profile
    x <- coverage$chromStart
    x_end <- coverage$chromEnd
    y_range <- diff(Ylim)
    par(mar=ProfileMar)
    plot(
      NA, xlim=c(RegionStart, RegionEnd), ylim=Ylim, ylab="", xlab="",
      xaxt="n", yaxt="n", bty="n", xaxs="i"
    )

    if(StrandMode == "collapsed"){
      y <- coverage$plot_signal
      if(SmoothSignal) y <- SafeSmooth(x, y)
      if(PlotStyle == "lines"){
        lines(x, y, col=CollapsedSignalColor, lwd=ProfileLineLwd)
      } else {
        positive <- PeakSupportedBars(coverage, y, sample$peaks)
        colors <- ifelse(positive, PositiveSignalColor, NegativeSignalColor)
        segments(x, 0, x, y, col=colors, lwd=ProfileBarLwd)
      }
    } else {
      watson <- coverage$watson_signal
      crick <- coverage$crick_signal
      if(SmoothSignal){
        watson <- SafeSmooth(x, watson)
        crick <- SafeSmooth(x, crick)
      }
      watson[!is.finite(watson)] <- 0
      crick[!is.finite(crick)] <- 0
      watson <- pmax(watson, 0)
      crick <- -pmax(crick, 0)
      if(PlotStyle == "lines"){
        lines(x, watson, col=WatsonColor, lwd=ProfileLineLwd)
        lines(x, crick, col=CrickColor, lwd=ProfileLineLwd)
      } else {
        segments(x, 0, x, watson, col=WatsonColor, lwd=ProfileBarLwd)
        segments(x, 0, x, crick, col=CrickColor, lwd=ProfileBarLwd)
      }
      if(show_strand_legend){
        legend(
          "topright", legend=c("Watson", "Crick"),
          col=c(WatsonColor, CrickColor), lwd=2, bty="n", cex=0.72
        )
      }
    }
    segments(
      pmax(x, RegionStart), 0, pmin(x_end, RegionEnd), 0, lwd=0.25,
      col=grDevices::adjustcolor("gray40", alpha.f=0.35)
    )

    axis(
      2, at=YAxisTicks, labels=signif(YAxisTicks, 3), line=0,
      tick=TRUE, lwd.ticks=1.2, las=2, cex.axis=0.8
    )
    abline(
      h=YAxisTicks, lwd=0.05,
      col=grDevices::rgb(112, 128, 144, alpha=150, maxColorValue=255)
    )
    if(ShowBaseline){
      if(StrandMode == "separated"){
        abline(h=0, lwd=0.9, lty=3, col="gray20")
        if(MetricIsRatio){
          abline(h=c(-1, 1), lwd=0.7, lty=3, col="gray45")
        }
      } else if(BaselineValue >= min(Ylim) && BaselineValue <= max(Ylim)){
        abline(h=BaselineValue, lwd=0.9, lty=3, col="gray20")
      }
    }

    if(DisplayPeaks && nrow(sample$peaks) > 0){
      peak_x0 <- pmax(sample$peaks$peakStart, RegionStart)
      peak_x1 <- pmin(sample$peaks$peakEnd, RegionEnd)
      rect(
        peak_x0, max(Ylim) - 0.08*y_range,
        peak_x1, max(Ylim) - 0.015*y_range,
        col=grDevices::adjustcolor(PeakColor, alpha.f=0.35), border=NA
      )
    }

    if(nrow(Annotations$Centromeres) > 0){
      centers <- (Annotations$Centromeres$chromStart +
                    Annotations$Centromeres$chromEnd)/2
      segments(centers, min(Ylim), centers, max(Ylim),
               lwd=1.6, col="darkgreen")
      text(
        centers, max(Ylim) - 0.11*y_range, labels="CEN",
        cex=0.65, col="darkgreen", pos=4
      )
    }

    panel_title <- paste0(
      sample$sample_label, " | ", sample$assay, " | ", sample$alignment
    )
    title(main=panel_title, col="gray35", adj=0, cex.main=0.9, line=0.25)
    mtext(side=2, line=2.9, at=mean(Ylim), cex=0.8, YLabel)
    box(col="gray45")
  }

  DrawBlocks <- function(features, y, height, color, border){
    if(nrow(features) == 0) return(invisible(NULL))
    x0 <- pmax(features$chromStart, RegionStart)
    x1 <- pmin(features$chromEnd, RegionEnd)
    minimum_width <- max(1, RegionWidth/1800)
    too_small <- (x1 - x0) < minimum_width
    midpoint <- (x0 + x1)/2
    x0[too_small] <- midpoint[too_small] - minimum_width/2
    x1[too_small] <- midpoint[too_small] + minimum_width/2
    rect(x0, y-height, x1, y+height, col=color, border=border, lwd=0.4)
    invisible(NULL)
  }

  PlaceARSLabels <- function(x){
    if(length(x) == 0) return(integer())
    levels <- integer(length(x))
    last_x <- rep(-Inf, 3L)
    minimum_gap <- max(350, RegionWidth/18)
    for(index in order(x)){
      available <- which((x[index] - last_x) >= minimum_gap)
      level <- if(length(available) == 0) which.min(last_x) else available[1]
      levels[index] <- level - 1L
      last_x[level] <- x[index]
    }
    levels
  }

  PlotAnnotationTrack <- function(){
    par(mar=AnnotationMar)
    plot(
      NA, xlim=c(RegionStart, RegionEnd), ylim=c(0, 1.16),
      ylab="", xlab="", xaxt="n", yaxt="n", bty="n", xaxs="i", yaxs="i"
    )
    track_y <- c(ARS=1.00, `ORF+`=0.79, `ORF-`=0.64,
                 Ty=0.45, TER=0.28, tRNA=0.12)
    abline(
      h=unname(track_y), lwd=0.05,
      col=grDevices::rgb(112, 128, 144, alpha=150, maxColorValue=255)
    )

    if(nrow(Annotations$ARS) > 0){
      ars_x <- (Annotations$ARS$chromStart + Annotations$ARS$chromEnd)/2
      points(ars_x, rep(track_y[["ARS"]], length(ars_x)), pch=21,
             bg="yellow", col="purple", lwd=1.25, cex=0.95)
      label_levels <- PlaceARSLabels(ars_x)
      label_colors <- rep("gray15", nrow(Annotations$ARS))
      status <- tolower(Annotations$ARS$stat)
      label_colors[status == "early"] <- "red"
      label_colors[status == "late"] <- "blue"
      text(
        ars_x, 1.055 + 0.045*label_levels, labels=Annotations$ARS$name,
        cex=0.66, col=label_colors, xpd=NA
      )
    }

    if("ORF" %in% FeatureTracks && nrow(Annotations$ORFs) > 0){
      orfs <- Annotations$ORFs
      orfs$plotStart <- pmax(orfs$chromStart, RegionStart)
      orfs$plotEnd <- pmin(orfs$chromEnd, RegionEnd)
      orfs <- orfs[orfs$plotEnd > orfs$plotStart, , drop=FALSE]
      for(index in seq_len(nrow(orfs))){
        x0 <- orfs$plotStart[index]
        x1 <- orfs$plotEnd[index]
        plus <- orfs$strand[index] == "+"
        y <- if(plus) track_y[["ORF+"]] else track_y[["ORF-"]]
        color <- if(plus) "brown3" else "cornflowerblue"
        if((x1 - x0) < max(1, RegionWidth/1800)){
          segments(x0, y, x1, y, lwd=ORFLwd, col=color)
        } else if(plus){
          suppressWarnings(arrows(
            x0, y, x1, y, length=0.04, angle=25, code=2,
            lwd=ORFLwd, col=color
          ))
        } else {
          suppressWarnings(arrows(
            x1, y, x0, y, length=0.04, angle=25, code=2,
            lwd=ORFLwd, col=color
          ))
        }
      }
    }
    if("Ty" %in% FeatureTracks){
      DrawBlocks(
        Annotations$Ty, track_y[["Ty"]], 0.045,
        grDevices::adjustcolor("mediumpurple3", alpha.f=0.75), "mediumpurple4"
      )
    }
    if("TER" %in% FeatureTracks){
      DrawBlocks(
        Annotations$TER, track_y[["TER"]], 0.045,
        grDevices::adjustcolor("orange2", alpha.f=0.65), "orange4"
      )
    }
    if("tRNA" %in% FeatureTracks){
      DrawBlocks(
        Annotations$tRNA, track_y[["tRNA"]], 0.038,
        grDevices::adjustcolor("seagreen3", alpha.f=0.75), "seagreen4"
      )
    }

    axis(
      2, at=unname(track_y), labels=names(track_y), line=0,
      tick=TRUE, lwd.ticks=1, las=2, cex.axis=0.72
    )
    coordinate_ticks <- pretty(c(RegionStart, RegionEnd), n=6)
    coordinate_ticks <- coordinate_ticks[
      coordinate_ticks >= RegionStart & coordinate_ticks <= RegionEnd
    ]
    coordinate_labels <- format(
      round(coordinate_ticks/1000, 3), trim=TRUE, scientific=FALSE
    )
    axis(
      1, at=coordinate_ticks, labels=coordinate_labels,
      line=0, tick=FALSE, cex.axis=0.8
    )
    title(
      xlab=paste0(Chromosome, " coordinates (Kbp)"),
      col="gray30", cex.lab=0.88, line=0.95
    )
    box(col="gray45")
  }

  PlotLegendSpacer <- function(){
    par(mar=c(0, 0, 0, 0))
    plot(
      NA, xlim=c(0, 1), ylim=c(0, 1), axes=FALSE,
      xlab="", ylab="", bty="n", xaxs="i", yaxs="i"
    )
    if(DisplayPeaks){
      rect(
        0.40, 0.49, 0.435, 0.59,
        col=grDevices::adjustcolor(PeakColor, alpha.f=0.35), border=NA
      )
      text(0.45, 0.54, "sample-specific peaks", adj=0, cex=0.74, col="gray25")
    } else {
      points(0.46, 0.54, pch=21, bg="yellow", col="purple", lwd=1.2, cex=0.9)
      text(0.48, 0.54, "ARS", adj=0, cex=0.74, col="gray25")
    }
  }

  PlotBlankProfile <- function(){
    par(mar=ProfileMar)
    plot(
      NA, xlim=c(RegionStart, RegionEnd), ylim=Ylim,
      axes=FALSE, xlab="", ylab="", bty="n", xaxs="i"
    )
  }

  SanitizeFilename <- function(x){
    x <- gsub("[^A-Za-z0-9._-]+", "_", x)
    x <- gsub("_+", "_", x)
    sub("^_+|_+$", "", x)
  }
  sample_tag <- if(NumberOfSamples == 1L){
    SanitizeFilename(SampleNames[[1]])
  } else {
    candidate <- paste(SanitizeFilename(SampleLabels), collapse="_vs_")
    if(nchar(candidate) <= 120) candidate else paste0("comparison_", NumberOfSamples, "samples")
  }
  assay_tag <- if(length(unique(Assay)) == 1L) unique(Assay) else "mixed_assay"
  alignment_tag <- if(length(unique(Alignment)) == 1L){
    unique(Alignment)
  } else {
    "mixed_alignment"
  }
  metric_suffix <- gsub("\\.", "_", Metric)
  log_suffix <- if(DisplayLog2) "log2_" else ""
  coordinate_tag <- paste0(
    format(RegionStart, scientific=FALSE, trim=TRUE), "-",
    format(RegionEnd, scientific=FALSE, trim=TRUE)
  )
  OutputFile <- file.path(
    OutputDir,
    paste0(
      sample_tag, "_", assay_tag, "_", alignment_tag, "_", StrandMode, "_",
      Chromosome, "_", coordinate_tag, "_", log_suffix, metric_suffix,
      "_region.pdf"
    )
  )

  PageCount <- ceiling(NumberOfSamples/PanelsPerPage)
  PanelSlots <- min(PanelsPerPage, NumberOfSamples)
  PdfHeight <- max(6.5, min(11.5, 3.0 + 2.1*PanelSlots))
  grDevices::pdf(
    OutputFile, width=PdfWidth, height=PdfHeight, useDingbats=FALSE
  )
  on.exit(grDevices::dev.off(), add=TRUE)

  for(page in seq_len(PageCount)){
    page_start <- (page-1L)*PanelsPerPage + 1L
    page_end <- min(page*PanelsPerPage, NumberOfSamples)
    page_indexes <- page_start:page_end
    layout(
      matrix(seq_len(PanelSlots+2L), ncol=1),
      heights=c(rep(3.1, PanelSlots), 1.65, 0.45)
    )
    par(oma=OuterMar)
    for(slot in seq_len(PanelSlots)){
      if(slot <= length(page_indexes)){
        PlotProfilePanel(
          Samples[[page_indexes[slot]]],
          show_strand_legend=StrandMode == "separated" && slot == 1L
        )
      } else {
        PlotBlankProfile()
      }
    }
    PlotAnnotationTrack()
    PlotLegendSpacer()
    page_suffix <- if(PageCount > 1L) paste0(" | page ", page, "/", PageCount) else ""
    mtext(
      paste0(
        "Regional ", TitleMetricLabel, " | ", Chromosome, ":",
        format(RegionStart, scientific=FALSE, trim=TRUE), "-",
        format(RegionEnd, scientific=FALSE, trim=TRUE),
        " | ", StrandMode, page_suffix
      ),
      outer=TRUE, side=3, line=1.25, cex=0.95, col="gray35"
    )
  }

  message("Regional plot saved: ", OutputFile)
  invisible(list(
    pdf=OutputFile,
    sample_dir=SampleDir,
    sample_name=SampleNames,
    sample_labels=SampleLabels,
    assay=Assay,
    alignment=Alignment,
    strand_mode=StrandMode,
    metric=Metric,
    chromosome=Chromosome,
    region=c(start=RegionStart, end=RegionEnd),
    ratio_files=lapply(Samples, function(sample) sample$ratio_files),
    peak_files=vapply(Samples, function(sample) sample$peak_file, character(1)),
    peak_visualization=DisplayPeaks,
    log2_profile=DisplayLog2,
    steps=vapply(Samples, function(sample) sample$step, numeric(1)),
    y_val=y_val,
    y_limits=Ylim,
    y_limit_source=YLimitSource,
    panels_per_page=PanelsPerPage,
    page_count=PageCount,
    primary_output_only=TRUE,
    plotter_operations=c(
      simulation=FALSE,
      noise_estimation=FALSE,
      signal_filtering=FALSE,
      ratio_recalculation=FALSE,
      peak_calling=FALSE,
      pvalue_thresholding=FALSE
    ),
    display_operations=c(
      spline_smoothing=SmoothSignal,
      collapsed_log2=DisplayLog2,
      crick_mirroring=StrandMode == "separated",
      shared_comparison_scale=NumberOfSamples > 1L
    )
  ))
}

## Direct collapsed ChIP-BrDU regional enrichment comparison. This function is
## intentionally separate from ChIP_BrDU_Region_Plotter: one explicitly
## supplied ChIP sample and one explicitly supplied BrDU sample are overlaid in
## a single regional profile panel with independent, baseline-aligned y-axes.
## RegionStart and RegionEnd retain the zero-based, half-open convention used by
## the primary-analysis BED ratio tables.
##
## Only final collapsed ratio tables are read. The two regional coordinate grids
## must match exactly. ChIP is drawn as a solid line against the left axis and
## BrDU as a dotted line against the right axis. Peak files are neither read nor
## displayed because independent ChIP and BrDU peak calls would obscure the
## paired signal comparison. The shared project-local ARS, ORF, Ty, TER, tRNA,
## and centromere annotations follow the established regional plotter.
##
## Log2Profile=FALSE preserves untransformed values. Log2Profile=TRUE uses
## log2(1+x) for coverage and log2(x) for positive ratio values; non-positive
## ratios remain unavailable. Spline smoothing and log transformation are
## display-only. y_val_chip and y_val_brdu optionally set separate upper limits;
## their defaults retain automatic baseline-aligned calculation.
##
## Example:
## ChIP_BrDU_Region_Comparison_Plotter(
##   ChIPSampleDir="/path/to/sample-ChIP",
##   BrDUSampleDir="/path/to/sample-BrDU",
##   Chromosome="chrIV",
##   RegionStart=400000,
##   RegionEnd=500000,
##   Alignment="generic",
##   Metric="ratio.ipin.noise",
##   Log2Profile=FALSE
## )
ChIP_BrDU_Region_Comparison_Plotter <- function(
    ChIPSampleDir,
    BrDUSampleDir,
    Chromosome,
    RegionStart,
    RegionEnd,
    Alignment=c("generic", "malign"),
    Metric=c(
      "ratio.ipin.noise", "ratio.ipin", "ratio.ipnoise", "ip.score"
    ),
    Log2Profile=FALSE,
    y_val_chip=NULL,
    y_val_brdu=NULL,
    OutputDir=NULL){

  MetricLabels <- c(
    ip.score="Coverage",
    ratio.ipin="Enrichment over input",
    ratio.ipnoise="Enrichment over noise",
    ratio.ipin.noise="Clean enrichment"
  )
  RawBaselines <- c(
    ip.score=0,
    ratio.ipin=1,
    ratio.ipnoise=1,
    ratio.ipin.noise=1
  )
  ChromosomeInfo <- data.frame(
    chrom=c(
      "chrI", "chrII", "chrIII", "chrIV", "chrV", "chrVI", "chrVII",
      "chrVIII", "chrIX", "chrX", "chrXI", "chrXII", "chrXIII",
      "chrXIV", "chrXV", "chrXVI", "chrM"
    ),
    length=c(
      230218, 813184, 316620, 1531933, 576874, 270161, 1090940,
      562643, 439888, 745751, 666816, 1078177, 924431, 784333,
      1091291, 948066, 85779
    ),
    stringsAsFactors=FALSE
  )
  FeatureTracks <- c("ORF", "Ty", "TER", "tRNA")
  ChIPColor <- "darkorchid4"
  BrDUColor <- "darkorange3"
  BaselineColor <- "gray45"
  ORFLwd <- 2.5
  SmoothingSpar <- NULL
  PdfWidth <- 11
  PdfHeight <- 7.5
  ProfileMar <- c(0.65, 5.1, 1.65, 5.1)
  AnnotationMar <- c(2.7, 5.1, 0.35, 5.1)
  OuterMar <- c(2.1, 1.0, 3.15, 1.0)

  Alignment <- match.arg(Alignment)
  Metric <- match.arg(Metric)
  if(!is.logical(Log2Profile) || length(Log2Profile) != 1L ||
     is.na(Log2Profile)){
    stop("Log2Profile must be TRUE or FALSE.", call.=FALSE)
  }
  MetricIsRatio <- Metric != "ip.score"
  BaselineValue <- if(Log2Profile) 0 else RawBaselines[[Metric]]
  ScaleTag <- if(Log2Profile) "log2" else "linear"
  ScaleLabel <- if(Log2Profile){
    "log2 display"
  } else {
    "untransformed display"
  }

  ValidateSampleDir <- function(path, label){
    if(length(path) != 1L || !is.character(path) || is.na(path) ||
       !nzchar(path)){
      stop(label, " must be one existing sample directory.", call.=FALSE)
    }
    if(!dir.exists(path)){
      stop(label, " does not exist: ", path, call.=FALSE)
    }
    normalizePath(path, winslash="/", mustWork=TRUE)
  }
  ChIPSampleDir <- ValidateSampleDir(ChIPSampleDir, "ChIPSampleDir")
  BrDUSampleDir <- ValidateSampleDir(BrDUSampleDir, "BrDUSampleDir")
  ChIPSampleName <- basename(ChIPSampleDir)
  BrDUSampleName <- basename(BrDUSampleDir)

  ResolveChromosome <- function(chromosome){
    if(length(chromosome) != 1L || is.na(chromosome)){
      stop("Chromosome must identify exactly one chromosome.", call.=FALSE)
    }
    ChromosomeText <- as.character(chromosome)
    if(grepl("^[0-9]+$", ChromosomeText)){
      Index <- as.integer(ChromosomeText)
    } else {
      Stripped <- sub("^chr", "", ChromosomeText, ignore.case=TRUE)
      Index <- match(
        toupper(Stripped),
        toupper(sub("^chr", "", ChromosomeInfo$chrom))
      )
    }
    if(is.na(Index) || Index < 1L || Index > nrow(ChromosomeInfo)){
      stop("Could not resolve chromosome: ", ChromosomeText, call.=FALSE)
    }
    ChromosomeInfo[Index, , drop=FALSE]
  }
  ChromosomeRecord <- ResolveChromosome(Chromosome)
  Chromosome <- ChromosomeRecord$chrom[[1]]
  ChromosomeLength <- ChromosomeRecord$length[[1]]
  if(!is.numeric(RegionStart) || length(RegionStart) != 1L ||
     !is.finite(RegionStart) || RegionStart < 0){
    stop(
      "RegionStart must be one finite, non-negative coordinate.",
      call.=FALSE
    )
  }
  if(!is.numeric(RegionEnd) || length(RegionEnd) != 1L ||
     !is.finite(RegionEnd) || RegionEnd <= RegionStart){
    stop(
      "RegionEnd must be one finite coordinate greater than RegionStart.",
      call.=FALSE
    )
  }
  if(RegionEnd > ChromosomeLength){
    stop(
      "RegionEnd exceeds ", Chromosome, " length (",
      ChromosomeLength, " bp).",
      call.=FALSE
    )
  }
  RegionStart <- as.numeric(RegionStart)
  RegionEnd <- as.numeric(RegionEnd)
  RegionWidth <- RegionEnd-RegionStart

  ValidateYValue <- function(value, label){
    if(is.null(value)){
      return(NULL)
    }
    if(!is.numeric(value) || length(value) != 1L ||
       !is.finite(value)){
      stop(
        label, " must be NULL or one finite numeric upper limit.",
        call.=FALSE
      )
    }
    if(value <= BaselineValue){
      stop(
        label,
        " must be greater than the displayed neutral baseline (",
        BaselineValue, ").",
        call.=FALSE
      )
    }
    as.numeric(value)
  }
  y_val_chip <- ValidateYValue(y_val_chip, "y_val_chip")
  y_val_brdu <- ValidateYValue(y_val_brdu, "y_val_brdu")

  if(is.null(OutputDir)){
    ParentDirs <- unique(dirname(c(ChIPSampleDir, BrDUSampleDir)))
    OutputDir <- if(length(ParentDirs) == 1L){
      ParentDirs[[1]]
    } else {
      ChIPSampleDir
    }
  }
  if(length(OutputDir) != 1L || !is.character(OutputDir) ||
     is.na(OutputDir) || !nzchar(OutputDir)){
    stop("OutputDir must be NULL or one directory path.", call.=FALSE)
  }
  if(!dir.exists(OutputDir)){
    dir.create(OutputDir, recursive=TRUE, showWarnings=FALSE)
  }
  if(!dir.exists(OutputDir)){
    stop("Could not create OutputDir: ", OutputDir, call.=FALSE)
  }
  OutputDir <- normalizePath(OutputDir, winslash="/", mustWork=TRUE)

  if(!requireNamespace("data.table", quietly=TRUE)){
    stop(
      "The data.table package is required to read paired regional ratio tables efficiently.",
      call.=FALSE
    )
  }

  RatioFolder <- if(Alignment == "generic") "Ratios" else "Ratios_ma"
  RatioFiles <- c(
    ChIP=file.path(
      ChIPSampleDir,
      RatioFolder,
      paste0(ChIPSampleName, "_ChIP_collapsed.bed")
    ),
    BrDU=file.path(
      BrDUSampleDir,
      RatioFolder,
      paste0(BrDUSampleName, "_BrDU_collapsed.bed")
    )
  )
  MissingRatioFiles <- RatioFiles[!file.exists(RatioFiles)]
  if(length(MissingRatioFiles) > 0L){
    stop(
      "Required primary-analysis ratio table(s) are missing:\n",
      paste(MissingRatioFiles, collapse="\n"),
      call.=FALSE
    )
  }

  InferStep <- function(Profile){
    Starts <- sort(unique(Profile$chromStart[is.finite(Profile$chromStart)]))
    Differences <- diff(Starts)
    Differences <- Differences[
      is.finite(Differences) & Differences > 0
    ]
    if(length(Differences) == 0L){
      return(NA_real_)
    }
    as.numeric(names(which.max(base::table(Differences))))
  }
  ReadRatio <- function(file, assay_label){
    Header <- names(data.table::fread(
      file,
      header=TRUE,
      sep="\t",
      nrows=0L,
      showProgress=FALSE,
      data.table=TRUE
    ))
    RequiredColumns <- c("chrom", "chromStart", "chromEnd", Metric)
    MissingColumns <- setdiff(RequiredColumns, Header)
    if(length(MissingColumns) > 0L){
      stop(
        assay_label, " ratio table is missing required column(s): ",
        paste(MissingColumns, collapse=", "), "\n", file,
        call.=FALSE
      )
    }
    Ratio <- data.table::fread(
      file,
      header=TRUE,
      sep="\t",
      select=RequiredColumns,
      showProgress=FALSE,
      data.table=FALSE
    )
    names(Ratio)[names(Ratio) == Metric] <- "metric_value"
    Ratio$chrom <- as.character(Ratio$chrom)
    Ratio$chromStart <- suppressWarnings(as.numeric(Ratio$chromStart))
    Ratio$chromEnd <- suppressWarnings(as.numeric(Ratio$chromEnd))
    Ratio$metric_value <- suppressWarnings(
      as.numeric(Ratio$metric_value)
    )
    Ratio <- Ratio[
      Ratio$chrom == Chromosome &
        is.finite(Ratio$chromStart) &
        is.finite(Ratio$chromEnd) &
        Ratio$chromEnd > RegionStart &
        Ratio$chromStart < RegionEnd,
      ,
      drop=FALSE
    ]
    Ratio <- Ratio[
      order(Ratio$chromStart, Ratio$chromEnd),
      ,
      drop=FALSE
    ]
    if(nrow(Ratio) == 0L){
      stop(
        "No ratio-table rows overlap ", Chromosome, ":",
        RegionStart, "-", RegionEnd, " for ", assay_label, ".",
        call.=FALSE
      )
    }
    if(any(!is.finite(Ratio$metric_value))){
      stop(
        assay_label,
        " ratio table contains a non-finite metric value in the selected region: ",
        file,
        call.=FALSE
      )
    }
    if(anyDuplicated(Ratio[, c("chrom", "chromStart")])){
      stop(
        assay_label,
        " ratio table contains duplicated regional chrom/chromStart coordinates: ",
        file,
        call.=FALSE
      )
    }
    Ratio
  }

  Profiles <- list(
    ChIP=ReadRatio(RatioFiles[["ChIP"]], "ChIP"),
    BrDU=ReadRatio(RatioFiles[["BrDU"]], "BrDU")
  )
  CoordinatesMatch <-
    nrow(Profiles$ChIP) == nrow(Profiles$BrDU) &&
    identical(Profiles$ChIP$chrom, Profiles$BrDU$chrom) &&
    identical(Profiles$ChIP$chromStart, Profiles$BrDU$chromStart) &&
    identical(Profiles$ChIP$chromEnd, Profiles$BrDU$chromEnd)
  if(!CoordinatesMatch){
    stop(
      "ChIP and BrDU regional ratio-table coordinates do not match exactly.",
      call.=FALSE
    )
  }
  Steps <- vapply(Profiles, InferStep, numeric(1))
  FiniteSteps <- Steps[is.finite(Steps)]
  if(length(FiniteSteps) > 1L &&
     any(abs(FiniteSteps-FiniteSteps[[1]]) >
         sqrt(.Machine$double.eps))){
    stop(
      "ChIP and BrDU regional ratio tables do not use the same step.",
      call.=FALSE
    )
  }
  BinWidths <- vapply(
    Profiles,
    function(Profile){
      Widths <- Profile$chromEnd-Profile$chromStart
      as.numeric(names(which.max(base::table(Widths))))
    },
    numeric(1)
  )

  TransformSignal <- function(values){
    Values <- suppressWarnings(as.numeric(values))
    if(!Log2Profile){
      return(Values)
    }
    Transformed <- rep(NA_real_, length(Values))
    Finite <- is.finite(Values)
    if(Metric == "ip.score"){
      NonNegative <- Finite & Values >= 0
      Transformed[NonNegative] <- log2(1+Values[NonNegative])
    } else {
      Positive <- Finite & Values > 0
      Transformed[Positive] <- log2(Values[Positive])
    }
    Transformed
  }
  SafeSmooth <- function(x, y){
    Smoothed <- rep(NA_real_, length(y))
    Good <- which(is.finite(x) & is.finite(y))
    if(length(Good) < 4L ||
       length(unique(x[Good])) < 4L ||
       length(unique(y[Good])) < 2L){
      Smoothed[Good] <- y[Good]
      return(Smoothed)
    }
    Fit <- tryCatch(
      if(is.null(SmoothingSpar)){
        stats::smooth.spline(x[Good], y[Good])
      } else {
        stats::smooth.spline(
          x[Good],
          y[Good],
          spar=SmoothingSpar
        )
      },
      error=function(error) NULL
    )
    if(is.null(Fit)){
      Smoothed[Good] <- y[Good]
    } else {
      Smoothed[Good] <- Fit$y
    }
    Smoothed
  }
  BuildDisplayProfile <- function(Profile){
    Display <- Profile
    Display$plot_signal <- SafeSmooth(
      Display$chromStart,
      TransformSignal(Display$metric_value)
    )
    Display
  }
  DisplayProfiles <- lapply(Profiles, BuildDisplayProfile)
  DisplayValues <- lapply(
    DisplayProfiles,
    function(Profile) Profile$plot_signal
  )

  AutomaticLimits <- function(values){
    Values <- values[is.finite(values)]
    if(length(Values) == 0L){
      stop(
        "No finite regional values remain for automatic y-axis calculation.",
        call.=FALSE
      )
    }
    Lower <- min(c(Values, BaselineValue))
    Upper <- max(c(Values, BaselineValue))
    Span <- Upper-Lower
    if(!is.finite(Span) || Span == 0){
      Span <- max(0.5, abs(Upper)*0.10)
    }
    Lower <- Lower-0.08*Span
    Upper <- Upper+0.08*Span
    if(BaselineValue == 0 && all(Values >= 0)){
      Lower <- 0
    }
    c(Lower, Upper)
  }
  AlignLimitsAtBaseline <- function(ChIPLimits, BrDULimits){
    BaselineFraction <- function(Limits){
      (BaselineValue-Limits[[1]])/diff(Limits)
    }
    Fractions <- c(
      ChIP=BaselineFraction(ChIPLimits),
      BrDU=BaselineFraction(BrDULimits)
    )
    TargetFraction <- max(Fractions)
    if(!is.finite(TargetFraction) ||
       TargetFraction <= sqrt(.Machine$double.eps) ||
       TargetFraction >= 1-sqrt(.Machine$double.eps)){
      return(list(ChIP=ChIPLimits, BrDU=BrDULimits))
    }
    ExpandLower <- function(Limits, fraction){
      if(fraction+sqrt(.Machine$double.eps) >= TargetFraction){
        return(Limits)
      }
      NewLower <- (
        BaselineValue-TargetFraction*Limits[[2]]
      )/(1-TargetFraction)
      Limits[[1]] <- min(Limits[[1]], NewLower)
      Limits
    }
    list(
      ChIP=ExpandLower(ChIPLimits, Fractions[["ChIP"]]),
      BrDU=ExpandLower(BrDULimits, Fractions[["BrDU"]])
    )
  }

  ChIPLimits <- AutomaticLimits(DisplayValues$ChIP)
  BrDULimits <- AutomaticLimits(DisplayValues$BrDU)
  ChIPLimitSource <- "automatic"
  BrDULimitSource <- "automatic"
  if(!is.null(y_val_chip)){
    ChIPLimits[[2]] <- y_val_chip
    ChIPLimitSource <- "y_val_chip"
  }
  if(!is.null(y_val_brdu)){
    BrDULimits[[2]] <- y_val_brdu
    BrDULimitSource <- "y_val_brdu"
  }
  if(ChIPLimits[[2]] <= ChIPLimits[[1]]){
    ChIPLimits[[1]] <- min(
      BaselineValue,
      ChIPLimits[[2]]-0.5
    )
  }
  if(BrDULimits[[2]] <= BrDULimits[[1]]){
    BrDULimits[[1]] <- min(
      BaselineValue,
      BrDULimits[[2]]-0.5
    )
  }
  YLimits <- AlignLimitsAtBaseline(ChIPLimits, BrDULimits)
  ChIPFinite <- DisplayValues$ChIP[is.finite(DisplayValues$ChIP)]
  BrDUFinite <- DisplayValues$BrDU[is.finite(DisplayValues$BrDU)]
  YLimitTable <- data.table::data.table(
    metric=Metric,
    baseline=BaselineValue,
    chip_lower=YLimits$ChIP[[1]],
    chip_upper=YLimits$ChIP[[2]],
    brdu_lower=YLimits$BrDU[[1]],
    brdu_upper=YLimits$BrDU[[2]],
    chip_source=ChIPLimitSource,
    brdu_source=BrDULimitSource,
    chip_clipped_low=sum(ChIPFinite < YLimits$ChIP[[1]]),
    chip_clipped_high=sum(ChIPFinite > YLimits$ChIP[[2]]),
    brdu_clipped_low=sum(BrDUFinite < YLimits$BrDU[[1]]),
    brdu_clipped_high=sum(BrDUFinite > YLimits$BrDU[[2]])
  )

  ProjectPaths <- ChIP_BrDU_Project_Paths(check=TRUE)
  AnnotationFiles <- c(
    ORFs=ProjectPaths$elements$orfs,
    ARS=ProjectPaths$elements$ars,
    TER=ProjectPaths$elements$termination_regions,
    Ty=ProjectPaths$elements$ty_elements,
    tRNA=ProjectPaths$elements$trnas,
    Centromeres=ProjectPaths$elements$centromeres
  )
  ReadFeature <- function(file, default_type){
    if(!file.exists(file)){
      stop("Missing genomic-element file: ", file, call.=FALSE)
    }
    FirstLine <- readLines(file, n=1L, warn=FALSE)
    Fields <- strsplit(trimws(FirstLine), "\\s+")[[1]]
    HasHeader <- length(Fields) >= 3L &&
      (is.na(suppressWarnings(as.numeric(Fields[[2]]))) ||
       is.na(suppressWarnings(as.numeric(Fields[[3]]))))
    Features <- data.table::fread(
      file,
      header=HasHeader,
      showProgress=FALSE,
      data.table=FALSE
    )
    if(ncol(Features) < 3L){
      stop(
        "Genomic-element file has fewer than 3 columns: ",
        file,
        call.=FALSE
      )
    }
    if(HasHeader){
      Lower <- tolower(names(Features))
      ChromColumn <- match(TRUE, Lower %in% c("chrom", "chr"))
      StartColumn <- match(TRUE, Lower %in% c("chromstart", "start"))
      EndColumn <- match(TRUE, Lower %in% c("chromend", "end"))
      NameColumn <- match(
        TRUE,
        Lower %in% c("name", "orf", "gene", "feature")
      )
      ScoreColumn <- match(TRUE, Lower %in% "score")
      StrandColumn <- match(TRUE, Lower %in% "strand")
      TypeColumn <- match(TRUE, Lower %in% c("type", "featuretype"))
      StatColumn <- match(TRUE, Lower %in% c("stat", "status", "timing"))
    } else {
      ChromColumn <- 1L
      StartColumn <- 2L
      EndColumn <- 3L
      NameColumn <- if(ncol(Features) >= 4L) 4L else NA_integer_
      ScoreColumn <- if(ncol(Features) >= 5L) 5L else NA_integer_
      StrandColumn <- if(ncol(Features) >= 6L) 6L else NA_integer_
      TypeColumn <- if(ncol(Features) >= 7L) 7L else NA_integer_
      StatColumn <- NA_integer_
    }
    if(any(is.na(c(ChromColumn, StartColumn, EndColumn)))){
      stop(
        "Could not identify genomic-element coordinates in: ",
        file,
        call.=FALSE
      )
    }
    Output <- data.frame(
      chrom=as.character(Features[[ChromColumn]]),
      chromStart=suppressWarnings(
        as.numeric(Features[[StartColumn]])
      ),
      chromEnd=suppressWarnings(
        as.numeric(Features[[EndColumn]])
      ),
      name=if(is.na(NameColumn)){
        paste0(default_type, "_", seq_len(nrow(Features)))
      } else {
        as.character(Features[[NameColumn]])
      },
      score=if(is.na(ScoreColumn)){
        0
      } else {
        suppressWarnings(as.numeric(Features[[ScoreColumn]]))
      },
      strand=if(is.na(StrandColumn)){
        "."
      } else {
        as.character(Features[[StrandColumn]])
      },
      type=if(is.na(TypeColumn)){
        default_type
      } else {
        as.character(Features[[TypeColumn]])
      },
      stat=if(is.na(StatColumn)){
        ""
      } else {
        as.character(Features[[StatColumn]])
      },
      stringsAsFactors=FALSE
    )
    Output$strand[
      Output$strand %in% c("1", "plus", "Plus", "Watson", "W")
    ] <- "+"
    Output$strand[
      Output$strand %in% c("-1", "minus", "Minus", "Crick", "C")
    ] <- "-"
    Output$strand[
      !Output$strand %in% c("+", "-", ".")
    ] <- "."
    Output <- Output[
      Output$chrom == Chromosome &
        is.finite(Output$chromStart) &
        is.finite(Output$chromEnd) &
        Output$chromEnd > RegionStart &
        Output$chromStart < RegionEnd,
      ,
      drop=FALSE
    ]
    Output[
      order(Output$chromStart, Output$chromEnd),
      ,
      drop=FALSE
    ]
  }
  Annotations <- list(
    ORFs=ReadFeature(AnnotationFiles[["ORFs"]], "ORF"),
    ARS=ReadFeature(AnnotationFiles[["ARS"]], "ARS"),
    TER=ReadFeature(AnnotationFiles[["TER"]], "TER"),
    Ty=ReadFeature(AnnotationFiles[["Ty"]], "Ty"),
    tRNA=ReadFeature(AnnotationFiles[["tRNA"]], "tRNA"),
    Centromeres=ReadFeature(
      AnnotationFiles[["Centromeres"]],
      "centromere"
    )
  )
  AnnotationCounts <- vapply(Annotations, nrow, integer(1))

  DisplayMetricLabel <- function(){
    Label <- MetricLabels[[Metric]]
    if(!Log2Profile){
      return(Label)
    }
    if(Metric == "ip.score"){
      paste0("log2(1 + ", Label, ")")
    } else {
      paste0("log2(", Label, ")")
    }
  }
  DrawBlocks <- function(features, y, height, color, border){
    if(nrow(features) == 0L){
      return(invisible(NULL))
    }
    XStart <- pmax(features$chromStart, RegionStart)
    XEnd <- pmin(features$chromEnd, RegionEnd)
    MinimumWidth <- max(1, RegionWidth/1800)
    TooSmall <- (XEnd-XStart) < MinimumWidth
    Midpoint <- (XStart+XEnd)/2
    XStart[TooSmall] <- Midpoint[TooSmall]-MinimumWidth/2
    XEnd[TooSmall] <- Midpoint[TooSmall]+MinimumWidth/2
    graphics::rect(
      XStart,
      y-height,
      XEnd,
      y+height,
      col=color,
      border=border,
      lwd=0.4
    )
    invisible(NULL)
  }
  PlaceARSLabels <- function(x){
    if(length(x) == 0L){
      return(integer())
    }
    Levels <- integer(length(x))
    LastX <- rep(-Inf, 3L)
    MinimumGap <- max(350, RegionWidth/18)
    for(Index in order(x)){
      Available <- which((x[[Index]]-LastX) >= MinimumGap)
      Level <- if(length(Available) == 0L){
        which.min(LastX)
      } else {
        Available[[1]]
      }
      Levels[[Index]] <- Level-1L
      LastX[[Level]] <- x[[Index]]
    }
    Levels
  }

  PlotComparisonPanel <- function(){
    ChIPProfile <- DisplayProfiles$ChIP
    BrDUProfile <- DisplayProfiles$BrDU
    X <- ChIPProfile$chromStart
    ChIPTicks <- pretty(YLimits$ChIP, n=5)
    ChIPTicks <- ChIPTicks[
      ChIPTicks >= YLimits$ChIP[[1]] &
      ChIPTicks <= YLimits$ChIP[[2]]
    ]
    BrDUTicks <- pretty(YLimits$BrDU, n=5)
    BrDUTicks <- BrDUTicks[
      BrDUTicks >= YLimits$BrDU[[1]] &
      BrDUTicks <= YLimits$BrDU[[2]]
    ]

    graphics::par(mar=ProfileMar)
    graphics::plot(
      NA,
      xlim=c(RegionStart, RegionEnd),
      ylim=YLimits$ChIP,
      axes=FALSE,
      xlab="",
      ylab="",
      bty="n",
      xaxs="i",
      yaxs="i"
    )
    graphics::abline(
      h=ChIPTicks,
      lwd=0.05,
      col=grDevices::rgb(
        112,
        128,
        144,
        alpha=150,
        maxColorValue=255
      )
    )
    graphics::abline(
      h=BaselineValue,
      lwd=0.9,
      lty=3,
      col=BaselineColor
    )
    graphics::lines(
      X,
      ChIPProfile$plot_signal,
      col=ChIPColor,
      lty=1,
      lwd=2
    )
    graphics::axis(
      2,
      at=ChIPTicks,
      labels=signif(ChIPTicks, 3),
      las=1,
      cex.axis=0.78,
      col=ChIPColor,
      col.ticks=ChIPColor,
      col.axis=ChIPColor,
      tcl=-0.23
    )
    graphics::mtext(
      paste0("ChIP ", DisplayMetricLabel()),
      side=2,
      line=3.25,
      cex=0.75,
      col=ChIPColor
    )
    graphics::box(bty="l", col="gray35", lwd=0.8)

    graphics::par(new=TRUE)
    graphics::plot(
      NA,
      xlim=c(RegionStart, RegionEnd),
      ylim=YLimits$BrDU,
      axes=FALSE,
      xlab="",
      ylab="",
      bty="n",
      xaxs="i",
      yaxs="i"
    )
    graphics::lines(
      X,
      BrDUProfile$plot_signal,
      col=BrDUColor,
      lty=3,
      lwd=2
    )
    graphics::axis(
      4,
      at=BrDUTicks,
      labels=signif(BrDUTicks, 3),
      las=1,
      cex.axis=0.78,
      col=BrDUColor,
      col.ticks=BrDUColor,
      col.axis=BrDUColor,
      tcl=-0.23
    )
    graphics::mtext(
      paste0("BrDU ", DisplayMetricLabel()),
      side=4,
      line=3.25,
      cex=0.75,
      col=BrDUColor
    )
    CurrentLimits <- graphics::par("usr")
    graphics::segments(
      x0=CurrentLimits[[2]],
      y0=CurrentLimits[[3]],
      x1=CurrentLimits[[2]],
      y1=CurrentLimits[[4]],
      col=BrDUColor,
      lty=3,
      lwd=1.1
    )
    if(nrow(Annotations$Centromeres) > 0L){
      Centres <- (
        Annotations$Centromeres$chromStart +
          Annotations$Centromeres$chromEnd
      )/2
      graphics::segments(
        Centres,
        CurrentLimits[[3]],
        Centres,
        CurrentLimits[[4]],
        lwd=1.5,
        col="darkgreen"
      )
      graphics::text(
        Centres,
        CurrentLimits[[4]]-0.08*diff(CurrentLimits[3:4]),
        labels="CEN",
        cex=0.68,
        col="darkgreen",
        pos=4
      )
    }
    graphics::legend(
      "topright",
      legend=c("ChIP (left axis)", "BrDU (right axis)"),
      col=c(ChIPColor, BrDUColor),
      lty=c(1, 3),
      lwd=2,
      bty="n",
      cex=0.76
    )
  }

  PlotAnnotationTrack <- function(){
    graphics::par(mar=AnnotationMar)
    graphics::plot(
      NA,
      xlim=c(RegionStart, RegionEnd),
      ylim=c(0, 1.16),
      axes=FALSE,
      xlab="",
      ylab="",
      bty="n",
      xaxs="i",
      yaxs="i"
    )
    TrackY <- c(
      ARS=1.00,
      ORFplus=0.79,
      ORFminus=0.64,
      Ty=0.45,
      TER=0.28,
      tRNA=0.12
    )
    names(TrackY)[2:3] <- c("ORF+", "ORF-")
    graphics::abline(
      h=unname(TrackY),
      lwd=0.05,
      col=grDevices::rgb(
        112,
        128,
        144,
        alpha=150,
        maxColorValue=255
      )
    )

    if(nrow(Annotations$ARS) > 0L){
      ARSX <- (
        Annotations$ARS$chromStart +
          Annotations$ARS$chromEnd
      )/2
      graphics::points(
        ARSX,
        rep(TrackY[["ARS"]], length(ARSX)),
        pch=21,
        bg="yellow",
        col="purple",
        lwd=1.25,
        cex=0.95
      )
      LabelLevels <- PlaceARSLabels(ARSX)
      LabelColors <- rep("gray15", nrow(Annotations$ARS))
      Status <- tolower(Annotations$ARS$stat)
      LabelColors[Status == "early"] <- "red"
      LabelColors[Status == "late"] <- "blue"
      graphics::text(
        ARSX,
        1.055+0.045*LabelLevels,
        labels=Annotations$ARS$name,
        cex=0.66,
        col=LabelColors,
        xpd=NA
      )
    }

    if("ORF" %in% FeatureTracks && nrow(Annotations$ORFs) > 0L){
      ORFs <- Annotations$ORFs
      ORFs$plotStart <- pmax(ORFs$chromStart, RegionStart)
      ORFs$plotEnd <- pmin(ORFs$chromEnd, RegionEnd)
      ORFs <- ORFs[
        ORFs$plotEnd > ORFs$plotStart,
        ,
        drop=FALSE
      ]
      for(Index in seq_len(nrow(ORFs))){
        XStart <- ORFs$plotStart[[Index]]
        XEnd <- ORFs$plotEnd[[Index]]
        Plus <- ORFs$strand[[Index]] == "+"
        Y <- if(Plus) TrackY[["ORF+"]] else TrackY[["ORF-"]]
        Color <- if(Plus) "brown3" else "cornflowerblue"
        if((XEnd-XStart) < max(1, RegionWidth/1800)){
          graphics::segments(
            XStart,
            Y,
            XEnd,
            Y,
            lwd=ORFLwd,
            col=Color
          )
        } else if(Plus){
          suppressWarnings(graphics::arrows(
            XStart,
            Y,
            XEnd,
            Y,
            length=0.04,
            angle=25,
            code=2,
            lwd=ORFLwd,
            col=Color
          ))
        } else {
          suppressWarnings(graphics::arrows(
            XEnd,
            Y,
            XStart,
            Y,
            length=0.04,
            angle=25,
            code=2,
            lwd=ORFLwd,
            col=Color
          ))
        }
      }
    }
    if("Ty" %in% FeatureTracks){
      DrawBlocks(
        Annotations$Ty,
        TrackY[["Ty"]],
        0.045,
        grDevices::adjustcolor("mediumpurple3", alpha.f=0.75),
        "mediumpurple4"
      )
    }
    if("TER" %in% FeatureTracks){
      DrawBlocks(
        Annotations$TER,
        TrackY[["TER"]],
        0.045,
        grDevices::adjustcolor("orange2", alpha.f=0.65),
        "orange4"
      )
    }
    if("tRNA" %in% FeatureTracks){
      DrawBlocks(
        Annotations$tRNA,
        TrackY[["tRNA"]],
        0.038,
        grDevices::adjustcolor("seagreen3", alpha.f=0.75),
        "seagreen4"
      )
    }

    graphics::axis(
      2,
      at=unname(TrackY),
      labels=names(TrackY),
      las=2,
      cex.axis=0.72,
      tcl=-0.22
    )
    CoordinateTicks <- pretty(c(RegionStart, RegionEnd), n=6)
    CoordinateTicks <- CoordinateTicks[
      CoordinateTicks >= RegionStart &
      CoordinateTicks <= RegionEnd
    ]
    CoordinateLabels <- format(
      round(CoordinateTicks/1000, 3),
      trim=TRUE,
      scientific=FALSE
    )
    graphics::axis(
      1,
      at=CoordinateTicks,
      labels=CoordinateLabels,
      tick=FALSE,
      cex.axis=0.8
    )
    graphics::title(
      xlab=paste0(Chromosome, " coordinates (kb)"),
      col="gray30",
      cex.lab=0.88,
      line=1.75
    )
    graphics::box(col="gray45")
  }

  ChIPPrefix <- sub("-ChIP$", "", ChIPSampleName)
  BrDUPrefix <- sub("-BrDU$", "", BrDUSampleName)
  PairLabel <- if(identical(ChIPPrefix, BrDUPrefix)){
    ChIPPrefix
  } else {
    paste0(ChIPSampleName, " vs ", BrDUSampleName)
  }
  SanitizeFilename <- function(value){
    Value <- gsub("[^A-Za-z0-9._-]+", "_", value)
    Value <- gsub("_+", "_", Value)
    sub("^_+|_+$", "", Value)
  }
  PairTag <- SanitizeFilename(PairLabel)
  MetricTag <- gsub("\\.", "_", Metric)
  CoordinateTag <- paste0(
    format(RegionStart, scientific=FALSE, trim=TRUE),
    "-",
    format(RegionEnd, scientific=FALSE, trim=TRUE)
  )
  OutputFile <- file.path(
    OutputDir,
    paste0(
      PairTag,
      "_ChIP_BrDU_",
      Alignment,
      "_collapsed_",
      ScaleTag,
      "_",
      Chromosome,
      "_",
      CoordinateTag,
      "_",
      MetricTag,
      "_Region_Comparison.pdf"
    )
  )

  grDevices::pdf(
    OutputFile,
    width=PdfWidth,
    height=PdfHeight,
    useDingbats=FALSE
  )
  PdfDevice <- grDevices::dev.cur()
  on.exit({
    OpenDevices <- grDevices::dev.list()
    if(!is.null(OpenDevices) && PdfDevice %in% OpenDevices){
      grDevices::dev.off(which=PdfDevice)
    }
  }, add=TRUE)

  graphics::layout(
    matrix(c(1, 2), ncol=1),
    heights=c(4.6, 1.8)
  )
  graphics::par(oma=OuterMar)
  PlotComparisonPanel()
  PlotAnnotationTrack()
  graphics::mtext(
    paste0(
      "ChIP-BrDU regional ",
      DisplayMetricLabel(),
      " | ",
      Chromosome,
      ":",
      format(RegionStart, scientific=FALSE, trim=TRUE),
      "-",
      format(RegionEnd, scientific=FALSE, trim=TRUE)
    ),
    outer=TRUE,
    side=3,
    line=1.25,
    font=2,
    cex=1.08,
    col="gray25"
  )
  graphics::mtext(
    paste0(
      PairLabel,
      " | ",
      Alignment,
      " | collapsed | ",
      ScaleLabel,
      " | ChIP solid/left axis | BrDU dotted/right axis"
    ),
    outer=TRUE,
    side=3,
    line=0.10,
    cex=0.76,
    col="gray42"
  )

  grDevices::dev.off(which=PdfDevice)
  message("ChIP-BrDU regional comparison saved: ", OutputFile)

  invisible(list(
    pdf=OutputFile,
    output_pdf=OutputFile,
    chip_sample_dir=ChIPSampleDir,
    brdu_sample_dir=BrDUSampleDir,
    chip_sample_name=ChIPSampleName,
    brdu_sample_name=BrDUSampleName,
    pair_label=PairLabel,
    alignment=Alignment,
    strand_mode="collapsed",
    metric=Metric,
    chromosome=Chromosome,
    chromosome_length=ChromosomeLength,
    region=c(start=RegionStart, end=RegionEnd),
    ratio_files=RatioFiles,
    paired_ratio_coordinates_identical=CoordinatesMatch,
    raw_profiles=Profiles,
    display_profiles=DisplayProfiles,
    log2_profile=Log2Profile,
    display_transform=if(Log2Profile){
      if(Metric == "ip.score"){
        "log2(1+x)"
      } else {
        "log2(x) for positive values; non-positive values shown as missing"
      }
    } else {
      "untransformed"
    },
    steps=Steps,
    bin_widths=BinWidths,
    raw_neutral_baseline=RawBaselines[[Metric]],
    neutral_baseline=BaselineValue,
    y_val_chip=y_val_chip,
    y_val_brdu=y_val_brdu,
    y_limits=YLimits,
    y_limit_table=YLimitTable,
    y_limit_semantics="assay-specific upper limits with automatic lower limits and aligned neutral baselines",
    annotation_files=AnnotationFiles,
    annotation_counts=AnnotationCounts,
    annotations=Annotations,
    peak_visualization=FALSE,
    page_count=1L,
    pdf_dimensions_inches=c(width=PdfWidth, height=PdfHeight),
    primary_ratio_output_only=TRUE,
    annotation_source="project-local processed genomic-element BED files",
    plotter_operations=c(
      bam_reading=FALSE,
      coverage_reading=FALSE,
      simulation=FALSE,
      noise_estimation=FALSE,
      signal_filtering=FALSE,
      ratio_recalculation=FALSE,
      strand_collapsing=FALSE,
      peak_file_reading=FALSE,
      peak_calling=FALSE,
      peak_visualization=FALSE,
      pvalue_thresholding=FALSE
    ),
    display_operations=c(
      spline_smoothing=TRUE,
      log_transformation=Log2Profile,
      coverage_log1p=Log2Profile && Metric == "ip.score",
      ratio_log2_positive_only=Log2Profile && MetricIsRatio,
      dual_y_axes=TRUE,
      neutral_baseline_alignment=TRUE,
      chip_solid_line=TRUE,
      brdu_dotted_line=TRUE
    )
  ))
}

## rDNA ChIP/BrDU enrichment plotter.
##
## SampleDir accepts one sample directory or a vector of directories. Every
## sample must be a completed primary analysis run with Alignment="mrdna" and
## a Ratios_ma_rdna directory. One assay value may be shared by all samples, or
## one ChIP/BrDU value may be supplied per sample. Samples are drawn as stacked
## panels with one shared y-axis scale and one exact custom-reference annotation
## track. The native SGD second rDNA repeat is never used: RDNAx2.fasta contains
## a literal second copy of the selected 9,137-bp custom unit, so annotation copy
## 2 is always copy 1 shifted by +9,137 bp.
##
## Collapsed profiles may be displayed with or without log2 transformation.
## Separated profiles always use untransformed Watson and Crick ratios, with
## Crick mirrored below zero. Spline smoothing is display-only. This function
## reads the final Ratios_ma_rdna tables without simulation, noise estimation,
## filtering, ratio recalculation, peak calling, or peak annotation.
##
## Example:
## ChIP_BrDU_rDNA_Plotter(
##   SampleDir=c("/path/sample_A-ChIP", "/path/sample_B-ChIP"),
##   Assay="ChIP",
##   StrandMode="collapsed",
##   Metric="ratio.ipin.noise",
##   Log2Profile=TRUE,
##   SampleLabels=c("sample A", "sample B")
## )
ChIP_BrDU_rDNA_Plotter <- function(
    SampleDir,
    Assay="ChIP",
    StrandMode="collapsed",
    Metric="ratio.ipin.noise",
    Log2Profile=TRUE,
    SampleLabels=NULL,
    PlotStyle="lines",
    y_val=NULL,
    OutputDir=NULL){

  ## Fixed graphical contract. These settings remain internal so the run-script
  ## call is short and one- and multi-sample figures remain directly comparable.
  PanelsPerPage <- 4L
  Log2YMin <- -1
  YAxisScale <- 8
  SmoothSignal <- TRUE
  SmoothingSpar <- NULL
  ShowBaseline <- TRUE
  CollapsedSignalColor <- "gray25"
  WatsonColor <- "brown3"
  CrickColor <- "cornflowerblue"
  ProfileLineLwd <- 1.35
  ProfileBarLwd <- 0.38
  PdfWidth <- 11
  ProfileMar <- c(0.45, 4.65, 1.55, 1.0)
  AnnotationMar <- c(3.25, 4.65, 0.30, 1.0)
  OuterMar <- c(2.3, 2.5, 2.8, 1.2)

  ValidateLogical <- function(x, name){
    if(!is.logical(x) || length(x) != 1L || is.na(x)){
      stop(name, " must be TRUE or FALSE.")
    }
  }
  ValidatePositive <- function(x, name){
    if(!is.numeric(x) || length(x) != 1L || !is.finite(x) || x <= 0){
      stop(name, " must be one positive number.")
    }
  }
  RecycleChoice <- function(x, n, choices, name){
    x <- as.character(x)
    if(length(x) == 1L) x <- rep(x, n)
    if(length(x) != n){
      stop(name, " must contain one value or one value per SampleDir.")
    }
    invalid <- !x %in% choices
    if(any(invalid)){
      stop(
        name, " contains unsupported value(s): ",
        paste(unique(x[invalid]), collapse=", "),
        ". Allowed values: ", paste(choices, collapse=", "), "."
      )
    }
    x
  }

  if(is.null(SampleDir) || length(SampleDir) == 0L){
    stop("SampleDir must contain at least one sample directory.")
  }
  SampleDir <- as.character(SampleDir)
  if(any(is.na(SampleDir) | !nzchar(SampleDir))){
    stop("Every SampleDir entry must be a non-empty path.")
  }
  missing_sample_dirs <- SampleDir[!dir.exists(path.expand(SampleDir))]
  if(length(missing_sample_dirs) > 0L){
    stop(
      "Sample director", if(length(missing_sample_dirs) == 1L) "y is" else "ies are",
      " missing:\n", paste(missing_sample_dirs, collapse="\n")
    )
  }
  SampleDir <- vapply(
    SampleDir,
    function(path) normalizePath(path.expand(path), winslash="/", mustWork=TRUE),
    character(1)
  )
  NumberOfSamples <- length(SampleDir)

  Assay <- RecycleChoice(Assay, NumberOfSamples, c("ChIP", "BrDU"), "Assay")
  StrandMode <- match.arg(
    as.character(StrandMode)[1], c("collapsed", "separated")
  )
  Metric <- match.arg(
    as.character(Metric)[1],
    c("ratio.ipin.noise", "ratio.ipin", "ratio.ipnoise", "ip.score")
  )
  PlotStyle <- match.arg(as.character(PlotStyle)[1], c("hist", "lines"))
  if(PlotStyle == "hist") PlotStyle <- "bars"
  ValidateLogical(Log2Profile, "Log2Profile")
  if(!is.null(y_val)) ValidatePositive(y_val, "y_val")

  DisplayLog2 <- StrandMode == "collapsed" && Log2Profile
  if(StrandMode == "separated" && Log2Profile){
    message("Strand-separated rDNA profiles use untransformed ratios; Log2Profile is ignored.")
  }

  SampleNames <- basename(SampleDir)
  if(is.null(SampleLabels)){
    SampleLabels <- SampleNames
  } else {
    SampleLabels <- as.character(SampleLabels)
    if(length(SampleLabels) != NumberOfSamples){
      stop("SampleLabels must contain one label per SampleDir.")
    }
    if(any(is.na(SampleLabels) | !nzchar(SampleLabels))){
      stop("Every SampleLabels entry must be non-empty.")
    }
  }

  if(is.null(OutputDir)){
    OutputDir <- if(NumberOfSamples == 1L) SampleDir[[1]] else dirname(SampleDir[[1]])
  }
  OutputDir <- path.expand(as.character(OutputDir)[1])
  dir.create(OutputDir, recursive=TRUE, showWarnings=FALSE)
  OutputDir <- normalizePath(OutputDir, winslash="/", mustWork=TRUE)

  if(!requireNamespace("data.table", quietly=TRUE)){
    stop("The data.table package is required to read rDNA ratio and annotation tables efficiently.")
  }

  ProjectPaths <- ChIP_BrDU_Project_Paths(check=TRUE)
  ReferenceFasta <- ProjectPaths$indexes$rdna_fasta
  AnnotationFile <- ProjectPaths$elements$rdna_elements

  ReadSingleFasta <- function(file){
    lines <- readLines(file, warn=FALSE)
    header_index <- grep("^>", lines)
    if(length(header_index) != 1L){
      stop("The custom rDNA FASTA must contain exactly one sequence: ", file)
    }
    reference_name <- strsplit(
      sub("^>", "", lines[header_index]), "\\s+"
    )[[1]][1]
    sequence <- toupper(paste0(
      gsub("\\s+", "", lines[-header_index]), collapse=""
    ))
    if(!nzchar(sequence) || grepl("[^ACGTN]", sequence)){
      stop("The custom rDNA FASTA contains an empty or unsupported sequence: ", file)
    }
    list(name=reference_name, sequence=sequence, length=nchar(sequence))
  }

  Reference <- ReadSingleFasta(ReferenceFasta)
  ReferenceChromosome <- Reference$name
  ReferenceLength <- Reference$length
  if(ReferenceLength %% 2L != 0L){
    stop("The custom two-copy rDNA reference length must be divisible by two.")
  }
  UnitLength <- as.integer(ReferenceLength/2L)
  if(substr(Reference$sequence, 1L, UnitLength) !=
     substr(Reference$sequence, UnitLength+1L, ReferenceLength)){
    stop("RDNAx2.fasta does not contain two identical rDNA units.")
  }

  Annotation <- data.table::fread(
    AnnotationFile, data.table=FALSE, showProgress=FALSE
  )
  required_annotation_columns <- c(
    "chrom", "chromStart", "chromEnd", "name", "strand", "type",
    "repeat_copy", "part", "source_id"
  )
  missing_annotation_columns <- setdiff(
    required_annotation_columns, names(Annotation)
  )
  if(length(missing_annotation_columns) > 0L){
    stop(
      "The rDNA annotation is missing required column(s): ",
      paste(missing_annotation_columns, collapse=", "), "."
    )
  }
  Annotation$chrom <- as.character(Annotation$chrom)
  Annotation$chromStart <- as.numeric(Annotation$chromStart)
  Annotation$chromEnd <- as.numeric(Annotation$chromEnd)
  Annotation$name <- as.character(Annotation$name)
  Annotation$strand <- as.character(Annotation$strand)
  Annotation$type <- as.character(Annotation$type)
  Annotation$repeat_copy <- as.integer(Annotation$repeat_copy)
  Annotation$part <- as.character(Annotation$part)
  Annotation$source_id <- as.character(Annotation$source_id)
  Annotation <- Annotation[
    Annotation$chrom == ReferenceChromosome, , drop=FALSE
  ]
  invalid_annotation <- !is.finite(Annotation$chromStart) |
    !is.finite(Annotation$chromEnd) | Annotation$chromStart < 0 |
    Annotation$chromEnd > ReferenceLength |
    Annotation$chromEnd <= Annotation$chromStart
  if(nrow(Annotation) == 0L || any(invalid_annotation)){
    stop("The rDNA annotation is empty or contains coordinates outside RDNAx2.fasta.")
  }
  if(!identical(sort(unique(Annotation$repeat_copy)), c(1L, 2L))){
    stop("The rDNA annotation must contain custom repeat copies 1 and 2.")
  }
  copy2_sources <- Annotation$source_id[Annotation$repeat_copy == 2L]
  if(!all(grepl("^custom_copy1_duplicate", copy2_sources))){
    stop("Custom rDNA copy 2 must be annotated explicitly as a duplicate of copy 1.")
  }

  TransformSignal <- function(values){
    values <- suppressWarnings(as.numeric(values))
    if(DisplayLog2){
      values[!is.finite(values) | values <= 0] <- 1
      values <- log2(values)
    } else {
      values[!is.finite(values)] <- 0
    }
    values
  }

  ReadRatio <- function(file, sample_label){
    header <- names(data.table::fread(
      file, nrows=0, data.table=FALSE, showProgress=FALSE
    ))
    required <- c("chrom", "chromStart", "chromEnd", Metric)
    missing <- setdiff(required, header)
    if(length(missing) > 0L){
      stop(
        "rDNA ratio table for ", sample_label,
        " is missing required column(s) ", paste(missing, collapse=", "),
        ": ", file
      )
    }
    ratio <- data.table::fread(
      file, select=required, data.table=FALSE, showProgress=FALSE
    )
    names(ratio)[names(ratio) == Metric] <- "metric_value"
    ratio$chrom <- as.character(ratio$chrom)
    ratio$chromStart <- as.numeric(ratio$chromStart)
    ratio$chromEnd <- as.numeric(ratio$chromEnd)
    ratio$metric_value <- as.numeric(ratio$metric_value)
    ratio <- ratio[
      ratio$chrom == ReferenceChromosome &
        is.finite(ratio$chromStart) & is.finite(ratio$chromEnd) &
        ratio$chromStart < ReferenceLength & ratio$chromEnd > 0,
      , drop=FALSE
    ]
    ratio <- ratio[order(ratio$chromStart, ratio$chromEnd), , drop=FALSE]
    if(nrow(ratio) == 0L){
      stop(
        "No ", ReferenceChromosome, " rows were found in the ratio table for ",
        sample_label, ": ", file
      )
    }
    if(anyDuplicated(ratio$chromStart)){
      stop("Duplicated rDNA window starts were found for ", sample_label, ".")
    }
    ratio
  }

  InferStep <- function(profile){
    starts <- sort(unique(profile$chromStart[is.finite(profile$chromStart)]))
    differences <- diff(utils::head(starts, 10000L))
    differences <- differences[is.finite(differences) & differences > 0]
    if(length(differences) == 0L) return(NA_real_)
    as.numeric(names(which.max(base::table(differences))))
  }

  message("Reading primary-analysis Ratios_ma_rdna table(s)...")
  Samples <- vector("list", NumberOfSamples)
  for(index in seq_len(NumberOfSamples)){
    ratio_dir <- file.path(SampleDir[index], "Ratios_ma_rdna")
    if(!dir.exists(ratio_dir)){
      stop(
        "Required Ratios_ma_rdna directory is missing for ",
        SampleLabels[index], ": ", ratio_dir
      )
    }
    if(StrandMode == "collapsed"){
      ratio_files <- c(collapsed=file.path(
        ratio_dir,
        paste0(
          SampleNames[index], "_", Assay[index], "_rDNA_collapsed.bed"
        )
      ))
    } else {
      ratio_files <- c(
        watson=file.path(
          ratio_dir,
          paste0(SampleNames[index], "_", Assay[index], "_rDNA_watson.bed")
        ),
        crick=file.path(
          ratio_dir,
          paste0(SampleNames[index], "_", Assay[index], "_rDNA_crick.bed")
        )
      )
    }
    missing_ratio_files <- ratio_files[!file.exists(ratio_files)]
    if(length(missing_ratio_files) > 0L){
      stop(
        "Required rDNA ratio table(s) are missing for ",
        SampleLabels[index], ":\n",
        paste(missing_ratio_files, collapse="\n")
      )
    }

    if(StrandMode == "collapsed"){
      profile <- ReadRatio(ratio_files[["collapsed"]], SampleLabels[index])
      profile$plot_signal <- TransformSignal(profile$metric_value)
    } else {
      watson <- ReadRatio(ratio_files[["watson"]], SampleLabels[index])
      crick <- ReadRatio(ratio_files[["crick"]], SampleLabels[index])
      coordinates_match <- nrow(watson) == nrow(crick) &&
        identical(watson$chrom, crick$chrom) &&
        identical(watson$chromStart, crick$chromStart) &&
        identical(watson$chromEnd, crick$chromEnd)
      if(!coordinates_match){
        stop(
          "Watson and Crick rDNA ratio-table coordinates do not match for ",
          SampleLabels[index], "."
        )
      }
      profile <- data.frame(
        chrom=watson$chrom,
        chromStart=watson$chromStart,
        chromEnd=watson$chromEnd,
        watson_signal=TransformSignal(watson$metric_value),
        crick_signal=TransformSignal(crick$metric_value),
        stringsAsFactors=FALSE
      )
    }
    Samples[[index]] <- list(
      sample_dir=SampleDir[index],
      sample_name=SampleNames[index],
      sample_label=SampleLabels[index],
      assay=Assay[index],
      alignment="mrdna",
      ratio_files=ratio_files,
      profile=profile,
      step=InferStep(profile)
    )
  }

  MetricIsRatio <- Metric != "ip.score"
  BaselineValue <- if(DisplayLog2) 0 else if(MetricIsRatio) 1 else 0
  MetricLabels <- c(
    "ip.score"="IP coverage",
    "ratio.ipin"="IP / Input",
    "ratio.ipnoise"="IP / Noise",
    "ratio.ipin.noise"="(IP / Noise) / (Input / Noise)"
  )
  MetricShortLabels <- c(
    "ip.score"="IP coverage",
    "ratio.ipin"="IP/Input",
    "ratio.ipnoise"="IP/Noise",
    "ratio.ipin.noise"="clean enrichment"
  )
  TitleMetricLabel <- unname(MetricLabels[[Metric]])
  YLabel <- unname(MetricShortLabels[[Metric]])
  if(DisplayLog2){
    TitleMetricLabel <- paste0("log2(", TitleMetricLabel, ")")
    YLabel <- paste0("log2 ", YLabel)
  }
  if(StrandMode == "separated"){
    TitleMetricLabel <- paste0(TitleMetricLabel, " | W(+), C(-)")
    YLabel <- paste0(YLabel, " | W(+), C(-)")
  }

  GetThreshold <- function(values){
    values <- values[is.finite(values)]
    if(length(values) == 0L) return(1)
    quantiles <- stats::quantile(values, probs=c(0.01, 0.99), na.rm=TRUE)
    iqr <- stats::IQR(values, na.rm=TRUE)
    trimmed <- values[
      values > quantiles[1] - 1.5*iqr & values < quantiles[2] + 1.5*iqr
    ]
    threshold <- if(length(trimmed) < 2L){
      max(abs(values), na.rm=TRUE)
    } else {
      mean(trimmed, na.rm=TRUE) + YAxisScale*stats::sd(trimmed, na.rm=TRUE)
    }
    if(!is.finite(threshold) || threshold <= 0){
      threshold <- max(abs(values), na.rm=TRUE)
    }
    if(!is.finite(threshold) || threshold <= 0) threshold <- 1
    threshold
  }

  if(!is.null(y_val)){
    if(StrandMode == "collapsed"){
      if(DisplayLog2 && y_val <= Log2YMin){
        stop("For a collapsed log2 plot, y_val must be greater than Log2YMin.")
      }
      Ylim <- if(DisplayLog2) c(Log2YMin, y_val) else c(0, y_val)
    } else {
      Ylim <- c(-y_val, y_val)
    }
    YLimitSource <- "y_val"
  } else if(StrandMode == "collapsed"){
    values <- unlist(lapply(Samples, function(sample) sample$profile$plot_signal))
    y_max <- max(1, GetThreshold(values), na.rm=TRUE)
    if(DisplayLog2){
      Ylim <- c(Log2YMin, ceiling(y_max))
    } else {
      if(ShowBaseline) y_max <- max(y_max, BaselineValue*1.05)
      Ylim <- c(0, y_max)
    }
    YLimitSource <- "shared_internal"
  } else {
    values <- unlist(lapply(
      Samples,
      function(sample){
        c(sample$profile$watson_signal, sample$profile$crick_signal)
      }
    ))
    y_max <- ceiling(max(1, GetThreshold(abs(values)), na.rm=TRUE))
    if(MetricIsRatio) y_max <- max(y_max, 1.05)
    Ylim <- c(-y_max, y_max)
    YLimitSource <- "shared_internal"
  }
  YAxisTicks <- pretty(Ylim, n=5)
  YAxisTicks <- YAxisTicks[
    YAxisTicks >= min(Ylim) & YAxisTicks <= max(Ylim)
  ]

  SafeSmooth <- function(x, y){
    ok <- is.finite(x) & is.finite(y)
    if(sum(ok) < 4L || length(unique(x[ok])) < 4L ||
       length(unique(y[ok])) < 2L){
      return(y)
    }
    model <- tryCatch(
      if(is.null(SmoothingSpar)) stats::smooth.spline(x[ok], y[ok])
      else stats::smooth.spline(x[ok], y[ok], spar=SmoothingSpar),
      error=function(e) NULL
    )
    if(is.null(model)) return(y)
    stats::predict(model, x)$y
  }

  PlotProfilePanel <- function(sample, show_strand_legend=FALSE){
    coverage <- sample$profile
    x <- coverage$chromStart
    par(mar=ProfileMar)
    plot(
      NA, xlim=c(0, ReferenceLength), ylim=Ylim, ylab="", xlab="",
      xaxt="n", yaxt="n", bty="n", xaxs="i"
    )
    abline(
      v=UnitLength, lwd=0.8, lty=3,
      col=grDevices::adjustcolor("gray25", alpha.f=0.55)
    )
    abline(
      h=YAxisTicks, lwd=0.05,
      col=grDevices::rgb(112, 128, 144, alpha=150, maxColorValue=255)
    )

    if(StrandMode == "collapsed"){
      y <- coverage$plot_signal
      if(SmoothSignal) y <- SafeSmooth(x, y)
      if(PlotStyle == "lines"){
        lines(x, y, col=CollapsedSignalColor, lwd=ProfileLineLwd)
      } else {
        segments(x, 0, x, y, col=CollapsedSignalColor, lwd=ProfileBarLwd)
      }
    } else {
      watson <- coverage$watson_signal
      crick <- coverage$crick_signal
      if(SmoothSignal){
        watson <- SafeSmooth(x, watson)
        crick <- SafeSmooth(x, crick)
      }
      watson[!is.finite(watson)] <- 0
      crick[!is.finite(crick)] <- 0
      watson <- pmax(watson, 0)
      crick <- -pmax(crick, 0)
      if(PlotStyle == "lines"){
        lines(x, watson, col=WatsonColor, lwd=ProfileLineLwd)
        lines(x, crick, col=CrickColor, lwd=ProfileLineLwd)
      } else {
        segments(x, 0, x, watson, col=WatsonColor, lwd=ProfileBarLwd)
        segments(x, 0, x, crick, col=CrickColor, lwd=ProfileBarLwd)
      }
      if(show_strand_legend){
        legend(
          "topright", legend=c("Watson", "Crick"),
          col=c(WatsonColor, CrickColor), lwd=2,
          bty="n", cex=0.72
        )
      }
    }

    axis(
      2, at=YAxisTicks, labels=signif(YAxisTicks, 3), line=0,
      tick=TRUE, lwd.ticks=1.2, las=2, cex.axis=0.8
    )
    if(ShowBaseline){
      if(StrandMode == "separated"){
        abline(h=0, lwd=0.9, lty=3, col="gray20")
        if(MetricIsRatio){
          abline(h=c(-1, 1), lwd=0.7, lty=3, col="gray45")
        }
      } else if(BaselineValue >= min(Ylim) && BaselineValue <= max(Ylim)){
        abline(h=BaselineValue, lwd=0.9, lty=3, col="gray20")
      }
    }
    panel_title <- paste0(
      sample$sample_label, " | ", sample$assay, " | mrdna"
    )
    title(main=panel_title, col="gray35", adj=0, cex.main=0.9, line=0.25)
    mtext(side=2, line=3.0, at=mean(Ylim), cex=0.8, YLabel)
    box(col="gray45")
  }

  AnnotationColors <- c(
    `35S`="#91BFE3",
    NTS1="#C9B2DD",
    NTS2="#E2C98F",
    `5S`="#F2A65A",
    ETS="#BFDCEC",
    mature_rRNA="#5F97C4",
    ITS="#D6D9DE",
    rARS="#F6D55C",
    RFB="#D95F59"
  )

  DrawBlocks <- function(features, y, height, color, border="gray40", lwd=0.5){
    if(nrow(features) == 0L) return(invisible(NULL))
    rect(
      features$chromStart, y-height, features$chromEnd, y+height,
      col=color, border=border, lwd=lwd
    )
    invisible(NULL)
  }
  LabelLargestPart <- function(features, y, label=NULL, cex=0.54,
                               color="gray15", srt=0, offset=0){
    if(nrow(features) == 0L) return(invisible(NULL))
    for(copy in sort(unique(features$repeat_copy))){
      copy_features <- features[features$repeat_copy == copy, , drop=FALSE]
      widths <- copy_features$chromEnd - copy_features$chromStart
      selected <- copy_features[which.max(widths), , drop=FALSE]
      x <- (selected$chromStart + selected$chromEnd)/2
      text(
        x, y+offset,
        labels=if(is.null(label)) selected$name[[1]] else label,
        cex=cex, col=color, srt=srt, xpd=NA
      )
    }
    invisible(NULL)
  }
  DrawDirectionalFeature <- function(features, y, height, color){
    DrawBlocks(features, y, height, color)
    for(index in seq_len(nrow(features))){
      if(features$strand[index] == "-"){
        suppressWarnings(arrows(
          features$chromEnd[index], y, features$chromStart[index], y,
          length=0.045, angle=25, code=2, lwd=1.15, col="gray25"
        ))
      } else if(features$strand[index] == "+"){
        suppressWarnings(arrows(
          features$chromStart[index], y, features$chromEnd[index], y,
          length=0.045, angle=25, code=2, lwd=1.15, col="gray25"
        ))
      }
    }
    invisible(NULL)
  }

  PlotAnnotationTrack <- function(){
    par(mar=AnnotationMar)
    plot(
      NA, xlim=c(0, ReferenceLength), ylim=c(0, 1.52),
      ylab="", xlab="", xaxt="n", yaxt="n", bty="n",
      xaxs="i", yaxs="i"
    )
    track_y <- c(`repeat`=1.37, primary=1.06, `35S detail`=0.63,
                 replication=0.20)
    abline(
      v=UnitLength, lwd=0.8, lty=3,
      col=grDevices::adjustcolor("gray25", alpha.f=0.55)
    )
    abline(
      h=unname(track_y), lwd=0.05,
      col=grDevices::rgb(112, 128, 144, alpha=150, maxColorValue=255)
    )

    repeats <- Annotation[Annotation$type == "rDNA_repeat", , drop=FALSE]
    DrawBlocks(
      repeats, track_y[["repeat"]], 0.065,
      grDevices::adjustcolor("gray82", alpha.f=0.65), "gray45"
    )
    if(nrow(repeats) > 0L){
      text(
        (repeats$chromStart + repeats$chromEnd)/2,
        rep(track_y[["repeat"]], nrow(repeats)),
        labels=paste0("custom repeat ", repeats$repeat_copy),
        cex=0.58, col="gray25"
      )
    }

    rdn35 <- Annotation[Annotation$name == "35S", , drop=FALSE]
    nts1 <- Annotation[Annotation$name == "NTS1", , drop=FALSE]
    nts2 <- Annotation[Annotation$name == "NTS2", , drop=FALSE]
    rdn5 <- Annotation[Annotation$name == "5S", , drop=FALSE]
    DrawDirectionalFeature(
      rdn35, track_y[["primary"]], 0.07, AnnotationColors[["35S"]]
    )
    DrawBlocks(
      nts1, track_y[["primary"]], 0.07, AnnotationColors[["NTS1"]]
    )
    DrawBlocks(
      nts2, track_y[["primary"]], 0.07, AnnotationColors[["NTS2"]]
    )
    DrawDirectionalFeature(
      rdn5, track_y[["primary"]], 0.07, AnnotationColors[["5S"]]
    )
    LabelLargestPart(rdn35, track_y[["primary"]], "35S", cex=0.56)
    LabelLargestPart(nts1, track_y[["primary"]], "NTS1", cex=0.52)
    LabelLargestPart(nts2, track_y[["primary"]], "NTS2", cex=0.52)
    LabelLargestPart(
      rdn5, track_y[["primary"]], "5S", cex=0.50, srt=45, offset=0.11
    )

    detail_names <- c("ETS2", "25S", "ITS2", "5.8S", "ITS1", "18S", "ETS1")
    for(feature_name in detail_names){
      feature <- Annotation[Annotation$name == feature_name, , drop=FALSE]
      feature_color <- if(grepl("^ETS", feature_name)){
        AnnotationColors[["ETS"]]
      } else if(grepl("^ITS", feature_name)){
        AnnotationColors[["ITS"]]
      } else {
        AnnotationColors[["mature_rRNA"]]
      }
      DrawBlocks(feature, track_y[["35S detail"]], 0.055, feature_color)
      LabelLargestPart(
        feature, track_y[["35S detail"]], feature_name,
        cex=0.46, srt=45, offset=0.095
      )
    }

    rars <- Annotation[Annotation$name == "rARS", , drop=FALSE]
    acs <- Annotation[Annotation$name == "rARS_ACS", , drop=FALSE]
    rfb <- Annotation[Annotation$name == "RFB", , drop=FALSE]
    DrawBlocks(
      rars, track_y[["replication"]], 0.065,
      AnnotationColors[["rARS"]], "goldenrod4", 0.7
    )
    DrawBlocks(
      rfb, track_y[["replication"]], 0.055,
      AnnotationColors[["RFB"]], "firebrick4", 0.7
    )
    if(nrow(acs) > 0L){
      acs_center <- (acs$chromStart + acs$chromEnd)/2
      segments(
        acs_center, track_y[["replication"]]-0.085,
        acs_center, track_y[["replication"]]+0.085,
        lwd=1.6, col="black"
      )
      text(
        acs_center, rep(track_y[["replication"]]-0.14, length(acs_center)),
        labels="ACS", cex=0.39, col="gray15", srt=45, xpd=NA
      )
    }
    LabelLargestPart(
      rars, track_y[["replication"]], "rARS", cex=0.48, offset=0.12
    )
    LabelLargestPart(
      rfb, track_y[["replication"]], "RFB", cex=0.46, offset=-0.12
    )

    axis(
      2, at=unname(track_y), labels=names(track_y), line=0,
      tick=TRUE, lwd.ticks=1, las=2, cex.axis=0.68
    )
    coordinate_ticks <- sort(unique(c(
      pretty(c(0, ReferenceLength), n=8), 0, UnitLength, ReferenceLength
    )))
    coordinate_ticks <- coordinate_ticks[
      coordinate_ticks >= 0 & coordinate_ticks <= ReferenceLength
    ]
    coordinate_labels <- format(
      round(coordinate_ticks/1000, 3), trim=TRUE, scientific=FALSE
    )
    axis(
      1, at=coordinate_ticks, labels=coordinate_labels,
      line=0, tick=FALSE, cex.axis=0.76
    )
    title(
      xlab=paste0(ReferenceChromosome, " coordinates (Kbp)"),
      col="gray30", cex.lab=0.86, line=2.05
    )
    box(col="gray45")
  }

  PlotAnnotationNote <- function(){
    par(mar=c(0, 0, 0, 0))
    plot(
      NA, xlim=c(0, 1), ylim=c(0, 1), axes=FALSE,
      xlab="", ylab="", bty="n", xaxs="i", yaxs="i"
    )
    text(
      0.5, 0.55,
      "Exact custom annotation: copy 2 = copy 1 + 9,137 bp; native SGD repeat 2 is not used",
      cex=0.67, col="gray35"
    )
  }

  PlotBlankProfile <- function(){
    par(mar=ProfileMar)
    plot(
      NA, xlim=c(0, ReferenceLength), ylim=Ylim,
      axes=FALSE, xlab="", ylab="", bty="n", xaxs="i"
    )
  }

  SanitizeFilename <- function(x){
    x <- gsub("[^A-Za-z0-9._-]+", "_", x)
    x <- gsub("_+", "_", x)
    sub("^_+|_+$", "", x)
  }
  sample_tag <- if(NumberOfSamples == 1L){
    SanitizeFilename(SampleNames[[1]])
  } else {
    candidate <- paste(SanitizeFilename(SampleLabels), collapse="_vs_")
    if(nchar(candidate) <= 120L){
      candidate
    } else {
      paste0("comparison_", NumberOfSamples, "samples")
    }
  }
  assay_tag <- if(length(unique(Assay)) == 1L) unique(Assay) else "mixed_assay"
  metric_suffix <- gsub("\\.", "_", Metric)
  log_suffix <- if(DisplayLog2) "log2_" else ""
  OutputFile <- file.path(
    OutputDir,
    paste0(
      sample_tag, "_", assay_tag, "_mrdna_", StrandMode, "_",
      log_suffix, metric_suffix, "_rDNA.pdf"
    )
  )

  PageCount <- ceiling(NumberOfSamples/PanelsPerPage)
  PanelSlots <- min(PanelsPerPage, NumberOfSamples)
  PdfHeight <- max(7.4, min(12.5, 4.1 + 2.05*PanelSlots))
  grDevices::pdf(
    OutputFile, width=PdfWidth, height=PdfHeight, useDingbats=FALSE
  )
  on.exit(grDevices::dev.off(), add=TRUE)

  for(page in seq_len(PageCount)){
    page_start <- (page-1L)*PanelsPerPage + 1L
    page_end <- min(page*PanelsPerPage, NumberOfSamples)
    page_indexes <- page_start:page_end
    layout(
      matrix(seq_len(PanelSlots+2L), ncol=1),
      heights=c(rep(3.0, PanelSlots), 2.25, 0.42)
    )
    par(oma=OuterMar)
    for(slot in seq_len(PanelSlots)){
      if(slot <= length(page_indexes)){
        PlotProfilePanel(
          Samples[[page_indexes[slot]]],
          show_strand_legend=StrandMode == "separated" && slot == 1L
        )
      } else {
        PlotBlankProfile()
      }
    }
    PlotAnnotationTrack()
    PlotAnnotationNote()
    page_suffix <- if(PageCount > 1L){
      paste0(" | page ", page, "/", PageCount)
    } else {
      ""
    }
    mtext(
      paste0(
        "rDNA ", TitleMetricLabel, " | two custom NTS1-containing units | ",
        StrandMode, page_suffix
      ),
      outer=TRUE, side=3, line=1.25, cex=0.95, col="gray35"
    )
  }

  message("rDNA plot saved: ", OutputFile)
  invisible(list(
    pdf=OutputFile,
    sample_dir=SampleDir,
    sample_name=SampleNames,
    sample_labels=SampleLabels,
    assay=Assay,
    alignment=rep("mrdna", NumberOfSamples),
    strand_mode=StrandMode,
    metric=Metric,
    ratio_files=lapply(Samples, function(sample) sample$ratio_files),
    reference_fasta=ReferenceFasta,
    reference_name=ReferenceChromosome,
    reference_length=ReferenceLength,
    unit_length=UnitLength,
    annotation_file=AnnotationFile,
    annotation_copy2="custom_copy1_plus_9137",
    peak_visualization=FALSE,
    log2_profile=DisplayLog2,
    steps=vapply(Samples, function(sample) sample$step, numeric(1)),
    y_val=y_val,
    y_limits=Ylim,
    y_limit_source=YLimitSource,
    panels_per_page=PanelsPerPage,
    page_count=PageCount,
    primary_output_only=TRUE,
    plotter_operations=c(
      simulation=FALSE,
      noise_estimation=FALSE,
      signal_filtering=FALSE,
      ratio_recalculation=FALSE,
      peak_calling=FALSE,
      peak_annotation=FALSE,
      pvalue_thresholding=FALSE
    ),
    display_operations=c(
      spline_smoothing=SmoothSignal,
      collapsed_log2=DisplayLog2,
      crick_mirroring=StrandMode == "separated",
      shared_comparison_scale=NumberOfSamples > 1L,
      exact_rdna_annotation=TRUE
    )
  ))
}

## Peak-centred ChIP/BrDU enrichment report. This is one self-contained public
## block; a separate run script can source this main script and call it directly.
## The function reads the five peak-cohort files and either the strand-collapsed
## ratio table or the Watson and Crick ratio tables written by the current primary
## analysis. It never reads BAM/coverage files, calls peaks, simulates positions,
## estimates noise, filters signal, or recalculates a ratio. The median
## peak-centred profiles are graphical summaries of the four final ratio-table
## metrics, and spline smoothing is display-only. Strand-separated profiles keep
## Watson positive and mirror Crick below zero. Log2Profile=FALSE preserves the
## untransformed legacy display. Log2Profile=TRUE uses log2(x) for collapsed
## profiles and log2(1+x) for separated profiles so zero remains defined and the
## Watson-positive/Crick-negative strand orientation is preserved.
## Untransformed ratio panels mark 1 as the neutral reference (0 after log2),
## without rebasing the saved ratio values. Raw coverage remains data-scaled
## because it has no neutral enrichment baseline.
## Saved peak cohorts are used exactly as written: Genomewide, Origin, NonOrigin,
## EarlyOrigin, and LateOrigin are not rebuilt from genomic annotations here.
##
## The four-page report follows the legacy peak-analysis organization:
##   1. peak-cohort counts;
##   2. Genomewide, NonOrigin, and Origin profiles for all four metrics;
##   3. EarlyOrigin and LateOrigin profiles for all four metrics;
##   4. four pairwise comparisons using ratio.ipin.noise.
##
## Example:
## ChIP_BrDU_Peak_Enrichment_Plotter(
##   SampleDir="/path/to/sample-ChIP",
##   Assay="ChIP",
##   Alignment="generic",
##   StrandMode="collapsed",
##   Log2Profile=FALSE,
##   Window=3000
## )
ChIP_BrDU_Peak_Enrichment_Plotter <- function(
    SampleDir,
    Assay=c("ChIP", "BrDU"),
    Alignment=c("generic", "malign"),
    StrandMode=c("collapsed", "separated"),
    Log2Profile=FALSE,
    Window=3000,
    OutputDir=NULL){

  ## Fixed report contract. These display settings are implementation details,
  ## not user-facing arguments.
  Metrics <- c("ip.score", "ratio.ipin", "ratio.ipnoise", "ratio.ipin.noise")
  MetricLabels <- c(
    "IP coverage",
    "Enrichment over input",
    "Enrichment over noise",
    "Clean enrichment"
  )
  names(MetricLabels) <- Metrics
  PeakClasses <- c(
    "Genomewide", "NonOrigin", "Origin", "EarlyOrigin", "LateOrigin"
  )
  PeakColor <- "cornflowerblue"
  ProfileColor <- "darkorchid4"
  WatsonColor <- "brown3"
  CrickColor <- "cornflowerblue"
  PairColor1 <- grDevices::adjustcolor("darkorchid4", alpha.f=0.9)
  PairColor2 <- grDevices::adjustcolor("darkorange3", alpha.f=0.9)
  SmoothingSpar <- 0.5
  PdfWidth <- 12
  PdfHeight <- 10

  Assay <- match.arg(Assay)
  Alignment <- match.arg(Alignment)
  StrandMode <- match.arg(StrandMode)
  MetricTitles <- c(
    ip.score=Assay,
    ratio.ipin=paste0(Assay, " / Input"),
    ratio.ipnoise=paste0(Assay, " / Noise"),
    ratio.ipin.noise="Clean"
  )
  if(!is.logical(Log2Profile) || length(Log2Profile) != 1L ||
     is.na(Log2Profile)){
    stop("Log2Profile must be TRUE or FALSE.", call.=FALSE)
  }
  TransformLabel <- if(Log2Profile){
    if(StrandMode == "separated") "log2(1+x)" else "log2(x)"
  } else {
    "untransformed"
  }
  if(length(SampleDir) != 1L || is.na(SampleDir) || !nzchar(SampleDir)){
    stop("SampleDir must be one existing sample directory.", call.=FALSE)
  }
  if(!dir.exists(SampleDir)){
    stop("SampleDir does not exist: ", SampleDir, call.=FALSE)
  }
  SampleDir <- normalizePath(SampleDir, winslash="/", mustWork=TRUE)
  SampleName <- basename(SampleDir)

  if(length(Window) != 1L || !is.numeric(Window) || !is.finite(Window) ||
     Window <= 0 || abs(Window-round(Window)) > sqrt(.Machine$double.eps)){
    stop("Window must be one positive whole number of base pairs.", call.=FALSE)
  }
  Window <- as.integer(round(Window))

  if(is.null(OutputDir)){
    OutputDir <- SampleDir
  }
  if(length(OutputDir) != 1L || is.na(OutputDir) || !nzchar(OutputDir)){
    stop("OutputDir must be NULL or one directory path.", call.=FALSE)
  }
  if(!dir.exists(OutputDir)){
    dir.create(OutputDir, recursive=TRUE, showWarnings=FALSE)
  }
  if(!dir.exists(OutputDir)){
    stop("Could not create OutputDir: ", OutputDir, call.=FALSE)
  }
  OutputDir <- normalizePath(OutputDir, winslash="/", mustWork=TRUE)

  if(!requireNamespace("data.table", quietly=TRUE)){
    stop(
      "The data.table package is required to read and summarize peak outputs efficiently.",
      call.=FALSE
    )
  }

  PeakFolder <- if(Alignment == "generic") "Peaks" else "Peaks_ma"
  RatioFolder <- if(Alignment == "generic") "Ratios" else "Ratios_ma"
  PeakDir <- file.path(SampleDir, PeakFolder)
  RatioDir <- file.path(SampleDir, RatioFolder)
  PeakFiles <- setNames(
    file.path(
      PeakDir,
      paste0(SampleName, "_", PeakClasses, "_Peaks.bed")
    ),
    PeakClasses
  )
  RatioFiles <- if(StrandMode == "collapsed"){
    c(collapsed=file.path(
      RatioDir,
      paste0(SampleName, "_", Assay, "_collapsed.bed")
    ))
  } else {
    c(
      watson=file.path(
        RatioDir,
        paste0(SampleName, "_", Assay, "_watson.bed")
      ),
      crick=file.path(
        RatioDir,
        paste0(SampleName, "_", Assay, "_crick.bed")
      )
    )
  }
  RequiredFiles <- c(PeakFiles, RatioFiles)
  MissingFiles <- RequiredFiles[!file.exists(RequiredFiles)]
  if(length(MissingFiles) > 0L){
    stop(
      "Required primary-analysis output file(s) are missing:\n",
      paste(MissingFiles, collapse="\n"),
      call.=FALSE
    )
  }

  ReadPeakFile <- function(file, peak_class){
    Peaks <- data.table::fread(
      file,
      header=TRUE,
      sep="\t",
      showProgress=FALSE,
      data.table=TRUE
    )
    RequiredColumns <- c("chrom", "peakStart", "peakEnd", "peakSummit")
    MissingColumns <- setdiff(RequiredColumns, names(Peaks))
    if(length(MissingColumns) > 0L){
      stop(
        peak_class, " peak file is missing required column(s): ",
        paste(MissingColumns, collapse=", "), "\n", file,
        call.=FALSE
      )
    }
    Peaks <- Peaks[, .(
      chrom=as.character(chrom),
      peakStart=as.numeric(peakStart),
      peakEnd=as.numeric(peakEnd),
      peakSummit=as.numeric(peakSummit)
    )]
    if(nrow(Peaks) > 0L){
      NumericValues <- unlist(
        Peaks[, .(peakStart, peakEnd, peakSummit)],
        use.names=FALSE
      )
      if(any(!is.finite(NumericValues)) || any(!nzchar(Peaks$chrom))){
        stop("Invalid peak coordinates in: ", file, call.=FALSE)
      }
      if(any(Peaks$peakStart > Peaks$peakEnd)){
        stop("A peakStart is greater than peakEnd in: ", file, call.=FALSE)
      }
      PeakKey <- paste(
        Peaks$chrom, Peaks$peakStart, Peaks$peakEnd, Peaks$peakSummit,
        sep="\r"
      )
      if(anyDuplicated(PeakKey)){
        stop(
          "Duplicated peak coordinates were found in the saved ",
          peak_class, " cohort: ", file,
          call.=FALSE
        )
      }
      Peaks[, peak_key := PeakKey]
    } else {
      Peaks[, peak_key := character()]
    }
    Peaks
  }

  Peaks <- lapply(
    PeakClasses,
    function(peak_class) ReadPeakFile(PeakFiles[[peak_class]], peak_class)
  )
  names(Peaks) <- PeakClasses
  PeakCounts <- vapply(Peaks, nrow, integer(1))
  if(PeakCounts[["Genomewide"]] == 0L){
    stop(
      "The saved Genomewide peak cohort is empty; no peak-centred profile can be made.",
      call.=FALSE
    )
  }

  GenomewideKeys <- Peaks$Genomewide$peak_key
  PeakIds <- list(Genomewide=seq_len(PeakCounts[["Genomewide"]]))
  for(peak_class in setdiff(PeakClasses, "Genomewide")){
    PeakIds[[peak_class]] <- match(Peaks[[peak_class]]$peak_key, GenomewideKeys)
    if(anyNA(PeakIds[[peak_class]])){
      stop(
        "The saved ", peak_class,
        " cohort contains a peak absent from the saved Genomewide cohort. ",
        "The files were not reclassified; correct the primary outputs and rerun.",
        call.=FALSE
      )
    }
  }
  PeakIds <- PeakIds[PeakClasses]

  OriginNonOriginOverlap <- intersect(PeakIds$Origin, PeakIds$NonOrigin)
  OriginNonOriginMissing <- setdiff(
    PeakIds$Genomewide,
    union(PeakIds$Origin, PeakIds$NonOrigin)
  )
  if(length(OriginNonOriginOverlap) > 0L ||
     length(OriginNonOriginMissing) > 0L){
    warning(
      "Saved Origin and NonOrigin cohorts do not form an exact Genomewide partition ",
      "(overlap=", length(OriginNonOriginOverlap),
      ", unassigned=", length(OriginNonOriginMissing),
      "). They are being plotted exactly as saved.",
      call.=FALSE
    )
  }

  RatioColumns <- c("chrom", "chromStart", "chromEnd", Metrics)
  ReadRatioTable <- function(file, table_label){
    RatioHeader <- names(data.table::fread(
      file,
      header=TRUE,
      sep="\t",
      nrows=0L,
      showProgress=FALSE,
      data.table=TRUE
    ))
    MissingRatioColumns <- setdiff(RatioColumns, RatioHeader)
    if(length(MissingRatioColumns) > 0L){
      stop(
        table_label, " ratio table is missing required column(s): ",
        paste(MissingRatioColumns, collapse=", "), "\n", file,
        call.=FALSE
      )
    }
    Ratio <- data.table::fread(
      file,
      header=TRUE,
      sep="\t",
      select=RatioColumns,
      showProgress=FALSE,
      data.table=TRUE
    )
    if(nrow(Ratio) == 0L){
      stop(table_label, " ratio table is empty: ", file, call.=FALSE)
    }
    Ratio[, chrom := as.character(chrom)]
    for(column in setdiff(RatioColumns, "chrom")){
      data.table::set(Ratio, j=column, value=as.numeric(Ratio[[column]]))
    }
    if(any(!nzchar(Ratio$chrom)) ||
       any(!is.finite(Ratio$chromStart)) ||
       any(!is.finite(Ratio$chromEnd))){
      stop(
        table_label, " ratio table contains invalid genomic coordinates: ",
        file,
        call.=FALSE
      )
    }
    TableBinWidths <- Ratio$chromEnd-Ratio$chromStart
    if(any(!is.finite(TableBinWidths)) || any(TableBinWidths <= 0)){
      stop(
        table_label, " ratio table contains a non-positive genomic-window width: ",
        file,
        call.=FALSE
      )
    }
    BinWidthCounts <- data.table::data.table(binWidth=TableBinWidths)[
      , .N, by=binWidth
    ][order(-N, binWidth)]
    TableBinWidth <- as.numeric(BinWidthCounts$binWidth[[1]])
    MetricValues <- unlist(Ratio[, ..Metrics], use.names=FALSE)
    if(any(!is.finite(MetricValues))){
      stop(
        table_label, " ratio table contains a non-finite final metric value: ",
        file,
        call.=FALSE
      )
    }
    if(Log2Profile && any(MetricValues < 0)){
      stop(
        table_label,
        " ratio table contains a negative value, which cannot use Log2Profile: ",
        file,
        call.=FALSE
      )
    }
    if(anyDuplicated(Ratio[, .(chrom, chromStart)])){
      stop(
        table_label,
        " ratio table contains duplicated chrom/chromStart coordinates: ",
        file,
        call.=FALSE
      )
    }
    data.table::setorder(Ratio, chrom, chromStart)
    StepCounts <- Ratio[, .(
      delta=diff(sort(unique(chromStart)))
    ), by=chrom][delta > 0, .N, by=delta][order(-N, delta)]
    if(nrow(StepCounts) == 0L || !is.finite(StepCounts$delta[[1]]) ||
       StepCounts$delta[[1]] <= 0){
      stop(
        "Could not infer a positive sliding-window step from ",
        table_label, " ratio table: ", file,
        call.=FALSE
      )
    }
    TableStep <- as.numeric(StepCounts$delta[[1]])
    if(abs(TableStep-round(TableStep)) > sqrt(.Machine$double.eps)){
      stop(
        "The inferred sliding-window step in the ", table_label,
        " ratio table is not a whole number of base pairs.",
        call.=FALSE
      )
    }
    list(
      table=Ratio,
      step=as.integer(round(TableStep)),
      bin_width=TableBinWidth
    )
  }

  RatioResults <- lapply(
    names(RatioFiles),
    function(table_label){
      ReadRatioTable(RatioFiles[[table_label]], table_label)
    }
  )
  names(RatioResults) <- names(RatioFiles)
  RatioTables <- lapply(RatioResults, `[[`, "table")
  RatioSteps <- vapply(RatioResults, `[[`, integer(1), "step")
  RatioBinWidths <- vapply(RatioResults, `[[`, numeric(1), "bin_width")
  if(length(unique(RatioSteps)) != 1L){
    stop(
      "Watson and Crick ratio tables do not use the same sliding-window step.",
      call.=FALSE
    )
  }
  Step <- unname(RatioSteps[[1]])
  BinWidth <- unname(RatioBinWidths[[1]])
  if(StrandMode == "separated"){
    WatsonRatio <- RatioTables$watson
    CrickRatio <- RatioTables$crick
    CoordinatesMatch <-
      nrow(WatsonRatio) == nrow(CrickRatio) &&
      identical(WatsonRatio$chrom, CrickRatio$chrom) &&
      identical(WatsonRatio$chromStart, CrickRatio$chromStart) &&
      identical(WatsonRatio$chromEnd, CrickRatio$chromEnd)
    if(!CoordinatesMatch){
      stop(
        "Watson and Crick ratio-table coordinates do not match for ",
        SampleName, ".",
        call.=FALSE
      )
    }
  }
  if(abs(Window/Step-round(Window/Step)) > sqrt(.Machine$double.eps)){
    stop(
      "Window (", Window, " bp) must be an exact multiple of the inferred ",
      "sliding-window step (", Step, " bp).",
      call.=FALSE
    )
  }
  Offsets <- seq.int(-Window, Window, by=Step)
  OffsetRows <- seq.int(-Window/Step, Window/Step)
  Genomewide <- data.table::copy(Peaks$Genomewide)
  Genomewide[, peak_id := .I]

  MedianOrNA <- function(values){
    if(all(is.na(values))){
      NA_real_
    } else {
      stats::median(values, na.rm=TRUE)
    }
  }
  BuildProfilesFromRatio <- function(Ratio, table_label){
    ## Rsubread/malign tables can restart their sliding-window phase within a
    ## chromosome. Anchor to the nearest saved interval centre, then move through
    ## the saved row sequence. No genomic value is interpolated or zero-padded.
    Ratio <- data.table::copy(Ratio)
    Ratio[, ratioRow := seq_len(.N), by=chrom]
    Ratio[, binCenter := chromStart+(chromEnd-chromStart)/2]
    AnchorLookup <- Ratio[, .(
      chrom,
      anchorCenter=binCenter,
      anchorRow=ratioRow
    )]
    Anchors <- AnchorLookup[
      Genomewide,
      on=.(chrom, anchorCenter=peakSummit),
      roll="nearest",
      .(
        peak_id=i.peak_id,
        chrom=i.chrom,
        peakSummit=i.peakSummit,
        anchorRow,
        matchedCenter=x.anchorCenter
      )
    ]
    if(anyNA(Anchors$anchorRow)){
      MissingChromosomes <- unique(Anchors[is.na(anchorRow), chrom])
      stop(
        "Genomewide peaks refer to chromosome(s) absent from the ",
        table_label, " ratio table: ",
        paste(MissingChromosomes, collapse=", "),
        call.=FALSE
      )
    }
    Anchors[, anchorDistance := matchedCenter-peakSummit]
    Queries <- Anchors[, .(
      offset=Offsets,
      targetRow=anchorRow+OffsetRows
    ), by=.(peak_id, chrom)]
    Signal <- Ratio[
      Queries,
      on=.(chrom, ratioRow=targetRow),
      .(
        peak_id=i.peak_id,
        offset=i.offset,
        ip.score,
        ratio.ipin,
        ratio.ipnoise,
        ratio.ipin.noise
      )
    ]
    BuildProfile <- function(peak_class){
      ids <- PeakIds[[peak_class]]
      if(length(ids) == 0L){
        EmptyProfile <- data.table::data.table(
          offset=Offsets,
          n_contributing=integer(length(Offsets))
        )
        for(metric in Metrics){
          EmptyProfile[, (metric) := NA_real_]
        }
        data.table::setcolorder(
          EmptyProfile,
          c("offset", "n_contributing", Metrics)
        )
        return(EmptyProfile)
      }
      Profile <- Signal[peak_id %in% ids, c(
        list(n_contributing=sum(!is.na(ip.score))),
        lapply(.SD, MedianOrNA)
      ), by=offset, .SDcols=Metrics]
      FullOffsets <- data.table::data.table(offset=Offsets)
      Profile <- Profile[FullOffsets, on=.(offset)]
      data.table::setorder(Profile, offset)
      Profile
    }
    CohortProfiles <- lapply(PeakClasses, BuildProfile)
    names(CohortProfiles) <- PeakClasses
    list(profiles=CohortProfiles, anchors=Anchors)
  }

  ProfileResults <- lapply(
    names(RatioTables),
    function(table_label){
      BuildProfilesFromRatio(RatioTables[[table_label]], table_label)
    }
  )
  names(ProfileResults) <- names(RatioTables)
  Profiles <- if(StrandMode == "collapsed"){
    ProfileResults$collapsed$profiles
  } else {
    list(
      watson=ProfileResults$watson$profiles,
      crick=ProfileResults$crick$profiles
    )
  }
  AnchorsByTable <- lapply(ProfileResults, `[[`, "anchors")

  TransformProfileForDisplay <- function(values){
    values <- suppressWarnings(as.numeric(values))
    if(!Log2Profile){
      return(values)
    }
    Transformed <- rep(NA_real_, length(values))
    Finite <- is.finite(values)
    if(StrandMode == "separated"){
      Transformed[Finite] <- log2(1+values[Finite])
    } else {
      Positive <- Finite & values > 0
      Zero <- Finite & values == 0
      Transformed[Positive] <- log2(values[Positive])
      Transformed[Zero] <- 0
    }
    Transformed
  }
  DisplayMetricLabel <- function(metric){
    Label <- MetricLabels[[metric]]
    if(!Log2Profile){
      return(Label)
    }
    if(StrandMode == "separated"){
      paste0("log2(1 + ", Label, ")")
    } else {
      paste0("log2(", Label, ")")
    }
  }

  SmoothProfile <- function(x, y){
    Smooth <- rep(NA_real_, length(y))
    Good <- which(is.finite(x) & is.finite(y))
    if(length(Good) < 4L || length(unique(x[Good])) < 4L){
      Smooth[Good] <- y[Good]
      return(Smooth)
    }
    Fit <- try(
      stats::smooth.spline(x[Good], y[Good], spar=SmoothingSpar),
      silent=TRUE
    )
    if(inherits(Fit, "try-error")){
      Smooth[Good] <- y[Good]
    } else {
      Smooth[Good] <- Fit$y
    }
    Smooth
  }
  AddDistanceAxis <- function(){
    AxisAt <- seq(-Window, Window, length.out=9L)/1000
    AxisLabels <- signif(AxisAt, 2)
    AxisLabels[c(2L, 4L, 6L, 8L)] <- NA
    graphics::axis(
      1,
      at=AxisAt,
      labels=AxisLabels,
      las=1,
      cex.axis=0.90
    )
  }

  PrettyPeakClass <- function(peak_class){
    switch(
      peak_class,
      Genomewide="Genomewide",
      NonOrigin="Non-origin",
      Origin="Origin",
      EarlyOrigin="Early-origin",
      LateOrigin="Late-origin",
      peak_class
    )
  }
  ShortPeakClass <- function(peak_class){
    switch(
      peak_class,
      Genomewide="Gen",
      NonOrigin="NO",
      Origin="Ori",
      EarlyOrigin="E",
      LateOrigin="L",
      peak_class
    )
  }
  AddPageLabels <- function(title, page){
    graphics::mtext(
      title,
      outer=TRUE,
      side=3,
      line=1.1,
      font=2,
      cex=1.25,
      col="gray25"
    )
    graphics::mtext(
      paste0(SampleName, " | ", Assay, " | ", Alignment, " | ", StrandMode,
             " | ", TransformLabel,
             " | peak window +/-", format(Window, big.mark=","), " bp"),
      outer=TRUE,
      side=3,
      line=0.05,
      cex=0.78,
      col="gray40"
    )
    graphics::mtext(
      paste0("Page ", page, " of 4"),
      outer=TRUE,
      side=1,
      line=0.55,
      font=3,
      cex=0.82,
      col="gray40"
    )
  }
  PlotBlank <- function(){
    graphics::plot.new()
  }
  PlotEmptyProfile <- function(peak_class){
    graphics::plot(
      NA,
      xlim=c(-Window, Window)/1000,
      ylim=c(0, 1),
      axes=FALSE,
      xlab="",
      ylab="",
      bty="n"
    )
    graphics::text(
      0, 0.5,
      paste0("No peaks in\n", PrettyPeakClass(peak_class), " cohort"),
      cex=0.92,
      font=2,
      col="gray35"
    )
    graphics::box(col="gray85")
  }
  PlotProfile <- function(peak_class, metric){
    if(PeakCounts[[peak_class]] == 0L){
      PlotEmptyProfile(peak_class)
      return(invisible(NULL))
    }
    if(StrandMode == "collapsed"){
      Profile <- Profiles[[peak_class]]
      X <- Profile$offset/1000
      Y <- SmoothProfile(
        Profile$offset,
        TransformProfileForDisplay(Profile[[metric]])
      )
      ## Ratio metrics have a biological neutral reference (1, or 0 after
      ## log2 transformation). Raw coverage has no equivalent neutral value,
      ## so it must not be compressed by forcing zero into the y range.
      Baseline <- if(metric == "ip.score"){
        NA_real_
      } else if(Log2Profile){
        0
      } else {
        1
      }
      FiniteY <- Y[is.finite(Y)]
      if(length(FiniteY) == 0L){
        PlotEmptyProfile(peak_class)
        return(invisible(NULL))
      }
      YRange <- range(c(FiniteY, Baseline), finite=TRUE)
      YPad <- diff(YRange)*0.08
      if(!is.finite(YPad) || YPad == 0){
        YPad <- max(0.1, abs(YRange[[1]])*0.08)
      }
      YLim <- YRange+c(-YPad, YPad)
      graphics::plot(
        X,
        Y,
        type="l",
        lwd=2,
        col=ProfileColor,
        xlim=c(-Window, Window)/1000,
        ylim=YLim,
        xaxs="i",
        yaxs="i",
        las=1,
        bty="n",
        xaxt="n",
        xlab="Distance from summit (kb)",
        ylab=DisplayMetricLabel(metric),
        main=MetricTitles[[metric]],
        cex.main=1,
        cex.lab=0.90,
        cex.axis=0.90
      )
      if(is.finite(Baseline)){
        graphics::abline(h=Baseline, col="gray72", lwd=0.7, lty=2)
      }
      graphics::abline(v=0, col="gray72", lwd=0.7)
      AddDistanceAxis()
      graphics::legend(
        "topright",
        legend=PrettyPeakClass(peak_class),
        col=ProfileColor,
        lwd=2,
        bty="n",
        cex=0.82
      )
      return(invisible(NULL))
    }

    WatsonProfile <- Profiles$watson[[peak_class]]
    CrickProfile <- Profiles$crick[[peak_class]]
    X <- WatsonProfile$offset/1000
    WatsonY <- SmoothProfile(
      WatsonProfile$offset,
      TransformProfileForDisplay(WatsonProfile[[metric]])
    )
    CrickY <- -SmoothProfile(
      CrickProfile$offset,
      TransformProfileForDisplay(CrickProfile[[metric]])
    )
    FiniteY <- c(
      WatsonY[is.finite(WatsonY)],
      CrickY[is.finite(CrickY)],
      0
    )
    if(length(FiniteY) == 1L){
      PlotEmptyProfile(peak_class)
      return(invisible(NULL))
    }
    YMax <- max(abs(FiniteY), na.rm=TRUE)
    if(!is.finite(YMax) || YMax == 0){
      YMax <- 1
    }
    YLim <- c(-1, 1)*YMax*1.08
    graphics::plot(
      X,
      WatsonY,
      type="l",
      lwd=2,
      col=WatsonColor,
      xlim=c(-Window, Window)/1000,
      ylim=YLim,
      xaxs="i",
      yaxs="i",
      las=1,
      bty="n",
      xaxt="n",
      xlab="Distance from summit (kb)",
      ylab=DisplayMetricLabel(metric),
      main=MetricTitles[[metric]],
      cex.main=1,
      cex.lab=0.90,
      cex.axis=0.90
    )
    graphics::lines(X, CrickY, col=CrickColor, lwd=2)
    graphics::abline(h=0, col="gray62", lwd=0.75)
    graphics::abline(v=0, col="gray72", lwd=0.7)
    AddDistanceAxis()
    graphics::legend(
      "topright",
      legend=c(
        paste0(PrettyPeakClass(peak_class), " Watson (+)"),
        paste0(PrettyPeakClass(peak_class), " Crick (-)")
      ),
      col=c(WatsonColor, CrickColor),
      lwd=2,
      bty="n",
      cex=0.72
    )
  }
  PlotPair <- function(peak_class_1, peak_class_2){
    if(PeakCounts[[peak_class_1]] == 0L ||
       PeakCounts[[peak_class_2]] == 0L){
      graphics::plot(
        NA,
        xlim=c(-Window, Window)/1000,
        ylim=c(0, 1),
        axes=FALSE,
        xlab="",
        ylab="",
        bty="n"
      )
      graphics::text(
        0, 0.5,
        paste0(
          "Missing peak cohort:\n",
          PrettyPeakClass(peak_class_1), " vs ",
          PrettyPeakClass(peak_class_2)
        ),
        cex=0.9,
        font=2,
        col="gray35"
      )
      graphics::box(col="gray85")
      return(invisible(NULL))
    }
    X <- Offsets/1000
    if(StrandMode == "collapsed"){
      Y1 <- SmoothProfile(
        Profiles[[peak_class_1]]$offset,
        TransformProfileForDisplay(
          Profiles[[peak_class_1]][["ratio.ipin.noise"]]
        )
      )
      Y2 <- SmoothProfile(
        Profiles[[peak_class_2]]$offset,
        TransformProfileForDisplay(
          Profiles[[peak_class_2]][["ratio.ipin.noise"]]
        )
      )
      PairBaseline <- if(Log2Profile) 0 else 1
      FiniteY <- c(Y1[is.finite(Y1)], Y2[is.finite(Y2)], PairBaseline)
      YRange <- range(FiniteY, finite=TRUE)
      YPad <- diff(YRange)*0.08
      if(!is.finite(YPad) || YPad == 0){
        YPad <- max(0.1, abs(YRange[[1]])*0.08)
      }
      YLim <- YRange+c(-YPad, YPad)
      graphics::plot(
        X,
        Y1,
        type="l",
        lwd=2,
        col=PairColor1,
        xlim=c(-Window, Window)/1000,
        ylim=YLim,
        xaxs="i",
        yaxs="i",
        las=1,
        bty="n",
        xaxt="n",
        xlab="Distance from summit (kb)",
        ylab=DisplayMetricLabel("ratio.ipin.noise"),
        main=MetricTitles[["ratio.ipin.noise"]],
        cex.main=1,
        cex.lab=0.90,
        cex.axis=0.90
      )
      graphics::lines(X, Y2, col=PairColor2, lwd=2)
      graphics::abline(h=PairBaseline, col="gray72", lwd=0.7, lty=2)
      graphics::abline(v=0, col="gray72", lwd=0.7)
      AddDistanceAxis()
      graphics::legend(
        "topright",
        legend=c(
          ShortPeakClass(peak_class_1),
          ShortPeakClass(peak_class_2)
        ),
        col=c(PairColor1, PairColor2),
        lwd=2,
        bty="n",
        cex=0.72
      )
      return(invisible(NULL))
    }

    P1Watson <- Profiles$watson[[peak_class_1]]
    P1Crick <- Profiles$crick[[peak_class_1]]
    P2Watson <- Profiles$watson[[peak_class_2]]
    P2Crick <- Profiles$crick[[peak_class_2]]
    Y1Watson <- SmoothProfile(
      P1Watson$offset,
      TransformProfileForDisplay(P1Watson[["ratio.ipin.noise"]])
    )
    Y1Crick <- -SmoothProfile(
      P1Crick$offset,
      TransformProfileForDisplay(P1Crick[["ratio.ipin.noise"]])
    )
    Y2Watson <- SmoothProfile(
      P2Watson$offset,
      TransformProfileForDisplay(P2Watson[["ratio.ipin.noise"]])
    )
    Y2Crick <- -SmoothProfile(
      P2Crick$offset,
      TransformProfileForDisplay(P2Crick[["ratio.ipin.noise"]])
    )
    FiniteY <- c(
      Y1Watson[is.finite(Y1Watson)],
      Y1Crick[is.finite(Y1Crick)],
      Y2Watson[is.finite(Y2Watson)],
      Y2Crick[is.finite(Y2Crick)],
      0
    )
    YMax <- max(abs(FiniteY), na.rm=TRUE)
    if(!is.finite(YMax) || YMax == 0){
      YMax <- 1
    }
    YLim <- c(-1, 1)*YMax*1.08
    graphics::plot(
      X,
      Y1Watson,
      type="l",
      lwd=2,
      lty=1,
      col=WatsonColor,
      xlim=c(-Window, Window)/1000,
      ylim=YLim,
      xaxs="i",
      yaxs="i",
      las=1,
      bty="n",
      xaxt="n",
      xlab="Distance from summit (kb)",
      ylab=DisplayMetricLabel("ratio.ipin.noise"),
      main=MetricTitles[["ratio.ipin.noise"]],
      cex.main=1,
      cex.lab=0.90,
      cex.axis=0.90
    )
    graphics::lines(X, Y1Crick, col=CrickColor, lwd=2, lty=1)
    graphics::lines(X, Y2Watson, col=WatsonColor, lwd=2, lty=2)
    graphics::lines(X, Y2Crick, col=CrickColor, lwd=2, lty=2)
    graphics::abline(h=0, col="gray62", lwd=0.75)
    graphics::abline(v=0, col="gray72", lwd=0.7)
    AddDistanceAxis()
    graphics::legend(
      "topright",
      legend=c(
        paste0(ShortPeakClass(peak_class_1), " W"),
        paste0(ShortPeakClass(peak_class_1), " C"),
        paste0(ShortPeakClass(peak_class_2), " W"),
        paste0(ShortPeakClass(peak_class_2), " C")
      ),
      col=c(WatsonColor, CrickColor, WatsonColor, CrickColor),
      lty=c(1, 1, 2, 2),
      lwd=2,
      ncol=2,
      bty="n",
      cex=0.58
    )
  }

  OutputFile <- file.path(
    OutputDir,
    paste0(
      SampleName, "_", Assay, "_", Alignment,
      "_", StrandMode, "_",
      if(Log2Profile) "log2" else "linear",
      "_Peak_Enrichment.pdf"
    )
  )
  grDevices::pdf(
    OutputFile,
    width=PdfWidth,
    height=PdfHeight,
    useDingbats=FALSE
  )
  PdfDevice <- grDevices::dev.cur()
  on.exit({
    OpenDevices <- grDevices::dev.list()
    if(!is.null(OpenDevices) && PdfDevice %in% OpenDevices){
      grDevices::dev.off(which=PdfDevice)
    }
  }, add=TRUE)

  ## Page 1: five saved peak cohorts.
  graphics::par(oma=c(2.2, 1.0, 2.8, 1.0), mar=c(0, 0, 0, 0))
  graphics::layout(
    matrix(
      c(
        1, 1, 1, 1, 1, 1,
        2, 2, 2, 3, 3, 3,
        4, 4, 5, 5, 6, 6
      ),
      nrow=3,
      byrow=TRUE
    ),
    heights=c(0.62, 1.25, 1.25)
  )
  graphics::plot.new()
  graphics::text(
    0.5, 0.62,
    paste0("Experiment: ", SampleName),
    cex=1.65,
    font=2,
    family="serif"
  )
  graphics::text(
    0.5, 0.25,
    paste0(
      Assay, " | ", Alignment, " | ", StrandMode,
      " | ", TransformLabel, " primary-analysis peak cohorts"
    ),
    cex=1.05,
    font=3,
    family="serif",
    col="gray35"
  )
  PlotPeakCount <- function(peak_class){
    graphics::plot(
      NA,
      xlim=c(0, 1),
      ylim=c(0, 1),
      axes=FALSE,
      xlab="",
      ylab="",
      bty="n",
      xaxs="i",
      yaxs="i"
    )
    graphics::symbols(
      0.5, 0.48,
      circles=0.31,
      inches=FALSE,
      add=TRUE,
      fg=grDevices::adjustcolor(PeakColor, alpha.f=0.75),
      bg=grDevices::adjustcolor(PeakColor, alpha.f=0.32),
      lwd=2
    )
    graphics::text(
      0.5, 0.48,
      format(PeakCounts[[peak_class]], big.mark=","),
      cex=1.55,
      font=3,
      family="serif"
    )
    graphics::text(
      0.5, 0.93,
      PrettyPeakClass(peak_class),
      cex=1.05,
      font=2,
      family="serif"
    )
    if(peak_class != "Genomewide"){
      graphics::text(
        0.5, 0.06,
        paste0(
          formatC(
            100*PeakCounts[[peak_class]]/PeakCounts[["Genomewide"]],
            format="f",
            digits=1
          ),
          "% of Genomewide"
        ),
        cex=0.72,
        col="gray40"
      )
    }
  }
  for(peak_class in PeakClasses){
    PlotPeakCount(peak_class)
  }
  AddPageLabels("Saved peak cohorts", 1)

  ## Page 2: Genomewide, NonOrigin, and Origin by all four final metrics.
  graphics::par(
    mfrow=c(3, 4),
    oma=c(3, 1, 3, 1),
    mar=c(4, 4, 4, 2)+0.1
  )
  Page2Classes <- c("Genomewide", "NonOrigin", "Origin")
  for(peak_class in Page2Classes){
    for(metric in Metrics){
      PlotProfile(peak_class, metric)
    }
  }
  AddPageLabels(
    paste0(
      if(StrandMode == "separated") "Strand-separated" else "Collapsed",
      " peak-centred enrichment profiles"
    ),
    2
  )

  ## Page 3: EarlyOrigin and LateOrigin by all four final metrics.
  graphics::par(
    mfrow=c(3, 4),
    oma=c(3, 1, 3, 1),
    mar=c(4, 4, 4, 2)+0.1
  )
  Page3Classes <- c("EarlyOrigin", "LateOrigin")
  for(peak_class in Page3Classes){
    for(metric in Metrics){
      PlotProfile(peak_class, metric)
    }
  }
  for(index in seq_len(4L)){
    PlotBlank()
  }
  AddPageLabels(
    if(StrandMode == "separated"){
      "Strand-separated origin-timing peak enrichment profiles"
    } else {
      "Origin-timing peak enrichment profiles"
    },
    3
  )

  ## Page 4: legacy pairwise cohort comparisons using the final clean metric.
  graphics::par(
    mfrow=c(3, 4),
    oma=c(3, 1, 3, 1),
    mar=c(4, 4, 4, 2)+0.1
  )
  PairwiseClasses <- list(
    c("Origin", "NonOrigin"),
    c("EarlyOrigin", "NonOrigin"),
    c("Origin", "Genomewide"),
    c("EarlyOrigin", "LateOrigin")
  )
  for(pair in PairwiseClasses){
    PlotPair(pair[[1]], pair[[2]])
  }
  for(index in seq_len(8L)){
    PlotBlank()
  }
  AddPageLabels(
    if(StrandMode == "separated"){
      "Strand-separated pairwise clean enrichments in saved peak cohorts"
    } else {
      "Pairwise clean enrichments in saved peak cohorts"
    },
    4
  )

  grDevices::dev.off(which=PdfDevice)
  message("Peak-enrichment report saved: ", OutputFile)

  EarlyOutsideOrigin <- setdiff(PeakIds$EarlyOrigin, PeakIds$Origin)
  LateOutsideOrigin <- setdiff(PeakIds$LateOrigin, PeakIds$Origin)
  PeakAnchorDistance <- lapply(
    AnchorsByTable,
    function(anchors) summary(anchors$anchorDistance)
  )
  if(StrandMode == "collapsed"){
    PeakAnchorDistance <- PeakAnchorDistance$collapsed
  }
  invisible(list(
    pdf=OutputFile,
    sample_dir=SampleDir,
    sample_name=SampleName,
    assay=Assay,
    alignment=Alignment,
    strand_mode=StrandMode,
    log2_profile=Log2Profile,
    display_transform=TransformLabel,
    window=Window,
    step=Step,
    bin_width=BinWidth,
    ratio_steps=RatioSteps,
    bin_widths=RatioBinWidths,
    peak_anchor_distance=PeakAnchorDistance,
    ratio_file=if(StrandMode == "collapsed") unname(RatioFiles[[1]]) else NULL,
    ratio_files=RatioFiles,
    peak_files=PeakFiles,
    peak_counts=PeakCounts,
    peak_cohort_source="saved_primary_peak_files",
    cohort_checks=list(
      origin_nonorigin_overlap=length(OriginNonOriginOverlap),
      genomewide_unassigned=length(OriginNonOriginMissing),
      early_outside_origin=length(EarlyOutsideOrigin),
      late_outside_origin=length(LateOutsideOrigin)
    ),
    profiles=Profiles,
    metrics=Metrics,
    profile_statistic="median",
    edge_handling="missing chromosome-edge bins excluded; no zero padding",
    page_count=4L,
    primary_output_only=TRUE,
    plotter_operations=c(
      bam_reading=FALSE,
      coverage_reading=FALSE,
      simulation=FALSE,
      noise_estimation=FALSE,
      signal_filtering=FALSE,
      ratio_recalculation=FALSE,
      strand_collapsing=FALSE,
      peak_calling=FALSE,
      peak_reclassification=FALSE,
      pvalue_thresholding=FALSE
    ),
    display_operations=c(
      peak_centered_median=TRUE,
      spline_smoothing=TRUE,
      shared_pairwise_scale=TRUE,
      ratio_neutral_reference_line=TRUE,
      profile_rebasing=FALSE,
      raw_coverage_forced_to_zero=FALSE,
      watson_positive=StrandMode == "separated",
      crick_negative_mirroring=StrandMode == "separated",
      log_transformation=Log2Profile,
      separated_log1p=StrandMode == "separated" && Log2Profile
    )
  ))
}

## Genomic-element-centred ChIP/BrDU enrichment report. This is one
## self-contained public block; a separate run script can source this main
## script and call it directly. The function reads selected project-local
## processed genomic-element BED files and/or the selected sample's final saved
## peak BED files plus the final ratio table(s) written by the current primary
## analysis. It never reads BAM/coverage files, calls or re-filters peaks,
## simulates positions, estimates noise, filters signal, or recalculates a
## ratio. chrM, ORFs, and the custom rDNA annotation are excluded. Median
## element-centred profiles summarize the four final ratio-table metrics, and
## spline smoothing is display-only. Strand-separated profiles keep Watson
## positive and mirror Crick below zero. Log2Profile=FALSE preserves the
## untransformed display. Log2Profile=TRUE uses log2(x) for collapsed profiles
## and log2(1+x) for separated profiles so zero remains defined and strand
## orientation is preserved. Curated features are anchored at their BED
## interval midpoint; peak cohorts are anchored at the saved peakSummit. Both
## retain reference-coordinate order and minus-strand features are not
## reversed. Untransformed ratio panels mark 1 as the neutral reference (0
## after log2), without rebasing the saved ratios; raw coverage is data-scaled.
##
## Elements=NULL retains the complete curated-element report. Elements may also
## select any combination of curated classes and the sample-specific selectors
## GenomewidePeaks, NonOriginPeaks, OriginPeaks, EarlyOriginPeaks, and
## LateOriginPeaks. The report begins with selected-cohort counts, continues
## with three cohort rows per page and four metric columns, and adds a final
## paired page for any complete curated Early/Late, CTrans/WTrans, or
## Convergent/Divergent pair in the selection.
##
## Example:
## ChIP_BrDU_Genomic_Element_Enrichment_Plotter(
##   SampleDir="/path/to/sample-ChIP",
##   Assay="ChIP",
##   Alignment="generic",
##   StrandMode="collapsed",
##   Elements=c("EarlyOrigin", "LateOrigin", "OriginPeaks"),
##   Log2Profile=FALSE,
##   Window=3000
## )
ChIP_BrDU_Genomic_Element_Enrichment_Plotter <- function(
    SampleDir,
    Assay=c("ChIP", "BrDU"),
    Alignment=c("generic", "malign"),
    StrandMode=c("collapsed", "separated"),
    Log2Profile=FALSE,
    Window=3000,
    OutputDir=NULL,
    Elements=NULL){

  ## Fixed display contract. Cohort selection is public; display styling stays
  ## internal so the reports retain one consistent publication layout.
  Metrics <- c("ip.score", "ratio.ipin", "ratio.ipnoise", "ratio.ipin.noise")
  MetricLabels <- c(
    "IP coverage",
    "Enrichment over input",
    "Enrichment over noise",
    "Clean enrichment"
  )
  names(MetricLabels) <- Metrics
  CuratedElementClasses <- c(
    "ARS", "EarlyOrigin", "LateOrigin",
    "TER", "Ty", "tRNA",
    "Centromere", "Convergent", "Divergent",
    "CTrans", "WTrans"
  )
  PeakElementClasses <- c(
    "GenomewidePeaks", "NonOriginPeaks", "OriginPeaks",
    "EarlyOriginPeaks", "LateOriginPeaks"
  )
  PeakClassNames <- c(
    GenomewidePeaks="Genomewide",
    NonOriginPeaks="NonOrigin",
    OriginPeaks="Origin",
    EarlyOriginPeaks="EarlyOrigin",
    LateOriginPeaks="LateOrigin"
  )
  ValidElements <- c(CuratedElementClasses, PeakElementClasses)
  ElementPathKeys <- c(
    ARS="ars",
    EarlyOrigin="early_origins",
    LateOrigin="late_origins",
    TER="termination_regions",
    Ty="ty_elements",
    tRNA="trnas",
    Centromere="centromeres",
    Convergent="convergent_regions",
    Divergent="divergent_regions",
    CTrans="crick_transcribed_regions",
    WTrans="watson_transcribed_regions"
  )
  NuclearChromosomes <- paste0("chr", as.character(as.roman(seq_len(16L))))
  ElementColor <- "cornflowerblue"
  ProfileColor <- "darkorchid4"
  WatsonColor <- "brown3"
  CrickColor <- "cornflowerblue"
  PairColor1 <- grDevices::adjustcolor("darkorchid4", alpha.f=0.9)
  PairColor2 <- grDevices::adjustcolor("darkorange3", alpha.f=0.9)
  SmoothingSpar <- 0.5
  PdfWidth <- 12
  PdfHeight <- 10

  Assay <- match.arg(Assay)
  Alignment <- match.arg(Alignment)
  StrandMode <- match.arg(StrandMode)
  MetricTitles <- c(
    ip.score=Assay,
    ratio.ipin=paste0(Assay, " / Input"),
    ratio.ipnoise=paste0(Assay, " / Noise"),
    ratio.ipin.noise="Clean"
  )
  if(!is.logical(Log2Profile) || length(Log2Profile) != 1L ||
     is.na(Log2Profile)){
    stop("Log2Profile must be TRUE or FALSE.", call.=FALSE)
  }
  TransformLabel <- if(Log2Profile){
    if(StrandMode == "separated") "log2(1+x)" else "log2(x)"
  } else {
    "untransformed"
  }
  if(length(SampleDir) != 1L || is.na(SampleDir) || !nzchar(SampleDir)){
    stop("SampleDir must be one existing sample directory.", call.=FALSE)
  }
  if(!dir.exists(SampleDir)){
    stop("SampleDir does not exist: ", SampleDir, call.=FALSE)
  }
  SampleDir <- normalizePath(SampleDir, winslash="/", mustWork=TRUE)
  SampleName <- basename(SampleDir)

  if(is.null(Elements)){
    ElementClasses <- CuratedElementClasses
  } else {
    if(!is.character(Elements) || length(Elements) == 0L ||
       anyNA(Elements) || any(!nzchar(Elements))){
      stop("Elements must be NULL or contain supported element classes.", call.=FALSE)
    }
    if(anyDuplicated(Elements)){
      stop("Elements must not contain duplicated element classes.", call.=FALSE)
    }
    InvalidElements <- setdiff(Elements, ValidElements)
    if(length(InvalidElements) > 0L){
      stop(
        "Unsupported Elements value(s): ",
        paste(InvalidElements, collapse=", "),
        ". Supported values are: ",
        paste(ValidElements, collapse=", "),
        ".",
        call.=FALSE
      )
    }
    ElementClasses <- Elements
  }

  if(length(Window) != 1L || !is.numeric(Window) || !is.finite(Window) ||
     Window <= 0 || abs(Window-round(Window)) > sqrt(.Machine$double.eps)){
    stop("Window must be one positive whole number of base pairs.", call.=FALSE)
  }
  Window <- as.integer(round(Window))

  if(is.null(OutputDir)){
    OutputDir <- SampleDir
  }
  if(length(OutputDir) != 1L || is.na(OutputDir) || !nzchar(OutputDir)){
    stop("OutputDir must be NULL or one directory path.", call.=FALSE)
  }
  if(!dir.exists(OutputDir)){
    dir.create(OutputDir, recursive=TRUE, showWarnings=FALSE)
  }
  if(!dir.exists(OutputDir)){
    stop("Could not create OutputDir: ", OutputDir, call.=FALSE)
  }
  OutputDir <- normalizePath(OutputDir, winslash="/", mustWork=TRUE)

  if(!requireNamespace("data.table", quietly=TRUE)){
    stop(
      "The data.table package is required to read and summarize genomic-element profiles efficiently.",
      call.=FALSE
    )
  }

  ProjectPaths <- ChIP_BrDU_Project_Paths(check=TRUE)
  PeakDir <- file.path(
    SampleDir,
    if(Alignment == "generic") "Peaks" else "Peaks_ma"
  )
  ElementFiles <- setNames(
    vapply(
      ElementClasses,
      function(element_class){
        if(element_class %in% PeakElementClasses){
          file.path(
            PeakDir,
            paste0(
              SampleName, "_", PeakClassNames[[element_class]], "_Peaks.bed"
            )
          )
        } else {
          ProjectPaths$elements[[ElementPathKeys[[element_class]]]]
        }
      },
      character(1)
    ),
    ElementClasses
  )
  RatioFolder <- if(Alignment == "generic") "Ratios" else "Ratios_ma"
  RatioDir <- file.path(SampleDir, RatioFolder)
  CollapsedRatioFile <- file.path(
    RatioDir,
    paste0(SampleName, "_", Assay, "_collapsed.bed")
  )
  RatioFiles <- if(StrandMode == "collapsed"){
    c(collapsed=CollapsedRatioFile)
  } else {
    c(
      watson=file.path(
        RatioDir,
        paste0(SampleName, "_", Assay, "_watson.bed")
      ),
      crick=file.path(
        RatioDir,
        paste0(SampleName, "_", Assay, "_crick.bed")
      )
    )
  }
  RequiredFiles <- c(ElementFiles, RatioFiles)
  MissingFiles <- RequiredFiles[!file.exists(RequiredFiles)]
  if(length(MissingFiles) > 0L){
    stop(
      "Required support or primary-analysis output file(s) are missing:\n",
      paste(MissingFiles, collapse="\n"),
      call.=FALSE
    )
  }

  ReadElementFile <- function(file, element_class){
    Elements <- data.table::fread(
      file,
      header=TRUE,
      sep="\t",
      showProgress=FALSE,
      data.table=TRUE
    )
    IsPeakClass <- element_class %in% PeakElementClasses
    RequiredColumns <- if(IsPeakClass){
      c("chrom", "peakStart", "peakEnd", "peakSummit")
    } else {
      c("chrom", "chromStart", "chromEnd", "name", "score", "strand", "type")
    }
    MissingColumns <- setdiff(RequiredColumns, names(Elements))
    if(length(MissingColumns) > 0L){
      stop(
        PrettyElementClass(element_class),
        " annotation is missing required column(s): ",
        paste(MissingColumns, collapse=", "), "\n", file,
        call.=FALSE
      )
    }
    if(IsPeakClass){
      PeakNames <- if("oriName" %in% names(Elements)){
        as.character(Elements$oriName)
      } else {
        rep(NA_character_, nrow(Elements))
      }
      MissingNames <- is.na(PeakNames) | !nzchar(PeakNames)
      PeakNames[MissingNames] <- paste0(
        PeakClassNames[[element_class]], "Peak_", which(MissingNames)
      )
      Elements <- Elements[, .(
        chrom=as.character(chrom),
        chromStart=as.numeric(peakStart),
        chromEnd=as.numeric(peakEnd),
        name=PeakNames,
        strand=".",
        type=paste0(PeakClassNames[[element_class]], "Peak"),
        elementCenter=as.numeric(peakSummit)
      )]
    } else {
      Elements <- Elements[, .(
        chrom=as.character(chrom),
        chromStart=as.numeric(chromStart),
        chromEnd=as.numeric(chromEnd),
        name=as.character(name),
        strand=as.character(strand),
        type=as.character(type),
        elementCenter=(as.numeric(chromStart)+as.numeric(chromEnd))/2
      )]
    }
    ChrMOmitted <- sum(Elements$chrom == "chrM", na.rm=TRUE)
    Elements <- Elements[chrom != "chrM"]
    if(nrow(Elements) == 0L){
      stop(
        "No nuclear records remain in the ", PrettyElementClass(element_class),
        " annotation after excluding chrM: ", file,
        call.=FALSE
      )
    }
    CoordinateValues <- unlist(
      Elements[, .(chromStart, chromEnd)],
      use.names=FALSE
    )
    if(any(!nzchar(Elements$chrom)) || any(!is.finite(CoordinateValues)) ||
       any(Elements$chromStart < 0) ||
       any(Elements$chromEnd <= Elements$chromStart) ||
       any(!is.finite(Elements$elementCenter)) ||
       any(Elements$elementCenter < Elements$chromStart) ||
       any(Elements$elementCenter > Elements$chromEnd)){
      stop("Invalid nuclear element coordinates in: ", file, call.=FALSE)
    }
    UnexpectedChromosomes <- setdiff(unique(Elements$chrom), NuclearChromosomes)
    if(length(UnexpectedChromosomes) > 0L){
      stop(
        "Unexpected chromosome name(s) in ", file, ": ",
        paste(UnexpectedChromosomes, collapse=", "),
        call.=FALSE
      )
    }
    ElementKey <- paste(
      Elements$chrom, Elements$chromStart, Elements$chromEnd,
      Elements$elementCenter,
      sep="\r"
    )
    if(anyDuplicated(ElementKey)){
      stop(
        "Duplicated nuclear coordinates were found in the ",
        PrettyElementClass(element_class), " annotation: ", file,
        call.=FALSE
      )
    }
    data.table::setorder(Elements, chrom, elementCenter, chromStart, chromEnd)
    list(table=Elements, chrM_omitted=ChrMOmitted)
  }

  PrettyElementClass <- function(element_class){
    switch(
      element_class,
      ARS="ARS",
      EarlyOrigin="Early-firing origins",
      LateOrigin="Late-firing origins",
      TER="Termination regions",
      Ty="Ty elements",
      tRNA="tRNAs",
      Centromere="Centromeres",
      Convergent="Convergent regions",
      Divergent="Divergent regions",
      CTrans="Crick-transcribed regions",
      WTrans="Watson-transcribed regions",
      GenomewidePeaks="Genome-wide peaks",
      NonOriginPeaks="Non-origin peaks",
      OriginPeaks="Origin-associated peaks",
      EarlyOriginPeaks="Early-origin peaks",
      LateOriginPeaks="Late-origin peaks",
      element_class
    )
  }
  ShortElementClass <- function(element_class){
    switch(
      element_class,
      EarlyOrigin="E",
      LateOrigin="L",
      Convergent="Conv",
      Divergent="Div",
      CTrans="CTrans",
      WTrans="WTrans",
      GenomewidePeaks="All peaks",
      NonOriginPeaks="Non-origin",
      OriginPeaks="Origin peaks",
      EarlyOriginPeaks="Early peaks",
      LateOriginPeaks="Late peaks",
      PrettyElementClass(element_class)
    )
  }
  DistanceLabel <- function(element_class){
    if(element_class %in% PeakElementClasses){
      "Distance from peak summit (kb)"
    } else {
      "Distance from element midpoint (kb)"
    }
  }

  ElementResults <- lapply(
    ElementClasses,
    function(element_class){
      ReadElementFile(ElementFiles[[element_class]], element_class)
    }
  )
  names(ElementResults) <- ElementClasses
  Elements <- lapply(ElementResults, `[[`, "table")
  ElementCounts <- vapply(Elements, nrow, integer(1))
  ElementChrMOmitted <- vapply(ElementResults, `[[`, integer(1), "chrM_omitted")

  RatioColumns <- c("chrom", "chromStart", "chromEnd", Metrics)
  ReadRatioTable <- function(file, table_label){
    RatioHeader <- names(data.table::fread(
      file,
      header=TRUE,
      sep="\t",
      nrows=0L,
      showProgress=FALSE,
      data.table=TRUE
    ))
    MissingRatioColumns <- setdiff(RatioColumns, RatioHeader)
    if(length(MissingRatioColumns) > 0L){
      stop(
        table_label, " ratio table is missing required column(s): ",
        paste(MissingRatioColumns, collapse=", "), "\n", file,
        call.=FALSE
      )
    }
    Ratio <- data.table::fread(
      file,
      header=TRUE,
      sep="\t",
      select=RatioColumns,
      showProgress=FALSE,
      data.table=TRUE
    )
    if(nrow(Ratio) == 0L){
      stop(table_label, " ratio table is empty: ", file, call.=FALSE)
    }
    Ratio[, chrom := as.character(chrom)]
    for(column in setdiff(RatioColumns, "chrom")){
      data.table::set(Ratio, j=column, value=as.numeric(Ratio[[column]]))
    }
    if(any(!nzchar(Ratio$chrom)) ||
       any(!is.finite(Ratio$chromStart)) ||
       any(!is.finite(Ratio$chromEnd))){
      stop(
        table_label, " ratio table contains invalid genomic coordinates: ",
        file,
        call.=FALSE
      )
    }
    ChrMOmitted <- sum(Ratio$chrom == "chrM", na.rm=TRUE)
    Ratio <- Ratio[chrom != "chrM"]
    if(nrow(Ratio) == 0L){
      stop(
        table_label,
        " ratio table has no nuclear rows after excluding chrM: ", file,
        call.=FALSE
      )
    }
    TableBinWidths <- Ratio$chromEnd-Ratio$chromStart
    if(any(!is.finite(TableBinWidths)) || any(TableBinWidths <= 0)){
      stop(
        table_label, " ratio table contains a non-positive genomic-window width: ",
        file,
        call.=FALSE
      )
    }
    BinWidthCounts <- data.table::data.table(binWidth=TableBinWidths)[
      , .N, by=binWidth
    ][order(-N, binWidth)]
    TableBinWidth <- as.numeric(BinWidthCounts$binWidth[[1]])
    MetricValues <- unlist(Ratio[, ..Metrics], use.names=FALSE)
    if(any(!is.finite(MetricValues))){
      stop(
        table_label, " ratio table contains a non-finite nuclear metric value: ",
        file,
        call.=FALSE
      )
    }
    if(Log2Profile && any(MetricValues < 0)){
      stop(
        table_label,
        " ratio table contains a negative nuclear value, which cannot use Log2Profile: ",
        file,
        call.=FALSE
      )
    }
    if(anyDuplicated(Ratio[, .(chrom, chromStart)])){
      stop(
        table_label,
        " ratio table contains duplicated nuclear chrom/chromStart coordinates: ",
        file,
        call.=FALSE
      )
    }
    data.table::setorder(Ratio, chrom, chromStart)
    StepCounts <- Ratio[, .(
      delta=diff(sort(unique(chromStart)))
    ), by=chrom][delta > 0, .N, by=delta][order(-N, delta)]
    if(nrow(StepCounts) == 0L || !is.finite(StepCounts$delta[[1]]) ||
       StepCounts$delta[[1]] <= 0){
      stop(
        "Could not infer a positive sliding-window step from ",
        table_label, " ratio table: ", file,
        call.=FALSE
      )
    }
    TableStep <- as.numeric(StepCounts$delta[[1]])
    if(abs(TableStep-round(TableStep)) > sqrt(.Machine$double.eps)){
      stop(
        "The inferred sliding-window step in the ", table_label,
        " ratio table is not a whole number of base pairs.",
        call.=FALSE
      )
    }
    list(
      table=Ratio,
      step=as.integer(round(TableStep)),
      bin_width=TableBinWidth,
      chrM_omitted=ChrMOmitted
    )
  }

  RatioResults <- lapply(
    names(RatioFiles),
    function(table_label){
      ReadRatioTable(RatioFiles[[table_label]], table_label)
    }
  )
  names(RatioResults) <- names(RatioFiles)
  RatioTables <- lapply(RatioResults, `[[`, "table")
  RatioSteps <- vapply(RatioResults, `[[`, integer(1), "step")
  RatioBinWidths <- vapply(RatioResults, `[[`, numeric(1), "bin_width")
  RatioChrMOmitted <- vapply(RatioResults, `[[`, integer(1), "chrM_omitted")
  if(length(unique(RatioSteps)) != 1L){
    stop(
      "Watson and Crick ratio tables do not use the same sliding-window step.",
      call.=FALSE
    )
  }
  Step <- unname(RatioSteps[[1]])
  BinWidth <- unname(RatioBinWidths[[1]])
  if(StrandMode == "separated"){
    WatsonRatio <- RatioTables$watson
    CrickRatio <- RatioTables$crick
    CoordinatesMatch <-
      nrow(WatsonRatio) == nrow(CrickRatio) &&
      identical(WatsonRatio$chrom, CrickRatio$chrom) &&
      identical(WatsonRatio$chromStart, CrickRatio$chromStart) &&
      identical(WatsonRatio$chromEnd, CrickRatio$chromEnd)
    if(!CoordinatesMatch){
      stop(
        "Watson and Crick nuclear ratio-table coordinates do not match for ",
        SampleName, ".",
        call.=FALSE
      )
    }
  }
  if(abs(Window/Step-round(Window/Step)) > sqrt(.Machine$double.eps)){
    stop(
      "Window (", Window, " bp) must be an exact multiple of the inferred ",
      "sliding-window step (", Step, " bp).",
      call.=FALSE
    )
  }
  Offsets <- seq.int(-Window, Window, by=Step)
  OffsetRows <- seq.int(-Window/Step, Window/Step)
  AllElements <- data.table::rbindlist(
    lapply(
      ElementClasses,
      function(element_class){
        ElementTable <- data.table::copy(Elements[[element_class]])
        ElementTable[, element_class := element_class]
        ElementTable[, element_id := seq_len(.N)]
        ElementTable[, .(
          element_class,
          element_id,
          chrom,
          elementCenter
        )]
      }
    ),
    use.names=TRUE
  )

  MedianOrNA <- function(values){
    if(all(is.na(values))){
      NA_real_
    } else {
      stats::median(values, na.rm=TRUE)
    }
  }
  BuildProfilesFromRatio <- function(Ratio, table_label){
    ## Anchor every selected feature centre to the nearest saved interval centre,
    ## then move through that chromosome's saved row sequence. No genomic value
    ## is interpolated or zero-padded.
    Ratio <- data.table::copy(Ratio)
    Ratio[, ratioRow := seq_len(.N), by=chrom]
    Ratio[, binCenter := chromStart+(chromEnd-chromStart)/2]
    AnchorLookup <- Ratio[, .(
      chrom,
      anchorCenter=binCenter,
      anchorRow=ratioRow
    )]
    Anchors <- AnchorLookup[
      AllElements,
      on=.(chrom, anchorCenter=elementCenter),
      roll="nearest",
      .(
        element_class=i.element_class,
        element_id=i.element_id,
        chrom=i.chrom,
        elementCenter=i.elementCenter,
        anchorRow,
        matchedCenter=x.anchorCenter
      )
    ]
    if(anyNA(Anchors$anchorRow)){
      MissingChromosomes <- unique(Anchors[is.na(anchorRow), chrom])
      stop(
        "Genomic elements refer to chromosome(s) absent from the nuclear ",
        table_label, " ratio table: ",
        paste(MissingChromosomes, collapse=", "),
        call.=FALSE
      )
    }
    Anchors[, anchorDistance := matchedCenter-elementCenter]
    Queries <- Anchors[, .(
      offset=Offsets,
      targetRow=anchorRow+OffsetRows
    ), by=.(element_class, element_id, chrom)]
    Signal <- Ratio[
      Queries,
      on=.(chrom, ratioRow=targetRow),
      .(
        element_class=i.element_class,
        element_id=i.element_id,
        offset=i.offset,
        ip.score,
        ratio.ipin,
        ratio.ipnoise,
        ratio.ipin.noise
      )
    ]
    BuildProfile <- function(element_class){
      TargetClass <- element_class
      ClassSignal <- Signal[
        base::which(Signal$element_class == TargetClass)
      ]
      Profile <- ClassSignal[, c(
        list(n_contributing=sum(!is.na(ip.score))),
        lapply(.SD, MedianOrNA)
      ), by=offset, .SDcols=Metrics]
      FullOffsets <- data.table::data.table(offset=Offsets)
      Profile <- Profile[FullOffsets, on=.(offset)]
      data.table::setorder(Profile, offset)
      Profile
    }
    ElementProfiles <- lapply(ElementClasses, BuildProfile)
    names(ElementProfiles) <- ElementClasses
    list(profiles=ElementProfiles, anchors=Anchors)
  }

  ProfileResults <- lapply(
    names(RatioTables),
    function(table_label){
      BuildProfilesFromRatio(RatioTables[[table_label]], table_label)
    }
  )
  names(ProfileResults) <- names(RatioTables)
  Profiles <- if(StrandMode == "collapsed"){
    ProfileResults$collapsed$profiles
  } else {
    list(
      watson=ProfileResults$watson$profiles,
      crick=ProfileResults$crick$profiles
    )
  }
  AnchorsByTable <- lapply(ProfileResults, `[[`, "anchors")

  TransformProfileForDisplay <- function(values){
    values <- suppressWarnings(as.numeric(values))
    if(!Log2Profile){
      return(values)
    }
    Transformed <- rep(NA_real_, length(values))
    Finite <- is.finite(values)
    if(StrandMode == "separated"){
      Transformed[Finite] <- log2(1+values[Finite])
    } else {
      Positive <- Finite & values > 0
      Zero <- Finite & values == 0
      Transformed[Positive] <- log2(values[Positive])
      Transformed[Zero] <- 0
    }
    Transformed
  }
  DisplayMetricLabel <- function(metric){
    Label <- MetricLabels[[metric]]
    if(!Log2Profile){
      return(Label)
    }
    if(StrandMode == "separated"){
      paste0("log2(1 + ", Label, ")")
    } else {
      paste0("log2(", Label, ")")
    }
  }
  SmoothProfile <- function(x, y){
    Smooth <- rep(NA_real_, length(y))
    Good <- which(is.finite(x) & is.finite(y))
    if(length(Good) < 4L || length(unique(x[Good])) < 4L){
      Smooth[Good] <- y[Good]
      return(Smooth)
    }
    Fit <- try(
      stats::smooth.spline(x[Good], y[Good], spar=SmoothingSpar),
      silent=TRUE
    )
    if(inherits(Fit, "try-error")){
      Smooth[Good] <- y[Good]
    } else {
      Smooth[Good] <- Fit$y
    }
    Smooth
  }
  AddDistanceAxis <- function(){
    AxisAt <- seq(-Window, Window, length.out=9L)/1000
    AxisLabels <- signif(AxisAt, 2)
    AxisLabels[c(2L, 4L, 6L, 8L)] <- NA
    graphics::axis(
      1,
      at=AxisAt,
      labels=AxisLabels,
      las=1,
      cex.axis=0.90
    )
  }
  AddPageLabels <- function(title, page, page_count){
    graphics::mtext(
      title,
      outer=TRUE,
      side=3,
      line=1.1,
      font=2,
      cex=1.25,
      col="gray25"
    )
    graphics::mtext(
      paste0(SampleName, " | ", Assay, " | ", Alignment, " | ", StrandMode,
             " | ", TransformLabel,
             " | nuclear elements | centred window +/-",
             format(Window, big.mark=","), " bp"),
      outer=TRUE,
      side=3,
      line=0.05,
      cex=0.78,
      col="gray40"
    )
    graphics::mtext(
      paste0("Page ", page, " of ", page_count),
      outer=TRUE,
      side=1,
      line=0.55,
      font=3,
      cex=0.82,
      col="gray40"
    )
  }
  PlotBlank <- function(){
    graphics::plot.new()
  }
  PlotEmptyProfile <- function(element_class){
    graphics::plot(
      NA,
      xlim=c(-Window, Window)/1000,
      ylim=c(0, 1),
      axes=FALSE,
      xlab="",
      ylab="",
      bty="n"
    )
    graphics::text(
      0, 0.5,
      paste0("No nuclear elements in\n", PrettyElementClass(element_class)),
      cex=0.92,
      font=2,
      col="gray35"
    )
    graphics::box(col="gray85")
  }
  PlotProfile <- function(element_class, metric){
    if(ElementCounts[[element_class]] == 0L){
      PlotEmptyProfile(element_class)
      return(invisible(NULL))
    }
    if(StrandMode == "collapsed"){
      Profile <- Profiles[[element_class]]
      X <- Profile$offset/1000
      Y <- SmoothProfile(
        Profile$offset,
        TransformProfileForDisplay(Profile[[metric]])
      )
      ## Only ratio metrics have a neutral enrichment reference. Keeping raw
      ## coverage data-scaled restores the legacy panel shape and avoids
      ## compressing the profile merely to display zero.
      Baseline <- if(metric == "ip.score"){
        NA_real_
      } else if(Log2Profile){
        0
      } else {
        1
      }
      FiniteY <- Y[is.finite(Y)]
      if(length(FiniteY) == 0L){
        PlotEmptyProfile(element_class)
        return(invisible(NULL))
      }
      YRange <- range(c(FiniteY, Baseline), finite=TRUE)
      YPad <- diff(YRange)*0.08
      if(!is.finite(YPad) || YPad == 0){
        YPad <- max(0.1, abs(YRange[[1]])*0.08)
      }
      YLim <- YRange+c(-YPad, YPad)
      graphics::plot(
        X,
        Y,
        type="l",
        lwd=2,
        col=ProfileColor,
        xlim=c(-Window, Window)/1000,
        ylim=YLim,
        xaxs="i",
        yaxs="i",
        las=1,
        bty="n",
        xaxt="n",
        xlab=DistanceLabel(element_class),
        ylab=DisplayMetricLabel(metric),
        main=MetricTitles[[metric]],
        cex.main=1,
        cex.lab=0.90,
        cex.axis=0.90
      )
      if(is.finite(Baseline)){
        graphics::abline(h=Baseline, col="gray72", lwd=0.7, lty=2)
      }
      graphics::abline(v=0, col="gray72", lwd=0.7)
      AddDistanceAxis()
      graphics::legend(
        "topright",
        legend=PrettyElementClass(element_class),
        col=ProfileColor,
        lwd=2,
        bty="n",
        cex=0.82
      )
      return(invisible(NULL))
    }

    WatsonProfile <- Profiles$watson[[element_class]]
    CrickProfile <- Profiles$crick[[element_class]]
    X <- WatsonProfile$offset/1000
    WatsonY <- SmoothProfile(
      WatsonProfile$offset,
      TransformProfileForDisplay(WatsonProfile[[metric]])
    )
    CrickY <- -SmoothProfile(
      CrickProfile$offset,
      TransformProfileForDisplay(CrickProfile[[metric]])
    )
    FiniteY <- c(
      WatsonY[is.finite(WatsonY)],
      CrickY[is.finite(CrickY)],
      0
    )
    if(length(FiniteY) == 1L){
      PlotEmptyProfile(element_class)
      return(invisible(NULL))
    }
    YMax <- max(abs(FiniteY), na.rm=TRUE)
    if(!is.finite(YMax) || YMax == 0){
      YMax <- 1
    }
    YLim <- c(-1, 1)*YMax*1.08
    graphics::plot(
      X,
      WatsonY,
      type="l",
      lwd=2,
      col=WatsonColor,
      xlim=c(-Window, Window)/1000,
      ylim=YLim,
      xaxs="i",
      yaxs="i",
      las=1,
      bty="n",
      xaxt="n",
      xlab=DistanceLabel(element_class),
      ylab=DisplayMetricLabel(metric),
      main=MetricTitles[[metric]],
      cex.main=1,
      cex.lab=0.90,
      cex.axis=0.90
    )
    graphics::lines(X, CrickY, col=CrickColor, lwd=2)
    graphics::abline(h=0, col="gray62", lwd=0.75)
    graphics::abline(v=0, col="gray72", lwd=0.7)
    AddDistanceAxis()
    graphics::legend(
      "topright",
      legend=c(
        paste0(PrettyElementClass(element_class), " Watson (+)"),
        paste0(PrettyElementClass(element_class), " Crick (-)")
      ),
      col=c(WatsonColor, CrickColor),
      lwd=2,
      bty="n",
      cex=0.72
    )
  }
  PlotPair <- function(
      element_class_1,
      element_class_2,
      metric,
      show_legend=FALSE){
    X <- Offsets/1000
    if(StrandMode == "collapsed"){
      Y1 <- SmoothProfile(
        Profiles[[element_class_1]]$offset,
        TransformProfileForDisplay(Profiles[[element_class_1]][[metric]])
      )
      Y2 <- SmoothProfile(
        Profiles[[element_class_2]]$offset,
        TransformProfileForDisplay(Profiles[[element_class_2]][[metric]])
      )
      PairBaseline <- if(metric == "ip.score"){
        NA_real_
      } else if(Log2Profile){
        0
      } else {
        1
      }
      FiniteY <- c(Y1[is.finite(Y1)], Y2[is.finite(Y2)], PairBaseline)
      YRange <- range(FiniteY, finite=TRUE)
      YPad <- diff(YRange)*0.08
      if(!is.finite(YPad) || YPad == 0){
        YPad <- max(0.1, abs(YRange[[1]])*0.08)
      }
      YLim <- YRange+c(-YPad, YPad)
      graphics::plot(
        X,
        Y1,
        type="l",
        lwd=2,
        col=PairColor1,
        xlim=c(-Window, Window)/1000,
        ylim=YLim,
        xaxs="i",
        yaxs="i",
        las=1,
        bty="n",
        xaxt="n",
        xlab="Distance from element midpoint (kb)",
        ylab=DisplayMetricLabel(metric),
        main=MetricTitles[[metric]],
        cex.main=1,
        cex.lab=0.90,
        cex.axis=0.90
      )
      graphics::lines(X, Y2, col=PairColor2, lwd=2)
      if(is.finite(PairBaseline)){
        graphics::abline(h=PairBaseline, col="gray72", lwd=0.7, lty=2)
      }
      graphics::abline(v=0, col="gray72", lwd=0.7)
      AddDistanceAxis()
      if(isTRUE(show_legend)){
        graphics::legend(
          "topright",
          legend=c(
            ShortElementClass(element_class_1),
            ShortElementClass(element_class_2)
          ),
          col=c(PairColor1, PairColor2),
          lwd=2,
          bty="n",
          cex=0.68
        )
      }
      return(invisible(NULL))
    }

    P1Watson <- Profiles$watson[[element_class_1]]
    P1Crick <- Profiles$crick[[element_class_1]]
    P2Watson <- Profiles$watson[[element_class_2]]
    P2Crick <- Profiles$crick[[element_class_2]]
    Y1Watson <- SmoothProfile(
      P1Watson$offset,
      TransformProfileForDisplay(P1Watson[[metric]])
    )
    Y1Crick <- -SmoothProfile(
      P1Crick$offset,
      TransformProfileForDisplay(P1Crick[[metric]])
    )
    Y2Watson <- SmoothProfile(
      P2Watson$offset,
      TransformProfileForDisplay(P2Watson[[metric]])
    )
    Y2Crick <- -SmoothProfile(
      P2Crick$offset,
      TransformProfileForDisplay(P2Crick[[metric]])
    )
    FiniteY <- c(
      Y1Watson[is.finite(Y1Watson)],
      Y1Crick[is.finite(Y1Crick)],
      Y2Watson[is.finite(Y2Watson)],
      Y2Crick[is.finite(Y2Crick)],
      0
    )
    YMax <- max(abs(FiniteY), na.rm=TRUE)
    if(!is.finite(YMax) || YMax == 0){
      YMax <- 1
    }
    YLim <- c(-1, 1)*YMax*1.08
    graphics::plot(
      X,
      Y1Watson,
      type="l",
      lwd=2,
      lty=1,
      col=WatsonColor,
      xlim=c(-Window, Window)/1000,
      ylim=YLim,
      xaxs="i",
      yaxs="i",
      las=1,
      bty="n",
      xaxt="n",
      xlab="Distance from element midpoint (kb)",
      ylab=DisplayMetricLabel(metric),
      main=MetricTitles[[metric]],
      cex.main=1,
      cex.lab=0.90,
      cex.axis=0.90
    )
    graphics::lines(X, Y1Crick, col=CrickColor, lwd=2, lty=1)
    graphics::lines(X, Y2Watson, col=WatsonColor, lwd=2, lty=2)
    graphics::lines(X, Y2Crick, col=CrickColor, lwd=2, lty=2)
    graphics::abline(h=0, col="gray62", lwd=0.75)
    graphics::abline(v=0, col="gray72", lwd=0.7)
    AddDistanceAxis()
    if(isTRUE(show_legend)){
      graphics::legend(
        "topright",
        legend=c(
          paste0(ShortElementClass(element_class_1), " W"),
          paste0(ShortElementClass(element_class_1), " C"),
          paste0(ShortElementClass(element_class_2), " W"),
          paste0(ShortElementClass(element_class_2), " C")
        ),
        col=c(WatsonColor, CrickColor, WatsonColor, CrickColor),
        lty=c(1, 1, 2, 2),
        lwd=2,
        ncol=2,
        bty="n",
        cex=0.56
      )
    }
  }

  ElementPages <- split(
    ElementClasses,
    ceiling(seq_along(ElementClasses)/3)
  )
  PairwiseClasses <- Filter(
    function(pair) all(pair %in% ElementClasses),
    list(
      c("EarlyOrigin", "LateOrigin"),
      c("CTrans", "WTrans"),
      c("Convergent", "Divergent")
    )
  )
  PageCount <- 1L+length(ElementPages)+as.integer(length(PairwiseClasses) > 0L)
  ElementTag <- if(identical(ElementClasses, CuratedElementClasses)){
    "curated_elements"
  } else {
    paste(ElementClasses, collapse="-")
  }
  OutputFile <- file.path(
    OutputDir,
    paste0(
      SampleName, "_", Assay, "_", Alignment,
      "_", StrandMode, "_",
      if(Log2Profile) "log2" else "linear",
      "_", ElementTag,
      "_Genomic_Element_Enrichment.pdf"
    )
  )
  grDevices::pdf(
    OutputFile,
    width=PdfWidth,
    height=PdfHeight,
    useDingbats=FALSE
  )
  PdfDevice <- grDevices::dev.cur()
  on.exit({
    OpenDevices <- grDevices::dev.list()
    if(!is.null(OpenDevices) && PdfDevice %in% OpenDevices){
      grDevices::dev.off(which=PdfDevice)
    }
  }, add=TRUE)

  ## Page 1: all included nuclear genomic-element counts.
  OverviewRows <- as.integer(ceiling(length(ElementClasses)/4))
  graphics::par(
    mfrow=c(OverviewRows, 4),
    oma=c(2.1, 1.0, 3.8, 1.0),
    mar=c(0.45, 0.45, 1.3, 0.45)
  )
  PlotElementCount <- function(element_class){
    graphics::plot(
      NA,
      xlim=c(0, 1),
      ylim=c(0, 1),
      axes=FALSE,
      xlab="",
      ylab="",
      bty="n",
      xaxs="i",
      yaxs="i",
      main=PrettyElementClass(element_class),
      cex.main=0.94,
      font.main=2
    )
    graphics::symbols(
      0.5, 0.50,
      circles=0.29,
      inches=FALSE,
      add=TRUE,
      fg=grDevices::adjustcolor(ElementColor, alpha.f=0.75),
      bg=grDevices::adjustcolor(ElementColor, alpha.f=0.32),
      lwd=2
    )
    graphics::text(
      0.5, 0.50,
      format(ElementCounts[[element_class]], big.mark=","),
      cex=1.35,
      font=3,
      family="serif"
    )
  }
  for(element_class in ElementClasses){
    PlotElementCount(element_class)
  }
  MissingOverviewPanels <- OverviewRows*4L-length(ElementClasses)
  if(MissingOverviewPanels > 0L){
    for(index in seq_len(MissingOverviewPanels)) PlotBlank()
  }
  AddPageLabels("Included nuclear genomic-element cohorts", 1L, PageCount)

  ## Pages 2-5: three element classes per page and four metrics per row.
  CurrentPage <- 2L
  for(PageClasses in ElementPages){
    graphics::par(
      mfrow=c(3, 4),
      oma=c(3, 1, 3, 1),
      mar=c(4, 4, 4, 2)+0.1
    )
    for(element_class in PageClasses){
      for(metric in Metrics){
        PlotProfile(element_class, metric)
      }
    }
    MissingRows <- 3L-length(PageClasses)
    if(MissingRows > 0L){
      for(index in seq_len(MissingRows*length(Metrics))){
        PlotBlank()
      }
    }
    AddPageLabels(
      paste0(
        if(StrandMode == "separated") "Strand-separated" else "Collapsed",
        " genomic-element enrichment profiles"
      ),
      CurrentPage,
      PageCount
    )
    CurrentPage <- CurrentPage+1L
  }

  ## Final page: any complete curated pairs among the selected classes.
  if(length(PairwiseClasses) > 0L){
    graphics::par(
      mfrow=c(3, 4),
      oma=c(3, 1, 3, 1),
      mar=c(4, 4, 4, 2)+0.1
    )
    for(pair in PairwiseClasses){
      for(metric in Metrics){
        PlotPair(
          pair[[1]],
          pair[[2]],
          metric,
          show_legend=TRUE
        )
      }
    }
    MissingPairPanels <- (3L-length(PairwiseClasses))*length(Metrics)
    if(MissingPairPanels > 0L){
      for(index in seq_len(MissingPairPanels)) PlotBlank()
    }
    AddPageLabels(
      paste0(
        if(StrandMode == "separated") "Strand-separated" else "Collapsed",
        " paired genomic-element enrichment profiles"
      ),
      CurrentPage,
      PageCount
    )
  }

  grDevices::dev.off(which=PdfDevice)
  message("Genomic-element enrichment report saved: ", OutputFile)

  ElementAnchorDistance <- lapply(
    AnchorsByTable,
    function(anchors){
      setNames(
        lapply(
          ElementClasses,
          function(element_class){
            TargetClass <- element_class
            summary(
              anchors$anchorDistance[
                anchors$element_class == TargetClass
              ]
            )
          }
        ),
        ElementClasses
      )
    }
  )
  if(StrandMode == "collapsed"){
    ElementAnchorDistance <- ElementAnchorDistance$collapsed
  }
  invisible(list(
    pdf=OutputFile,
    sample_dir=SampleDir,
    sample_name=SampleName,
    assay=Assay,
    alignment=Alignment,
    strand_mode=StrandMode,
    log2_profile=Log2Profile,
    display_transform=TransformLabel,
    window=Window,
    step=Step,
    bin_width=BinWidth,
    ratio_steps=RatioSteps,
    bin_widths=RatioBinWidths,
    ratio_chrM_rows_omitted=RatioChrMOmitted,
    element_anchor_distance=ElementAnchorDistance,
    ratio_file=if(StrandMode == "collapsed") unname(RatioFiles[[1]]) else NULL,
    ratio_files=RatioFiles,
    element_files=ElementFiles,
    elements=ElementClasses,
    peak_element_selectors=intersect(ElementClasses, PeakElementClasses),
    element_counts=ElementCounts,
    element_chrM_records_omitted=ElementChrMOmitted,
    excluded_annotations=c("ORF", "rDNA"),
    chromosomes=NuclearChromosomes,
    chrM_excluded=TRUE,
    element_centering="curated BED interval midpoint or saved primary-analysis peakSummit; reference-coordinate order retained",
    profiles=Profiles,
    metrics=Metrics,
    profile_statistic="median",
    edge_handling="missing chromosome-edge bins excluded; no zero padding",
    page_count=PageCount,
    page_layout=list(
      overview=paste0(
        length(ElementClasses), " selected nuclear cohort(s) in a ",
        OverviewRows, " x 4 grid"
      ),
      individual="three element rows x four metric columns",
      pairwise="three paired rows x four metric columns"
    ),
    primary_ratio_output_only=TRUE,
    annotation_source="project-local processed genomic-element BED files and/or sample-specific primary-analysis peak BED files",
    plotter_operations=c(
      bam_reading=FALSE,
      coverage_reading=FALSE,
      simulation=FALSE,
      noise_estimation=FALSE,
      signal_filtering=FALSE,
      ratio_recalculation=FALSE,
      strand_collapsing=FALSE,
      peak_calling=FALSE,
      pvalue_thresholding=FALSE
    ),
    display_operations=c(
      element_midpoint_median=TRUE,
      reference_coordinate_orientation=TRUE,
      feature_strand_reversal=FALSE,
      spline_smoothing=TRUE,
      shared_pairwise_scale=TRUE,
      ratio_neutral_reference_line=TRUE,
      profile_rebasing=FALSE,
      raw_coverage_forced_to_zero=FALSE,
      watson_positive=StrandMode == "separated",
      crick_negative_mirroring=StrandMode == "separated",
      log_transformation=Log2Profile,
      separated_log1p=StrandMode == "separated" && Log2Profile
    )
  ))
}

## Strand-collapsed genomic-element boxplots for one ChIP or BrDU sample. This
## self-contained public block reads only selected processed project-local
## element annotations and/or final saved sample peak BEDs plus the final
## collapsed ratio table written by the current primary analysis. It never
## reads BAM/coverage files, simulates positions, estimates noise, filters
## signal, recalculates ratios, or calls/re-filters peaks.
##
## Every curated element is anchored at its BED midpoint; a selected peak cohort
## is anchored at its saved peakSummit. Each record is summarized by the
## arithmetic mean of the saved final metric values within +/-Window bp. Missing
## chromosome-edge bins are omitted without interpolation or zero padding. The
## statistical unit is therefore one genomic element, not one sliding-window
## row. chrM, ORFs, and the custom rDNA annotation are excluded.
##
## Metric="all" produces the established four-column organization: coverage,
## enrichment over input, enrichment over noise, and clean enrichment. Each
## selected element occupies one row; three rows are placed on each page. Box
## outliers and individual points are not drawn. Each metric column uses one
## whisker-based y-axis range across every selected element and page. Shared
## coordinates remain in their documented element cohorts for plotting but are
## excluded from between-cohort statistical tests and reported in the return.
##
## Example:
## ChIP_BrDU_Genomic_Element_Boxplotter(
##   SampleDir="/path/to/sample-ChIP",
##   Assay="ChIP",
##   Alignment="generic",
##   Elements=c("EarlyOrigin", "LateOrigin"),
##   Metric="all",
##   Window=500,
##   Log2Values=TRUE
## )
## Peak selectors: GenomewidePeaks, NonOriginPeaks, OriginPeaks,
## EarlyOriginPeaks, and LateOriginPeaks.
ChIP_BrDU_Genomic_Element_Boxplotter <- function(
    SampleDir,
    Assay=c("ChIP", "BrDU"),
    Alignment=c("generic", "malign"),
    Elements=c("EarlyOrigin", "LateOrigin"),
    Metric="all",
    Window=500,
    Log2Values=TRUE,
    OutputDir=NULL){

  AllMetrics <- c(
    "ip.score", "ratio.ipin", "ratio.ipnoise", "ratio.ipin.noise"
  )
  CuratedElements <- c(
    "ARS", "EarlyOrigin", "LateOrigin",
    "TER", "Ty", "tRNA",
    "Centromere", "Convergent", "Divergent",
    "CTrans", "WTrans"
  )
  PeakElements <- c(
    "GenomewidePeaks", "NonOriginPeaks", "OriginPeaks",
    "EarlyOriginPeaks", "LateOriginPeaks"
  )
  PeakClassNames <- c(
    GenomewidePeaks="Genomewide",
    NonOriginPeaks="NonOrigin",
    OriginPeaks="Origin",
    EarlyOriginPeaks="EarlyOrigin",
    LateOriginPeaks="LateOrigin"
  )
  ValidElements <- c(CuratedElements, PeakElements)
  ElementPathKeys <- c(
    ARS="ars",
    EarlyOrigin="early_origins",
    LateOrigin="late_origins",
    TER="termination_regions",
    Ty="ty_elements",
    tRNA="trnas",
    Centromere="centromeres",
    Convergent="convergent_regions",
    Divergent="divergent_regions",
    CTrans="crick_transcribed_regions",
    WTrans="watson_transcribed_regions"
  )
  MetricYLabels <- c(
    ip.score="Coverage",
    ratio.ipin="Enrichment over input",
    ratio.ipnoise="Enrichment over noise",
    ratio.ipin.noise="Clean enrichment"
  )
  ElementColors <- c(
    ARS="#4C78A8",
    EarlyOrigin="#6A1B9A",
    LateOrigin="#E07A1F",
    TER="#5B8E7D",
    Ty="#B85C5C",
    tRNA="#2A9D8F",
    Centromere="#8C6D31",
    Convergent="#5E60CE",
    Divergent="#F28482",
    CTrans="#5B8FF9",
    WTrans="#D1495B",
    GenomewidePeaks="#3B528B",
    NonOriginPeaks="#21918C",
    OriginPeaks="#5EC962",
    EarlyOriginPeaks="#6A1B9A",
    LateOriginPeaks="#E07A1F"
  )
  NuclearChromosomes <- paste0("chr", as.character(as.roman(seq_len(16L))))
  MaxRowsPerPage <- 3L

  Assay <- match.arg(Assay)
  Alignment <- match.arg(Alignment)
  if(!is.logical(Log2Values) || length(Log2Values) != 1L ||
     is.na(Log2Values)){
    stop("Log2Values must be TRUE or FALSE.", call.=FALSE)
  }
  if(length(SampleDir) != 1L || is.na(SampleDir) || !nzchar(SampleDir)){
    stop("SampleDir must be one existing sample directory.", call.=FALSE)
  }
  if(!dir.exists(SampleDir)){
    stop("SampleDir does not exist: ", SampleDir, call.=FALSE)
  }
  SampleDir <- normalizePath(SampleDir, winslash="/", mustWork=TRUE)
  SampleName <- basename(SampleDir)

  if(!is.character(Elements) || length(Elements) == 0L ||
     anyNA(Elements) || any(!nzchar(Elements))){
    stop("Elements must contain at least one supported element class.", call.=FALSE)
  }
  if(anyDuplicated(Elements)){
    stop("Elements must not contain duplicated element classes.", call.=FALSE)
  }
  InvalidElements <- setdiff(Elements, ValidElements)
  if(length(InvalidElements) > 0L){
    stop(
      "Unsupported Elements value(s): ",
      paste(InvalidElements, collapse=", "),
      ". Supported values are: ",
      paste(ValidElements, collapse=", "),
      ".",
      call.=FALSE
    )
  }

  if(!is.character(Metric) || length(Metric) == 0L ||
     anyNA(Metric) || any(!nzchar(Metric))){
    stop("Metric must be 'all' or one or more final ratio-table metrics.", call.=FALSE)
  }
  if(length(Metric) == 1L && identical(Metric, "all")){
    PlotMetrics <- AllMetrics
  } else {
    if("all" %in% Metric){
      stop("Metric='all' cannot be combined with named metrics.", call.=FALSE)
    }
    if(anyDuplicated(Metric)){
      stop("Metric must not contain duplicated metric names.", call.=FALSE)
    }
    InvalidMetrics <- setdiff(Metric, AllMetrics)
    if(length(InvalidMetrics) > 0L){
      stop(
        "Unsupported Metric value(s): ",
        paste(InvalidMetrics, collapse=", "),
        ". Supported values are: all, ",
        paste(AllMetrics, collapse=", "),
        ".",
        call.=FALSE
      )
    }
    PlotMetrics <- Metric
  }

  if(length(Window) != 1L || !is.numeric(Window) || !is.finite(Window) ||
     Window < 0 || abs(Window-round(Window)) > sqrt(.Machine$double.eps)){
    stop("Window must be one non-negative whole number of base pairs.", call.=FALSE)
  }
  Window <- as.integer(round(Window))

  if(is.null(OutputDir)){
    OutputDir <- SampleDir
  }
  if(length(OutputDir) != 1L || is.na(OutputDir) || !nzchar(OutputDir)){
    stop("OutputDir must be NULL or one directory path.", call.=FALSE)
  }
  if(!dir.exists(OutputDir)){
    dir.create(OutputDir, recursive=TRUE, showWarnings=FALSE)
  }
  if(!dir.exists(OutputDir)){
    stop("Could not create OutputDir: ", OutputDir, call.=FALSE)
  }
  OutputDir <- normalizePath(OutputDir, winslash="/", mustWork=TRUE)

  if(!requireNamespace("data.table", quietly=TRUE)){
    stop(
      "The data.table package is required to read and summarize genomic-element boxplots efficiently.",
      call.=FALSE
    )
  }

  PrettyElementClass <- function(element_class){
    switch(
      element_class,
      ARS="ARS",
      EarlyOrigin="Early-firing origins",
      LateOrigin="Late-firing origins",
      TER="Termination regions",
      Ty="Ty elements",
      tRNA="tRNAs",
      Centromere="Centromeres",
      Convergent="Convergent regions",
      Divergent="Divergent regions",
      CTrans="Crick-transcribed regions",
      WTrans="Watson-transcribed regions",
      GenomewidePeaks="Genome-wide peaks",
      NonOriginPeaks="Non-origin peaks",
      OriginPeaks="Origin-associated peaks",
      EarlyOriginPeaks="Early-origin peaks",
      LateOriginPeaks="Late-origin peaks",
      element_class
    )
  }
  ShortElementClass <- function(element_class){
    switch(
      element_class,
      EarlyOrigin="Early",
      LateOrigin="Late",
      Centromere="CEN",
      Convergent="Conv",
      Divergent="Div",
      CTrans="CTrans",
      WTrans="WTrans",
      GenomewidePeaks="All peaks",
      NonOriginPeaks="Non-origin",
      OriginPeaks="Origin peaks",
      EarlyOriginPeaks="Early peaks",
      LateOriginPeaks="Late peaks",
      PrettyElementClass(element_class)
    )
  }

  MetricTitles <- if(Assay == "BrDU"){
    c(
      ip.score="BrDU",
      ratio.ipin="BrDU / Input",
      ratio.ipnoise="BrDU / Noise",
      ratio.ipin.noise="Clean"
    )
  } else {
    c(
      ip.score="ChIP",
      ratio.ipin="ChIP / Input",
      ratio.ipnoise="ChIP / Noise",
      ratio.ipin.noise="Clean"
    )
  }

  ProjectPaths <- ChIP_BrDU_Project_Paths(check=TRUE)
  PeakDir <- file.path(
    SampleDir,
    if(Alignment == "generic") "Peaks" else "Peaks_ma"
  )
  ElementFiles <- setNames(
    vapply(
      Elements,
      function(element_class){
        if(element_class %in% PeakElements){
          file.path(
            PeakDir,
            paste0(
              SampleName, "_", PeakClassNames[[element_class]], "_Peaks.bed"
            )
          )
        } else {
          ProjectPaths$elements[[ElementPathKeys[[element_class]]]]
        }
      },
      character(1)
    ),
    Elements
  )
  RatioFolder <- if(Alignment == "generic") "Ratios" else "Ratios_ma"
  RatioFile <- file.path(
    SampleDir,
    RatioFolder,
    paste0(SampleName, "_", Assay, "_collapsed.bed")
  )
  RequiredFiles <- c(ElementFiles, ratio=RatioFile)
  MissingFiles <- RequiredFiles[!file.exists(RequiredFiles)]
  if(length(MissingFiles) > 0L){
    stop(
      "Required support or primary-analysis output file(s) are missing:\n",
      paste(MissingFiles, collapse="\n"),
      call.=FALSE
    )
  }

  ReadElementFile <- function(file, element_class){
    ElementTable <- data.table::fread(
      file,
      header=TRUE,
      sep="\t",
      showProgress=FALSE,
      data.table=TRUE
    )
    IsPeakClass <- element_class %in% PeakElements
    RequiredColumns <- if(IsPeakClass){
      c("chrom", "peakStart", "peakEnd", "peakSummit")
    } else {
      c("chrom", "chromStart", "chromEnd", "name")
    }
    MissingColumns <- setdiff(RequiredColumns, names(ElementTable))
    if(length(MissingColumns) > 0L){
      stop(
        PrettyElementClass(element_class),
        " annotation is missing required column(s): ",
        paste(MissingColumns, collapse=", "), "\n", file,
        call.=FALSE
      )
    }
    if(IsPeakClass){
      PeakNames <- if("oriName" %in% names(ElementTable)){
        as.character(ElementTable$oriName)
      } else {
        rep(NA_character_, nrow(ElementTable))
      }
      MissingNames <- is.na(PeakNames) | !nzchar(PeakNames)
      PeakNames[MissingNames] <- paste0(
        PeakClassNames[[element_class]], "Peak_", which(MissingNames)
      )
      ElementTable <- ElementTable[, .(
        chrom=as.character(chrom),
        chromStart=as.numeric(peakStart),
        chromEnd=as.numeric(peakEnd),
        element_name=PeakNames,
        elementCenter=as.numeric(peakSummit)
      )]
    } else {
      ElementTable <- ElementTable[, .(
        chrom=as.character(chrom),
        chromStart=as.numeric(chromStart),
        chromEnd=as.numeric(chromEnd),
        element_name=as.character(name),
        elementCenter=(as.numeric(chromStart)+as.numeric(chromEnd))/2
      )]
    }
    ChrMOmitted <- sum(ElementTable$chrom == "chrM", na.rm=TRUE)
    ElementTable <- ElementTable[chrom != "chrM"]
    if(nrow(ElementTable) == 0L){
      stop(
        "No nuclear records remain in the ",
        PrettyElementClass(element_class),
        " annotation after excluding chrM: ", file,
        call.=FALSE
      )
    }
    CoordinateValues <- unlist(
      ElementTable[, .(chromStart, chromEnd)],
      use.names=FALSE
    )
    if(any(!nzchar(ElementTable$chrom)) ||
       any(!is.finite(CoordinateValues)) ||
       any(ElementTable$chromStart < 0) ||
       any(ElementTable$chromEnd <= ElementTable$chromStart) ||
       any(!is.finite(ElementTable$elementCenter)) ||
       any(ElementTable$elementCenter < ElementTable$chromStart) ||
       any(ElementTable$elementCenter > ElementTable$chromEnd)){
      stop("Invalid nuclear element coordinates in: ", file, call.=FALSE)
    }
    ElementTable[, element_class := element_class]
    data.table::setorder(
      ElementTable,
      chrom,
      elementCenter,
      chromStart,
      chromEnd,
      element_name
    )
    ElementTable[, element_id := seq_len(.N)]
    ElementTable[, element_key := paste(
      chrom, chromStart, chromEnd, elementCenter, sep=":"
    )]
    list(table=ElementTable, chrM_omitted=ChrMOmitted)
  }

  ElementResults <- lapply(
    Elements,
    function(element_class){
      ReadElementFile(ElementFiles[[element_class]], element_class)
    }
  )
  names(ElementResults) <- Elements
  ElementTables <- lapply(ElementResults, `[[`, "table")
  ElementCounts <- vapply(ElementTables, nrow, integer(1))
  ElementChrMOmitted <- vapply(
    ElementResults,
    `[[`,
    integer(1),
    "chrM_omitted"
  )
  AllElements <- data.table::rbindlist(
    ElementTables,
    use.names=TRUE,
    fill=FALSE
  )

  RatioColumns <- c("chrom", "chromStart", "chromEnd", AllMetrics)
  RatioHeader <- names(data.table::fread(
    RatioFile,
    header=TRUE,
    sep="\t",
    nrows=0L,
    showProgress=FALSE,
    data.table=TRUE
  ))
  MissingRatioColumns <- setdiff(RatioColumns, RatioHeader)
  if(length(MissingRatioColumns) > 0L){
    stop(
      "Collapsed ratio table is missing required column(s): ",
      paste(MissingRatioColumns, collapse=", "), "\n", RatioFile,
      call.=FALSE
    )
  }
  Ratio <- data.table::fread(
    RatioFile,
    header=TRUE,
    sep="\t",
    select=RatioColumns,
    showProgress=FALSE,
    data.table=TRUE
  )
  if(nrow(Ratio) == 0L){
    stop("Collapsed ratio table is empty: ", RatioFile, call.=FALSE)
  }
  Ratio[, chrom := as.character(chrom)]
  for(column in setdiff(RatioColumns, "chrom")){
    data.table::set(Ratio, j=column, value=as.numeric(Ratio[[column]]))
  }
  if(any(!nzchar(Ratio$chrom)) ||
     any(!is.finite(Ratio$chromStart)) ||
     any(!is.finite(Ratio$chromEnd))){
    stop(
      "Collapsed ratio table contains invalid genomic coordinates: ",
      RatioFile,
      call.=FALSE
    )
  }
  RatioChrMOmitted <- sum(Ratio$chrom == "chrM", na.rm=TRUE)
  Ratio <- Ratio[chrom != "chrM"]
  if(nrow(Ratio) == 0L){
    stop(
      "Collapsed ratio table has no nuclear rows after excluding chrM: ",
      RatioFile,
      call.=FALSE
    )
  }
  BinWidths <- Ratio$chromEnd-Ratio$chromStart
  if(any(!is.finite(BinWidths)) || any(BinWidths <= 0)){
    stop(
      "Collapsed ratio table contains a non-positive genomic-window width: ",
      RatioFile,
      call.=FALSE
    )
  }
  BinWidthCounts <- data.table::data.table(bin_width=BinWidths)[
    , .N, by=bin_width
  ][order(-N, bin_width)]
  BinWidth <- as.numeric(BinWidthCounts$bin_width[[1]])
  MetricValues <- unlist(Ratio[, ..AllMetrics], use.names=FALSE)
  if(any(!is.finite(MetricValues))){
    stop(
      "Collapsed ratio table contains a non-finite nuclear metric value: ",
      RatioFile,
      call.=FALSE
    )
  }
  if(any(MetricValues < 0)){
    stop(
      "Collapsed ratio table contains a negative nuclear metric value: ",
      RatioFile,
      call.=FALSE
    )
  }
  if(anyDuplicated(Ratio[, .(chrom, chromStart)])){
    stop(
      "Collapsed ratio table contains duplicated nuclear chrom/chromStart coordinates: ",
      RatioFile,
      call.=FALSE
    )
  }
  data.table::setorder(Ratio, chrom, chromStart)
  StepCounts <- Ratio[, .(
    delta=diff(sort(unique(chromStart)))
  ), by=chrom][delta > 0, .N, by=delta][order(-N, delta)]
  if(nrow(StepCounts) == 0L || !is.finite(StepCounts$delta[[1]]) ||
     StepCounts$delta[[1]] <= 0){
    stop(
      "Could not infer a positive sliding-window step from collapsed ratio table: ",
      RatioFile,
      call.=FALSE
    )
  }
  Step <- as.numeric(StepCounts$delta[[1]])
  if(abs(Step-round(Step)) > sqrt(.Machine$double.eps)){
    stop(
      "The inferred sliding-window step is not a whole number of base pairs.",
      call.=FALSE
    )
  }
  Step <- as.integer(round(Step))
  if(abs(Window/Step-round(Window/Step)) > sqrt(.Machine$double.eps)){
    stop(
      "Window (", Window, " bp) must be an exact multiple of the inferred ",
      "sliding-window step (", Step, " bp).",
      call.=FALSE
    )
  }

  Offsets <- seq.int(-Window, Window, by=Step)
  OffsetRows <- seq.int(-Window/Step, Window/Step)
  Ratio[, ratioRow := seq_len(.N), by=chrom]
  Ratio[, binCenter := chromStart+(chromEnd-chromStart)/2]
  AnchorLookup <- Ratio[, .(
    chrom,
    anchorCenter=binCenter,
    anchorRow=ratioRow
  )]
  Anchors <- AnchorLookup[
    AllElements,
    on=.(chrom, anchorCenter=elementCenter),
    roll="nearest",
    .(
      element_class=i.element_class,
      element_id=i.element_id,
      element_key=i.element_key,
      element_name=i.element_name,
      chrom=i.chrom,
      chromStart=i.chromStart,
      chromEnd=i.chromEnd,
      elementCenter=i.elementCenter,
      anchorRow,
      matchedCenter=x.anchorCenter
    )
  ]
  if(anyNA(Anchors$anchorRow)){
    MissingChromosomes <- unique(Anchors[is.na(anchorRow), chrom])
    stop(
      "Selected genomic elements refer to chromosome(s) absent from the nuclear collapsed ratio table: ",
      paste(MissingChromosomes, collapse=", "),
      call.=FALSE
    )
  }
  Anchors[, anchorDistance := matchedCenter-elementCenter]
  Queries <- Anchors[, .(
    offset=Offsets,
    targetRow=anchorRow+OffsetRows
  ), by=.(
    element_class,
    element_id,
    element_key,
    element_name,
    chrom,
    chromStart,
    chromEnd,
    elementCenter
  )]
  Signal <- Ratio[
    Queries,
    on=.(chrom, ratioRow=targetRow),
    .(
      element_class=i.element_class,
      element_id=i.element_id,
      element_key=i.element_key,
      element_name=i.element_name,
      chrom=i.chrom,
      chromStart=i.chromStart,
      chromEnd=i.chromEnd,
      elementCenter=i.elementCenter,
      offset=i.offset,
      ip.score,
      ratio.ipin,
      ratio.ipnoise,
      ratio.ipin.noise
    )
  ]
  MeanOrNA <- function(values){
    if(all(is.na(values))){
      NA_real_
    } else {
      mean(values, na.rm=TRUE)
    }
  }
  ElementScores <- Signal[, c(
    list(n_bins=sum(!is.na(ip.score))),
    lapply(.SD, MeanOrNA)
  ), by=.(
    element_class,
    element_id,
    element_key,
    element_name,
    chrom,
    chromStart,
    chromEnd,
    elementCenter
  ), .SDcols=AllMetrics]
  ElementScores[, element_order := match(element_class, Elements)]
  data.table::setorder(
    ElementScores,
    element_order,
    chrom,
    elementCenter,
    element_id
  )
  ElementScores[, element_order := NULL]

  KeyMembership <- unique(ElementScores[, .(
    element_key,
    element_class,
    chrom,
    chromStart,
    chromEnd,
    element_name
  )])
  SharedKeys <- KeyMembership[, .(
    n_classes=data.table::uniqueN(element_class)
  ), by=element_key][n_classes > 1L, element_key]
  ElementScores[, shared_between_selected_classes := element_key %in% SharedKeys]
  SharedCoordinates <- KeyMembership[element_key %in% SharedKeys]
  SharedCoordinates[, element_order := match(element_class, Elements)]
  data.table::setorder(
    SharedCoordinates,
    chrom,
    chromStart,
    chromEnd,
    element_order
  )
  SharedCoordinates[, element_order := NULL]

  DisplayScores <- data.table::melt(
    ElementScores,
    id.vars=c(
      "element_class", "element_id", "element_key", "element_name",
      "chrom", "chromStart", "chromEnd", "elementCenter", "n_bins",
      "shared_between_selected_classes"
    ),
    measure.vars=PlotMetrics,
    variable.name="metric",
    value.name="raw_value",
    variable.factor=FALSE
  )
  DisplayScores[, display_value := raw_value]
  if(Log2Values){
    DisplayScores[metric == "ip.score", display_value := log2(1+raw_value)]
    DisplayScores[
      metric != "ip.score" & is.finite(raw_value) & raw_value > 0,
      display_value := log2(raw_value)
    ]
    DisplayScores[
      metric != "ip.score" & (!is.finite(raw_value) | raw_value <= 0),
      display_value := NA_real_
    ]
  }
  DisplayScores[, display_finite := is.finite(display_value)]

  DisplayMetricLabel <- function(metric){
    Label <- MetricYLabels[[metric]]
    if(!Log2Values){
      return(Label)
    }
    if(metric == "ip.score"){
      paste0("log2(1 + ", Label, ")")
    } else {
      paste0("log2(", Label, ")")
    }
  }
  MetricBaseline <- function(metric){
    if(metric == "ip.score"){
      NA_real_
    } else if(Log2Values){
      0
    } else {
      1
    }
  }

  BoxSummaries <- data.table::rbindlist(
    lapply(
      PlotMetrics,
      function(metric){
        TargetMetric <- metric
        data.table::rbindlist(
          lapply(
            Elements,
            function(element_class){
              TargetClass <- element_class
              Values <- DisplayScores[
                metric == TargetMetric &
                element_class == TargetClass &
                display_finite,
                display_value
              ]
              if(length(Values) == 0L){
                return(data.table::data.table(
                  element_class=TargetClass,
                  metric=TargetMetric,
                  n=0L,
                  whisker_low=NA_real_,
                  q1=NA_real_,
                  median=NA_real_,
                  q3=NA_real_,
                  whisker_high=NA_real_,
                  n_outliers=0L
                ))
              }
              BoxStats <- grDevices::boxplot.stats(
                Values,
                coef=1.5,
                do.conf=FALSE,
                do.out=TRUE
              )
              data.table::data.table(
                element_class=TargetClass,
                metric=TargetMetric,
                n=length(Values),
                whisker_low=BoxStats$stats[[1]],
                q1=BoxStats$stats[[2]],
                median=BoxStats$stats[[3]],
                q3=BoxStats$stats[[4]],
                whisker_high=BoxStats$stats[[5]],
                n_outliers=length(BoxStats$out)
              )
            }
          ),
          use.names=TRUE
        )
      }
    ),
    use.names=TRUE
  )

  YLimits <- setNames(
    lapply(
      PlotMetrics,
      function(metric){
        TargetMetric <- metric
        WhiskerValues <- unlist(
          BoxSummaries[metric == TargetMetric, .(
            whisker_low,
            whisker_high
          )],
          use.names=FALSE
        )
        WhiskerValues <- WhiskerValues[is.finite(WhiskerValues)]
        if(length(WhiskerValues) == 0L){
          stop(
            "No finite values remain for plotted metric: ",
            TargetMetric,
            call.=FALSE
          )
        }
        Baseline <- MetricBaseline(TargetMetric)
        LimitValues <- if(is.finite(Baseline)){
          c(WhiskerValues, Baseline)
        } else {
          WhiskerValues
        }
        Limits <- range(LimitValues)
        Span <- diff(Limits)
        Padding <- if(Span > 0){
          0.08*Span
        } else {
          max(0.5, abs(Limits[[1]])*0.10)
        }
        LowerLimit <- Limits[[1]]-Padding
        UpperLimit <- Limits[[2]]+Padding
        if(TargetMetric == "ip.score" && Limits[[1]] >= 0){
          LowerLimit <- max(0, LowerLimit)
        }
        c(LowerLimit, UpperLimit)
      }
    ),
    PlotMetrics
  )

  EmptyStatistics <- data.table::data.table(
    metric=character(),
    test=character(),
    group_1=character(),
    group_2=character(),
    n_1=integer(),
    n_2=integer(),
    statistic=numeric(),
    p_value=numeric(),
    p_adjust_method=character(),
    p_adjusted=numeric(),
    shared_coordinates_excluded=integer()
  )
  ComparisonStatistics <- EmptyStatistics
  if(length(Elements) >= 2L){
    TestScores <- DisplayScores[
      display_finite & !shared_between_selected_classes
    ]
    if(length(Elements) == 2L){
      StatisticsRows <- lapply(
        PlotMetrics,
        function(metric){
          TargetMetric <- metric
          Group1 <- Elements[[1]]
          Group2 <- Elements[[2]]
          Values1 <- TestScores[
            metric == TargetMetric & element_class == Group1,
            display_value
          ]
          Values2 <- TestScores[
            metric == TargetMetric & element_class == Group2,
            display_value
          ]
          if(length(Values1) < 2L || length(Values2) < 2L){
            TestStatistic <- NA_real_
            PValue <- NA_real_
          } else {
            TestResult <- suppressWarnings(stats::wilcox.test(
              Values1,
              Values2,
              paired=FALSE,
              exact=FALSE
            ))
            TestStatistic <- unname(TestResult$statistic)
            PValue <- TestResult$p.value
          }
          data.table::data.table(
            metric=TargetMetric,
            test="Wilcoxon rank-sum",
            group_1=Group1,
            group_2=Group2,
            n_1=length(Values1),
            n_2=length(Values2),
            statistic=TestStatistic,
            p_value=PValue,
            p_adjust_method="none",
            p_adjusted=PValue,
            shared_coordinates_excluded=length(SharedKeys)
          )
        }
      )
      ComparisonStatistics <- data.table::rbindlist(
        StatisticsRows,
        use.names=TRUE
      )
    } else {
      StatisticsRows <- lapply(
        PlotMetrics,
        function(metric){
          TargetMetric <- metric
          MetricScores <- TestScores[metric == TargetMetric]
          GroupSizes <- MetricScores[, .N, by=element_class]
          GroupsWithData <- Elements[Elements %in% GroupSizes[N >= 2L, element_class]]
          if(length(GroupsWithData) >= 2L){
            GlobalScores <- MetricScores[element_class %in% GroupsWithData]
            GlobalTest <- suppressWarnings(stats::kruskal.test(
              display_value ~ factor(element_class, levels=GroupsWithData),
              data=GlobalScores
            ))
            GlobalRow <- data.table::data.table(
              metric=TargetMetric,
              test="Kruskal-Wallis",
              group_1=paste(GroupsWithData, collapse=" | "),
              group_2=NA_character_,
              n_1=nrow(GlobalScores),
              n_2=NA_integer_,
              statistic=unname(GlobalTest$statistic),
              p_value=GlobalTest$p.value,
              p_adjust_method="none",
              p_adjusted=GlobalTest$p.value,
              shared_coordinates_excluded=length(SharedKeys)
            )
          } else {
            GlobalRow <- data.table::data.table(
              metric=TargetMetric,
              test="Kruskal-Wallis",
              group_1=paste(GroupsWithData, collapse=" | "),
              group_2=NA_character_,
              n_1=nrow(MetricScores),
              n_2=NA_integer_,
              statistic=NA_real_,
              p_value=NA_real_,
              p_adjust_method="none",
              p_adjusted=NA_real_,
              shared_coordinates_excluded=length(SharedKeys)
            )
          }
          Pairs <- if(length(GroupsWithData) >= 2L){
            utils::combn(GroupsWithData, 2L, simplify=FALSE)
          } else {
            list()
          }
          PairRows <- lapply(
            Pairs,
            function(groups){
              Values1 <- MetricScores[
                element_class == groups[[1]],
                display_value
              ]
              Values2 <- MetricScores[
                element_class == groups[[2]],
                display_value
              ]
              PairTest <- suppressWarnings(stats::wilcox.test(
                Values1,
                Values2,
                paired=FALSE,
                exact=FALSE
              ))
              data.table::data.table(
                metric=TargetMetric,
                test="Pairwise Wilcoxon rank-sum",
                group_1=groups[[1]],
                group_2=groups[[2]],
                n_1=length(Values1),
                n_2=length(Values2),
                statistic=unname(PairTest$statistic),
                p_value=PairTest$p.value,
                p_adjust_method="BH",
                p_adjusted=NA_real_,
                shared_coordinates_excluded=length(SharedKeys)
              )
            }
          )
          if(length(PairRows) > 0L){
            PairTable <- data.table::rbindlist(PairRows, use.names=TRUE)
            PairTable[, p_adjusted := stats::p.adjust(p_value, method="BH")]
            data.table::rbindlist(list(GlobalRow, PairTable), use.names=TRUE)
          } else {
            GlobalRow
          }
        }
      )
      ComparisonStatistics <- data.table::rbindlist(
        StatisticsRows,
        use.names=TRUE
      )
    }
  }

  ElementTag <- paste(Elements, collapse="-")
  MetricTag <- if(identical(PlotMetrics, AllMetrics)){
    "all_metrics"
  } else {
    paste(gsub("[^A-Za-z0-9]+", "", PlotMetrics), collapse="-")
  }
  ScaleTag <- if(Log2Values) "log2" else "linear"
  OutputFile <- file.path(
    OutputDir,
    paste0(
      SampleName, "_", Assay, "_", Alignment,
      "_collapsed_", ScaleTag, "_", ElementTag, "_", MetricTag,
      "_Genomic_Element_Boxplots.pdf"
    )
  )

  RowsPerPage <- min(MaxRowsPerPage, length(Elements))
  ElementPages <- split(
    Elements,
    ceiling(seq_along(Elements)/RowsPerPage)
  )
  PageCount <- length(ElementPages)
  NumberMetrics <- length(PlotMetrics)
  PdfWidth <- c(`1`=5.2, `2`=7.2, `3`=9.6, `4`=12.0)[[
    as.character(NumberMetrics)
  ]]
  PdfHeight <- c(`1`=4.5, `2`=7.2, `3`=10.0)[[
    as.character(RowsPerPage)
  ]]
  PdfWidth <- unname(PdfWidth)
  PdfHeight <- unname(PdfHeight)

  grDevices::pdf(
    OutputFile,
    width=PdfWidth,
    height=PdfHeight,
    useDingbats=FALSE
  )
  PdfDevice <- grDevices::dev.cur()
  on.exit({
    OpenDevices <- grDevices::dev.list()
    if(!is.null(OpenDevices) && PdfDevice %in% OpenDevices){
      grDevices::dev.off(which=PdfDevice)
    }
  }, add=TRUE)

  PlotBlank <- function(){
    graphics::plot.new()
  }
  PlotElementBox <- function(element_class, metric){
    TargetClass <- element_class
    TargetMetric <- metric
    Values <- DisplayScores[
      element_class == TargetClass &
      metric == TargetMetric &
      display_finite,
      display_value
    ]
    if(length(Values) == 0L){
      graphics::plot(
        NA,
        xlim=c(0, 1),
        ylim=YLimits[[TargetMetric]],
        axes=FALSE,
        xlab="",
        ylab="",
        bty="n"
      )
      graphics::text(
        0.5,
        mean(YLimits[[TargetMetric]]),
        paste0("No finite values\n", PrettyElementClass(TargetClass)),
        cex=0.88,
        font=2,
        col="gray40"
      )
      graphics::box(col="gray82")
      return(invisible(NULL))
    }
    graphics::boxplot(
      Values,
      outline=FALSE,
      ylim=YLimits[[TargetMetric]],
      main=paste0(
        ShortElementClass(TargetClass), ": ", MetricTitles[[TargetMetric]]
      ),
      names=paste0(
        ShortElementClass(TargetClass), "\n(n=", length(Values), ")"
      ),
      ylab=DisplayMetricLabel(TargetMetric),
      col=grDevices::adjustcolor(ElementColors[[TargetClass]], alpha.f=0.76),
      border=grDevices::adjustcolor(ElementColors[[TargetClass]], alpha.f=1),
      boxwex=0.46,
      staplewex=0.62,
      medlwd=1.8,
      whisklty=1,
      whisklwd=1.1,
      staplelwd=1.1,
      las=1,
      cex.axis=0.76,
      cex.names=0.78,
      cex.lab=0.82,
      cex.main=0.90,
      xaxt="n"
    )
    graphics::axis(
      side=1,
      at=1,
      labels=paste0(
        ShortElementClass(TargetClass), "\n(n=", length(Values), ")"
      ),
      tick=FALSE,
      line=0.15,
      cex.axis=0.78
    )
    Baseline <- MetricBaseline(TargetMetric)
    if(is.finite(Baseline)){
      graphics::abline(
        h=Baseline,
        col=grDevices::adjustcolor("gray35", alpha.f=0.65),
        lwd=0.75,
        lty=2
      )
    }
    graphics::box(col="gray45", lwd=0.75)
  }
  AddPageLabels <- function(page){
    graphics::mtext(
      "Genomic-element enrichment distributions",
      outer=TRUE,
      side=3,
      line=1.15,
      font=2,
      cex=1.25,
      col="gray22"
    )
    graphics::mtext(
      paste0(
        SampleName, " | ", Assay, " | ", Alignment,
        " | collapsed | ",
        if(Log2Values) "log2 display" else "untransformed display",
        " | centred window +/-", format(Window, big.mark=","), " bp"
      ),
      outer=TRUE,
      side=3,
      line=0.05,
      cex=0.76,
      col="gray40"
    )
    graphics::mtext(
      "Outlier points hidden; boxes show median and IQR; whiskers extend to 1.5 x IQR",
      outer=TRUE,
      side=1,
      line=0.82,
      cex=0.68,
      col="gray42"
    )
    graphics::mtext(
      paste0("Page ", page, " of ", PageCount),
      outer=TRUE,
      side=1,
      line=0.05,
      font=3,
      cex=0.72,
      col="gray42"
    )
  }

  for(PageIndex in seq_along(ElementPages)){
    PageElements <- ElementPages[[PageIndex]]
    graphics::par(
      mfrow=c(RowsPerPage, NumberMetrics),
      oma=c(2.45, 0.85, 3.65, 0.65),
      mar=c(3.45, 4.05, 2.15, 0.70),
      mgp=c(2.15, 0.62, 0),
      tcl=-0.22
    )
    for(RowIndex in seq_len(RowsPerPage)){
      if(RowIndex <= length(PageElements)){
        ElementClass <- PageElements[[RowIndex]]
        for(metric in PlotMetrics){
          PlotElementBox(ElementClass, metric)
        }
      } else {
        for(metric in PlotMetrics){
          PlotBlank()
        }
      }
    }
    AddPageLabels(PageIndex)
  }

  grDevices::dev.off(which=PdfDevice)
  message("Genomic-element boxplot report saved: ", OutputFile)

  invisible(list(
    pdf=OutputFile,
    sample_dir=SampleDir,
    sample_name=SampleName,
    assay=Assay,
    alignment=Alignment,
    strand_mode="collapsed",
    elements=Elements,
    metrics=PlotMetrics,
    window=Window,
    step=Step,
    bin_width=BinWidth,
    expected_bins_per_element=length(Offsets),
    log2_values=Log2Values,
    display_transform=if(Log2Values){
      "log2(1+x) for ip.score; log2(x) for ratio metrics"
    } else {
      "untransformed"
    },
    ratio_file=RatioFile,
    ratio_chrM_rows_omitted=RatioChrMOmitted,
    element_files=ElementFiles,
    peak_element_selectors=intersect(Elements, PeakElements),
    element_counts=ElementCounts,
    element_chrM_records_omitted=ElementChrMOmitted,
    element_scores=ElementScores,
    display_scores=DisplayScores,
    box_summaries=BoxSummaries,
    y_limits=YLimits,
    shared_coordinates=SharedCoordinates,
    comparison_statistics=ComparisonStatistics,
    excluded_annotations=c("ORF", "rDNA"),
    chromosomes=NuclearChromosomes,
    chrM_excluded=TRUE,
    element_centering="curated BED interval midpoint or saved primary-analysis peakSummit; nearest saved ratio-window centre",
    element_statistic="arithmetic mean of final saved metric values within the selected feature-centred window",
    edge_handling="missing chromosome-edge bins excluded; no interpolation or zero padding",
    outlier_points_plotted=FALSE,
    individual_points_plotted=FALSE,
    y_axis_basis="shared within each metric across selected elements; whiskers plus metric baseline",
    page_count=PageCount,
    rows_per_page=RowsPerPage,
    page_layout=paste0(
      RowsPerPage, " element row(s) x ", NumberMetrics,
      " metric column(s); maximum three element rows per page"
    ),
    primary_ratio_output_only=TRUE,
    annotation_source="project-local processed genomic-element BED files and/or sample-specific primary-analysis peak BED files",
    plotter_operations=c(
      bam_reading=FALSE,
      coverage_reading=FALSE,
      simulation=FALSE,
      noise_estimation=FALSE,
      signal_filtering=FALSE,
      ratio_recalculation=FALSE,
      strand_collapsing=FALSE,
      peak_calling=FALSE,
      pvalue_thresholding=FALSE
    ),
    display_operations=c(
      element_midpoint_window_mean=TRUE,
      log_transformation=Log2Values,
      outlier_points_hidden=TRUE,
      individual_points_hidden=TRUE,
      shared_metric_y_scale=TRUE
    )
  ))
}

## Publication-oriented genomic-element heatmaps for one strand-collapsed ChIP
## or BrDU sample. This self-contained public block reads only selected
## processed project-local element annotations and/or final saved sample peak
## BEDs plus the final collapsed ratio table written by the current primary
## analysis. It never reads BAM/coverage files, simulates positions, estimates
## noise, filters signal, recalculates ratios, collapses strands, calls or
## re-filters peaks, smooths profiles, or applies row-wise normalization.
##
## Each selected element cohort occupies one PDF page. Metric="all" produces
## four tall heatmaps in one horizontal row: coverage, enrichment over input,
## enrichment over noise, and clean enrichment. Rows are individual elements;
## columns are the saved primary-analysis intervals within +/-Window bp of the
## curated BED midpoint or saved peakSummit. Missing chromosome-edge bins remain
## unavailable, with no zero padding or interpolation. ORFs, rDNA, and chrM are
## excluded. Peak selectors are GenomewidePeaks, NonOriginPeaks, OriginPeaks,
## EarlyOriginPeaks, and LateOriginPeaks.
##
## By default, rows are ordered independently within each cohort by decreasing
## mean clean enrichment across the displayed window. OrderBy="genomic" retains
## nuclear chromosome and midpoint order; any of the four final metrics can be
## used instead. Every metric keeps one shared robust colour scale across all
## selected cohort pages. The 2nd and 98th percentiles define display-only
## saturation limits, while the returned matrices preserve the complete values.
##
## Example:
## ChIP_BrDU_Genomic_Element_Heatmap_Plotter(
##   SampleDir="/path/to/sample-ChIP",
##   Assay="ChIP",
##   Alignment="generic",
##   Elements=c("EarlyOrigin", "LateOrigin"),
##   Metric="all",
##   Window=3000,
##   Log2Values=TRUE,
##   OrderBy="ratio.ipin.noise"
## )
ChIP_BrDU_Genomic_Element_Heatmap_Plotter <- function(
    SampleDir,
    Assay=c("ChIP", "BrDU"),
    Alignment=c("generic", "malign"),
    Elements=c("EarlyOrigin", "LateOrigin"),
    Metric="all",
    Window=3000,
    Log2Values=TRUE,
    OrderBy="ratio.ipin.noise",
    OutputDir=NULL){

  AllMetrics <- c(
    "ip.score", "ratio.ipin", "ratio.ipnoise", "ratio.ipin.noise"
  )
  CuratedElements <- c(
    "ARS", "EarlyOrigin", "LateOrigin",
    "TER", "Ty", "tRNA",
    "Centromere", "Convergent", "Divergent",
    "CTrans", "WTrans"
  )
  PeakElements <- c(
    "GenomewidePeaks", "NonOriginPeaks", "OriginPeaks",
    "EarlyOriginPeaks", "LateOriginPeaks"
  )
  PeakClassNames <- c(
    GenomewidePeaks="Genomewide",
    NonOriginPeaks="NonOrigin",
    OriginPeaks="Origin",
    EarlyOriginPeaks="EarlyOrigin",
    LateOriginPeaks="LateOrigin"
  )
  ValidElements <- c(CuratedElements, PeakElements)
  ElementPathKeys <- c(
    ARS="ars",
    EarlyOrigin="early_origins",
    LateOrigin="late_origins",
    TER="termination_regions",
    Ty="ty_elements",
    tRNA="trnas",
    Centromere="centromeres",
    Convergent="convergent_regions",
    Divergent="divergent_regions",
    CTrans="crick_transcribed_regions",
    WTrans="watson_transcribed_regions"
  )
  MetricYLabels <- c(
    ip.score="Coverage",
    ratio.ipin="Enrichment over input",
    ratio.ipnoise="Enrichment over noise",
    ratio.ipin.noise="Clean enrichment"
  )
  NuclearChromosomes <- paste0("chr", as.character(as.roman(seq_len(16L))))
  RobustProbabilities <- c(0.02, 0.98)
  MissingColor <- "#E6E6E6"

  Assay <- match.arg(Assay)
  Alignment <- match.arg(Alignment)
  if(!is.logical(Log2Values) || length(Log2Values) != 1L ||
     is.na(Log2Values)){
    stop("Log2Values must be TRUE or FALSE.", call.=FALSE)
  }
  if(length(SampleDir) != 1L || is.na(SampleDir) || !nzchar(SampleDir)){
    stop("SampleDir must be one existing sample directory.", call.=FALSE)
  }
  if(!dir.exists(SampleDir)){
    stop("SampleDir does not exist: ", SampleDir, call.=FALSE)
  }
  SampleDir <- normalizePath(SampleDir, winslash="/", mustWork=TRUE)
  SampleName <- basename(SampleDir)

  if(!is.character(Elements) || length(Elements) == 0L ||
     anyNA(Elements) || any(!nzchar(Elements))){
    stop("Elements must contain at least one supported element class.", call.=FALSE)
  }
  if(anyDuplicated(Elements)){
    stop("Elements must not contain duplicated element classes.", call.=FALSE)
  }
  InvalidElements <- setdiff(Elements, ValidElements)
  if(length(InvalidElements) > 0L){
    stop(
      "Unsupported Elements value(s): ",
      paste(InvalidElements, collapse=", "),
      ". Supported values are: ",
      paste(ValidElements, collapse=", "),
      ".",
      call.=FALSE
    )
  }
  SelectedElements <- Elements

  if(!is.character(Metric) || length(Metric) == 0L ||
     anyNA(Metric) || any(!nzchar(Metric))){
    stop("Metric must be 'all' or one or more final ratio-table metrics.", call.=FALSE)
  }
  if(length(Metric) == 1L && identical(Metric, "all")){
    PlotMetrics <- AllMetrics
  } else {
    if("all" %in% Metric){
      stop("Metric='all' cannot be combined with named metrics.", call.=FALSE)
    }
    if(anyDuplicated(Metric)){
      stop("Metric must not contain duplicated metric names.", call.=FALSE)
    }
    InvalidMetrics <- setdiff(Metric, AllMetrics)
    if(length(InvalidMetrics) > 0L){
      stop(
        "Unsupported Metric value(s): ",
        paste(InvalidMetrics, collapse=", "),
        ". Supported values are: all, ",
        paste(AllMetrics, collapse=", "),
        ".",
        call.=FALSE
      )
    }
    PlotMetrics <- Metric
  }

  if(length(OrderBy) != 1L || !is.character(OrderBy) ||
     is.na(OrderBy) || !nzchar(OrderBy) ||
     !OrderBy %in% c("genomic", AllMetrics)){
    stop(
      "OrderBy must be 'genomic' or one final ratio-table metric: ",
      paste(AllMetrics, collapse=", "),
      ".",
      call.=FALSE
    )
  }
  if(length(Window) != 1L || !is.numeric(Window) || !is.finite(Window) ||
     Window <= 0 || abs(Window-round(Window)) > sqrt(.Machine$double.eps)){
    stop("Window must be one positive whole number of base pairs.", call.=FALSE)
  }
  Window <- as.integer(round(Window))

  if(is.null(OutputDir)){
    OutputDir <- SampleDir
  }
  if(length(OutputDir) != 1L || is.na(OutputDir) || !nzchar(OutputDir)){
    stop("OutputDir must be NULL or one directory path.", call.=FALSE)
  }
  if(!dir.exists(OutputDir)){
    dir.create(OutputDir, recursive=TRUE, showWarnings=FALSE)
  }
  if(!dir.exists(OutputDir)){
    stop("Could not create OutputDir: ", OutputDir, call.=FALSE)
  }
  OutputDir <- normalizePath(OutputDir, winslash="/", mustWork=TRUE)

  if(!requireNamespace("data.table", quietly=TRUE)){
    stop(
      "The data.table package is required to build genomic-element heatmaps efficiently.",
      call.=FALSE
    )
  }
  if(!requireNamespace("viridisLite", quietly=TRUE)){
    stop(
      "The viridisLite package is required for genomic-element heatmap colours.",
      call.=FALSE
    )
  }

  PrettyElementClass <- function(element_class){
    switch(
      element_class,
      ARS="ARS",
      EarlyOrigin="Early-firing origins",
      LateOrigin="Late-firing origins",
      TER="Termination regions",
      Ty="Ty elements",
      tRNA="tRNAs",
      Centromere="Centromeres",
      Convergent="Convergent regions",
      Divergent="Divergent regions",
      CTrans="Crick-transcribed regions",
      WTrans="Watson-transcribed regions",
      GenomewidePeaks="Genome-wide peaks",
      NonOriginPeaks="Non-origin peaks",
      OriginPeaks="Origin-associated peaks",
      EarlyOriginPeaks="Early-origin peaks",
      LateOriginPeaks="Late-origin peaks",
      element_class
    )
  }
  MetricTitles <- if(Assay == "BrDU"){
    c(
      ip.score="BrDU",
      ratio.ipin="BrDU / Input",
      ratio.ipnoise="BrDU / Noise",
      ratio.ipin.noise="Clean"
    )
  } else {
    c(
      ip.score="ChIP",
      ratio.ipin="ChIP / Input",
      ratio.ipnoise="ChIP / Noise",
      ratio.ipin.noise="Clean"
    )
  }

  ProjectPaths <- ChIP_BrDU_Project_Paths(check=TRUE)
  PeakDir <- file.path(
    SampleDir,
    if(Alignment == "generic") "Peaks" else "Peaks_ma"
  )
  ElementFiles <- setNames(
    vapply(
      SelectedElements,
      function(element_class){
        if(element_class %in% PeakElements){
          file.path(
            PeakDir,
            paste0(
              SampleName, "_", PeakClassNames[[element_class]], "_Peaks.bed"
            )
          )
        } else {
          ProjectPaths$elements[[ElementPathKeys[[element_class]]]]
        }
      },
      character(1)
    ),
    SelectedElements
  )
  RatioFolder <- if(Alignment == "generic") "Ratios" else "Ratios_ma"
  RatioFile <- file.path(
    SampleDir,
    RatioFolder,
    paste0(SampleName, "_", Assay, "_collapsed.bed")
  )
  RequiredFiles <- c(ElementFiles, ratio=RatioFile)
  MissingFiles <- RequiredFiles[!file.exists(RequiredFiles)]
  if(length(MissingFiles) > 0L){
    stop(
      "Required support or primary-analysis output file(s) are missing:\n",
      paste(MissingFiles, collapse="\n"),
      call.=FALSE
    )
  }

  ReadElementFile <- function(file, element_class){
    ElementTable <- data.table::fread(
      file,
      header=TRUE,
      sep="\t",
      showProgress=FALSE,
      data.table=TRUE
    )
    IsPeakClass <- element_class %in% PeakElements
    RequiredColumns <- if(IsPeakClass){
      c("chrom", "peakStart", "peakEnd", "peakSummit")
    } else {
      c("chrom", "chromStart", "chromEnd", "name")
    }
    MissingColumns <- setdiff(RequiredColumns, names(ElementTable))
    if(length(MissingColumns) > 0L){
      stop(
        PrettyElementClass(element_class),
        " annotation is missing required column(s): ",
        paste(MissingColumns, collapse=", "), "\n", file,
        call.=FALSE
      )
    }
    if(IsPeakClass){
      PeakNames <- if("oriName" %in% names(ElementTable)){
        as.character(ElementTable$oriName)
      } else {
        rep(NA_character_, nrow(ElementTable))
      }
      MissingNames <- is.na(PeakNames) | !nzchar(PeakNames)
      PeakNames[MissingNames] <- paste0(
        PeakClassNames[[element_class]], "Peak_", which(MissingNames)
      )
      ElementTable <- ElementTable[, .(
        chrom=as.character(chrom),
        chromStart=as.numeric(peakStart),
        chromEnd=as.numeric(peakEnd),
        element_name=PeakNames,
        elementCenter=as.numeric(peakSummit)
      )]
    } else {
      ElementTable <- ElementTable[, .(
        chrom=as.character(chrom),
        chromStart=as.numeric(chromStart),
        chromEnd=as.numeric(chromEnd),
        element_name=as.character(name),
        elementCenter=(as.numeric(chromStart)+as.numeric(chromEnd))/2
      )]
    }
    ChrMOmitted <- sum(ElementTable$chrom == "chrM", na.rm=TRUE)
    ElementTable <- ElementTable[chrom != "chrM"]
    if(nrow(ElementTable) == 0L){
      stop(
        "No nuclear records remain in the ",
        PrettyElementClass(element_class),
        " annotation after excluding chrM: ", file,
        call.=FALSE
      )
    }
    Coordinates <- unlist(
      ElementTable[, .(chromStart, chromEnd)],
      use.names=FALSE
    )
    if(any(!nzchar(ElementTable$chrom)) ||
       any(!is.finite(Coordinates)) ||
       any(ElementTable$chromStart < 0) ||
       any(ElementTable$chromEnd <= ElementTable$chromStart) ||
       any(!is.finite(ElementTable$elementCenter)) ||
       any(ElementTable$elementCenter < ElementTable$chromStart) ||
       any(ElementTable$elementCenter > ElementTable$chromEnd)){
      stop("Invalid nuclear element coordinates in: ", file, call.=FALSE)
    }
    ElementTable[, chromosome_order := match(chrom, NuclearChromosomes)]
    if(anyNA(ElementTable$chromosome_order)){
      BadChromosomes <- unique(ElementTable[is.na(chromosome_order), chrom])
      stop(
        PrettyElementClass(element_class),
        " annotation contains unsupported nuclear chromosome name(s): ",
        paste(BadChromosomes, collapse=", "),
        call.=FALSE
      )
    }
    data.table::setorder(
      ElementTable,
      chromosome_order,
      elementCenter,
      chromStart,
      chromEnd,
      element_name
    )
    ElementTable[, element_class := element_class]
    ElementTable[, element_id := seq_len(.N)]
    ElementTable[, element_key := paste(
      chrom, chromStart, chromEnd, elementCenter, sep=":"
    )]
    list(table=ElementTable, chrM_omitted=ChrMOmitted)
  }

  ElementResults <- lapply(
    SelectedElements,
    function(element_class){
      ReadElementFile(ElementFiles[[element_class]], element_class)
    }
  )
  names(ElementResults) <- SelectedElements
  ElementTables <- lapply(ElementResults, `[[`, "table")
  ElementCounts <- vapply(ElementTables, nrow, integer(1))
  ElementChrMOmitted <- vapply(
    ElementResults,
    `[[`,
    integer(1),
    "chrM_omitted"
  )
  AllElements <- data.table::rbindlist(
    ElementTables,
    use.names=TRUE,
    fill=FALSE
  )

  RatioColumns <- c("chrom", "chromStart", "chromEnd", AllMetrics)
  RatioHeader <- names(data.table::fread(
    RatioFile,
    header=TRUE,
    sep="\t",
    nrows=0L,
    showProgress=FALSE,
    data.table=TRUE
  ))
  MissingRatioColumns <- setdiff(RatioColumns, RatioHeader)
  if(length(MissingRatioColumns) > 0L){
    stop(
      "Collapsed ratio table is missing required column(s): ",
      paste(MissingRatioColumns, collapse=", "), "\n", RatioFile,
      call.=FALSE
    )
  }
  Ratio <- data.table::fread(
    RatioFile,
    header=TRUE,
    sep="\t",
    select=RatioColumns,
    showProgress=FALSE,
    data.table=TRUE
  )
  if(nrow(Ratio) == 0L){
    stop("Collapsed ratio table is empty: ", RatioFile, call.=FALSE)
  }
  Ratio[, chrom := as.character(chrom)]
  for(column in setdiff(RatioColumns, "chrom")){
    data.table::set(Ratio, j=column, value=as.numeric(Ratio[[column]]))
  }
  if(any(!nzchar(Ratio$chrom)) ||
     any(!is.finite(Ratio$chromStart)) ||
     any(!is.finite(Ratio$chromEnd))){
    stop(
      "Collapsed ratio table contains invalid genomic coordinates: ",
      RatioFile,
      call.=FALSE
    )
  }
  RatioChrMOmitted <- sum(Ratio$chrom == "chrM", na.rm=TRUE)
  Ratio <- Ratio[chrom != "chrM"]
  if(nrow(Ratio) == 0L){
    stop(
      "Collapsed ratio table has no nuclear rows after excluding chrM: ",
      RatioFile,
      call.=FALSE
    )
  }
  BinWidths <- Ratio$chromEnd-Ratio$chromStart
  if(any(!is.finite(BinWidths)) || any(BinWidths <= 0)){
    stop(
      "Collapsed ratio table contains a non-positive genomic-window width: ",
      RatioFile,
      call.=FALSE
    )
  }
  BinWidthCounts <- data.table::data.table(bin_width=BinWidths)[
    , .N, by=bin_width
  ][order(-N, bin_width)]
  BinWidth <- as.numeric(BinWidthCounts$bin_width[[1]])
  MetricValues <- unlist(Ratio[, ..AllMetrics], use.names=FALSE)
  if(any(!is.finite(MetricValues))){
    stop(
      "Collapsed ratio table contains a non-finite nuclear metric value: ",
      RatioFile,
      call.=FALSE
    )
  }
  if(any(MetricValues < 0)){
    stop(
      "Collapsed ratio table contains a negative nuclear metric value: ",
      RatioFile,
      call.=FALSE
    )
  }
  if(anyDuplicated(Ratio[, .(chrom, chromStart)])){
    stop(
      "Collapsed ratio table contains duplicated nuclear chrom/chromStart coordinates: ",
      RatioFile,
      call.=FALSE
    )
  }
  data.table::setorder(Ratio, chrom, chromStart)
  StepCounts <- Ratio[, .(
    delta=diff(sort(unique(chromStart)))
  ), by=chrom][delta > 0, .N, by=delta][order(-N, delta)]
  if(nrow(StepCounts) == 0L || !is.finite(StepCounts$delta[[1]]) ||
     StepCounts$delta[[1]] <= 0){
    stop(
      "Could not infer a positive sliding-window step from collapsed ratio table: ",
      RatioFile,
      call.=FALSE
    )
  }
  Step <- as.numeric(StepCounts$delta[[1]])
  if(abs(Step-round(Step)) > sqrt(.Machine$double.eps)){
    stop(
      "The inferred sliding-window step is not a whole number of base pairs.",
      call.=FALSE
    )
  }
  Step <- as.integer(round(Step))
  if(abs(Window/Step-round(Window/Step)) > sqrt(.Machine$double.eps)){
    stop(
      "Window (", Window, " bp) must be an exact multiple of the inferred ",
      "sliding-window step (", Step, " bp).",
      call.=FALSE
    )
  }

  Offsets <- seq.int(-Window, Window, by=Step)
  OffsetRows <- seq.int(-Window/Step, Window/Step)
  Ratio[, ratioRow := seq_len(.N), by=chrom]
  Ratio[, binCenter := chromStart+(chromEnd-chromStart)/2]
  AnchorLookup <- Ratio[, .(
    chrom,
    anchorCenter=binCenter,
    anchorRow=ratioRow
  )]
  Anchors <- AnchorLookup[
    AllElements,
    on=.(chrom, anchorCenter=elementCenter),
    roll="nearest",
    .(
      element_class=i.element_class,
      element_id=i.element_id,
      element_key=i.element_key,
      element_name=i.element_name,
      chrom=i.chrom,
      chromStart=i.chromStart,
      chromEnd=i.chromEnd,
      elementCenter=i.elementCenter,
      chromosome_order=i.chromosome_order,
      anchorRow,
      matchedCenter=x.anchorCenter
    )
  ]
  if(anyNA(Anchors$anchorRow)){
    MissingChromosomes <- unique(Anchors[is.na(anchorRow), chrom])
    stop(
      "Selected genomic elements refer to chromosome(s) absent from the nuclear collapsed ratio table: ",
      paste(MissingChromosomes, collapse=", "),
      call.=FALSE
    )
  }
  Anchors[, anchorDistance := matchedCenter-elementCenter]
  Queries <- Anchors[, .(
    offset=Offsets,
    targetRow=anchorRow+OffsetRows
  ), by=.(
    element_class,
    element_id,
    element_key,
    element_name,
    chrom,
    chromStart,
    chromEnd,
    elementCenter,
    chromosome_order
  )]
  Signal <- Ratio[
    Queries,
    on=.(chrom, ratioRow=targetRow),
    .(
      element_class=i.element_class,
      element_id=i.element_id,
      element_key=i.element_key,
      element_name=i.element_name,
      chrom=i.chrom,
      chromStart=i.chromStart,
      chromEnd=i.chromEnd,
      elementCenter=i.elementCenter,
      chromosome_order=i.chromosome_order,
      offset=i.offset,
      ip.score,
      ratio.ipin,
      ratio.ipnoise,
      ratio.ipin.noise
    )
  ]

  BuildClassMatrices <- function(element_class){
    TargetClass <- element_class
    ClassMetadata <- data.table::copy(
      ElementTables[[TargetClass]][, .(
        element_class,
        element_id,
        element_key,
        element_name,
        chrom,
        chromStart,
        chromEnd,
        elementCenter,
        chromosome_order
      )]
    )
    ClassSignal <- Signal[element_class == TargetClass]
    RowIndex <- match(ClassSignal$element_id, ClassMetadata$element_id)
    ColumnIndex <- match(ClassSignal$offset, Offsets)
    if(anyNA(RowIndex) || anyNA(ColumnIndex)){
      stop(
        "Could not align extracted heatmap cells for ",
        PrettyElementClass(TargetClass),
        ".",
        call.=FALSE
      )
    }
    Matrices <- setNames(
      lapply(
        AllMetrics,
        function(metric){
          Matrix <- matrix(
            NA_real_,
            nrow=nrow(ClassMetadata),
            ncol=length(Offsets),
            dimnames=list(
              ClassMetadata$element_key,
              as.character(Offsets)
            )
          )
          Matrix[cbind(RowIndex, ColumnIndex)] <- ClassSignal[[metric]]
          Matrix
        }
      ),
      AllMetrics
    )
    list(metadata=ClassMetadata, matrices=Matrices)
  }

  ClassResults <- lapply(SelectedElements, BuildClassMatrices)
  names(ClassResults) <- SelectedElements
  RawHeatmaps <- lapply(ClassResults, `[[`, "matrices")
  RowMetadata <- lapply(ClassResults, `[[`, "metadata")

  MeanOrNA <- function(values){
    if(all(is.na(values))){
      NA_real_
    } else {
      mean(values, na.rm=TRUE)
    }
  }
  RowOrder <- setNames(vector("list", length(SelectedElements)), SelectedElements)
  OrderScores <- setNames(vector("list", length(SelectedElements)), SelectedElements)
  for(element_class in SelectedElements){
    Metadata <- RowMetadata[[element_class]]
    if(OrderBy == "genomic"){
      SortIndex <- order(
        Metadata$chromosome_order,
        Metadata$elementCenter,
        Metadata$chromStart,
        Metadata$chromEnd,
        Metadata$element_name,
        na.last=TRUE
      )
      Scores <- rep(NA_real_, nrow(Metadata))
    } else {
      Scores <- apply(
        RawHeatmaps[[element_class]][[OrderBy]],
        1L,
        MeanOrNA
      )
      SortScores <- Scores
      SortScores[!is.finite(SortScores)] <- -Inf
      SortIndex <- order(
        -SortScores,
        Metadata$chromosome_order,
        Metadata$elementCenter,
        Metadata$chromStart,
        Metadata$chromEnd,
        Metadata$element_name,
        na.last=TRUE
      )
    }
    RowOrder[[element_class]] <- SortIndex
    OrderScores[[element_class]] <- Scores[SortIndex]
    OrderedMetadata <- Metadata[SortIndex]
    OrderedMetadata[, heatmap_rank := seq_len(.N)]
    OrderedMetadata[, order_score := Scores[SortIndex]]
    RowMetadata[[element_class]] <- OrderedMetadata
    RawHeatmaps[[element_class]] <- lapply(
      RawHeatmaps[[element_class]],
      function(Matrix) Matrix[SortIndex, , drop=FALSE]
    )
  }

  TransformMatrixForDisplay <- function(Matrix, metric){
    Display <- Matrix
    if(!Log2Values){
      return(Display)
    }
    if(metric == "ip.score"){
      Display <- log2(1+Display)
    } else {
      Positive <- is.finite(Display) & Display > 0
      Display[Positive] <- log2(Display[Positive])
      Display[!Positive] <- NA_real_
    }
    Display
  }
  DisplayHeatmaps <- lapply(
    SelectedElements,
    function(element_class){
      setNames(
        lapply(
          AllMetrics,
          function(metric){
            TransformMatrixForDisplay(
              RawHeatmaps[[element_class]][[metric]],
              metric
            )
          }
        ),
        AllMetrics
      )
    }
  )
  names(DisplayHeatmaps) <- SelectedElements

  DisplayMetricLabel <- function(metric){
    Label <- MetricYLabels[[metric]]
    if(!Log2Values){
      return(Label)
    }
    if(metric == "ip.score"){
      paste0("log2(1 + ", Label, ")")
    } else {
      paste0("log2(", Label, ")")
    }
  }
  MetricBaseline <- function(metric){
    if(metric == "ip.score"){
      NA_real_
    } else if(Log2Values){
      0
    } else {
      1
    }
  }

  SequentialPalette <- viridisLite::viridis(
    256L,
    option="D",
    direction=1
  )
  MakoColors <- viridisLite::mako(256L)
  RocketColors <- viridisLite::rocket(256L)
  DivergingPalette <- grDevices::colorRampPalette(
    c(MakoColors[[120]], "#F7F7F7", RocketColors[[160]]),
    space="Lab"
  )(256L)
  PaletteForMetric <- function(metric){
    if(Log2Values && metric != "ip.score"){
      DivergingPalette
    } else {
      SequentialPalette
    }
  }
  PaletteNameForMetric <- function(metric){
    if(Log2Values && metric != "ip.score"){
      "viridis-derived mako-neutral-rocket diverging"
    } else {
      "viridis sequential"
    }
  }

  ColorLimits <- data.table::rbindlist(
    lapply(
      PlotMetrics,
      function(metric){
        Values <- unlist(
          lapply(
            SelectedElements,
            function(element_class){
              as.vector(DisplayHeatmaps[[element_class]][[metric]])
            }
          ),
          use.names=FALSE
        )
        FiniteValues <- Values[is.finite(Values)]
        if(length(FiniteValues) == 0L){
          stop(
            "No finite heatmap values remain for plotted metric: ",
            metric,
            call.=FALSE
          )
        }
        Robust <- as.numeric(stats::quantile(
          FiniteValues,
          probs=RobustProbabilities,
          na.rm=TRUE,
          names=FALSE,
          type=8
        ))
        if(Log2Values && metric != "ip.score"){
          MaximumAbsolute <- max(abs(Robust))
          if(!is.finite(MaximumAbsolute) || MaximumAbsolute == 0){
            MaximumAbsolute <- max(abs(FiniteValues))
          }
          if(!is.finite(MaximumAbsolute) || MaximumAbsolute == 0){
            MaximumAbsolute <- 1
          }
          Lower <- -MaximumAbsolute
          Upper <- MaximumAbsolute
        } else {
          Lower <- Robust[[1]]
          Upper <- Robust[[2]]
          Baseline <- MetricBaseline(metric)
          if(is.finite(Baseline)){
            Lower <- min(Lower, Baseline)
            Upper <- max(Upper, Baseline)
          }
          if(!is.finite(Lower) || !is.finite(Upper)){
            stop(
              "Could not calculate finite colour limits for metric: ",
              metric,
              call.=FALSE
            )
          }
          if(Lower == Upper){
            Padding <- max(0.5, abs(Lower)*0.10)
            Lower <- Lower-Padding
            Upper <- Upper+Padding
          }
        }
        data.table::data.table(
          metric=metric,
          lower=Lower,
          upper=Upper,
          robust_lower=Robust[[1]],
          robust_upper=Robust[[2]],
          n_finite=length(FiniteValues),
          n_missing=sum(!is.finite(Values)),
          n_clipped_low=sum(FiniteValues < Lower),
          n_clipped_high=sum(FiniteValues > Upper),
          palette=PaletteNameForMetric(metric),
          missing_color=MissingColor
        )
      }
    ),
    use.names=TRUE
  )

  KeyMembership <- unique(AllElements[, .(
    element_key,
    element_class,
    chrom,
    chromStart,
    chromEnd,
    element_name
  )])
  SharedKeys <- KeyMembership[, .(
    n_classes=data.table::uniqueN(element_class)
  ), by=element_key][n_classes > 1L, element_key]
  SharedCoordinates <- KeyMembership[element_key %in% SharedKeys]
  if(nrow(SharedCoordinates) > 0L){
    SharedCoordinates[, element_order := match(element_class, SelectedElements)]
    SharedCoordinates[, chromosome_order := match(chrom, NuclearChromosomes)]
    data.table::setorder(
      SharedCoordinates,
      chromosome_order,
      chromStart,
      chromEnd,
      element_order
    )
    SharedCoordinates[, c("element_order", "chromosome_order") := NULL]
  }

  ElementTag <- paste(SelectedElements, collapse="-")
  MetricTag <- if(identical(PlotMetrics, AllMetrics)){
    "all_metrics"
  } else {
    paste(gsub("[^A-Za-z0-9]+", "", PlotMetrics), collapse="-")
  }
  OrderTag <- gsub("[^A-Za-z0-9]+", "", OrderBy)
  ScaleTag <- if(Log2Values) "log2" else "linear"
  OutputFile <- file.path(
    OutputDir,
    paste0(
      SampleName, "_", Assay, "_", Alignment,
      "_collapsed_", ScaleTag, "_", ElementTag, "_", MetricTag,
      "_ordered_by_", OrderTag, "_Genomic_Element_Heatmaps.pdf"
    )
  )

  NumberMetrics <- length(PlotMetrics)
  PdfWidth <- c(`1`=5.6, `2`=8.2, `3`=11.2, `4`=14.0)[[
    as.character(NumberMetrics)
  ]]
  PdfHeight <- 8.5
  PageCount <- length(SelectedElements)

  grDevices::pdf(
    OutputFile,
    width=PdfWidth,
    height=PdfHeight,
    useDingbats=FALSE,
    onefile=TRUE
  )
  PdfDevice <- grDevices::dev.cur()
  on.exit({
    OpenDevices <- grDevices::dev.list()
    if(!is.null(OpenDevices) && PdfDevice %in% OpenDevices){
      grDevices::dev.off(which=PdfDevice)
    }
  }, add=TRUE)

  PlotHeatmapPanel <- function(element_class, metric, show_y_axis=FALSE){
    Matrix <- DisplayHeatmaps[[element_class]][[metric]]
    TargetMetric <- metric
    Limits <- ColorLimits[base::which(ColorLimits$metric == TargetMetric)]
    Lower <- Limits$lower[[1]]
    Upper <- Limits$upper[[1]]
    Palette <- PaletteForMetric(metric)
    PlotMatrix <- Matrix
    Finite <- is.finite(PlotMatrix)
    PlotMatrix[Finite & PlotMatrix < Lower] <- Lower
    PlotMatrix[Finite & PlotMatrix > Upper] <- Upper
    ColorStep <- (Upper-Lower)/length(Palette)
    if(!is.finite(ColorStep) || ColorStep <= 0){
      ColorStep <- 1
    }
    MissingSentinel <- Lower-ColorStep
    PlotMatrix[!Finite] <- MissingSentinel
    PlotColors <- c(MissingColor, Palette)
    PlotLimits <- c(MissingSentinel, Upper)
    NumberElements <- nrow(PlotMatrix)
    ReversedMatrix <- PlotMatrix[NumberElements:1L, , drop=FALSE]

    graphics::par(
      mar=c(4.0, if(show_y_axis) 4.3 else 1.25, 2.6, 0.75),
      mgp=c(2.25, 0.65, 0),
      tcl=-0.23
    )
    graphics::image(
      x=Offsets/1000,
      y=seq_len(NumberElements),
      z=t(ReversedMatrix),
      col=PlotColors,
      zlim=PlotLimits,
      axes=FALSE,
      xlab="",
      ylab="",
      main=MetricTitles[[metric]],
      useRaster=TRUE,
      xaxs="i",
      yaxs="i",
      cex.main=1.02
    )
    XTicks <- seq(-Window, Window, length.out=5L)/1000
    graphics::axis(
      1,
      at=XTicks,
      labels=format(signif(XTicks, 3), trim=TRUE),
      cex.axis=0.82
    )
    graphics::mtext(
      if(element_class %in% PeakElements){
        "Distance from peak summit (kb)"
      } else {
        "Distance from element midpoint (kb)"
      },
      side=1,
      line=2.45,
      cex=0.86
    )
    if(show_y_axis){
      if(NumberElements == 1L){
        graphics::axis(2, at=1, labels=1, las=1, cex.axis=0.78)
      } else {
        graphics::axis(
          2,
          at=c(1, NumberElements),
          labels=c(NumberElements, 1),
          las=1,
          cex.axis=0.78
        )
      }
      graphics::mtext(
        if(OrderBy == "genomic"){
          "Genomic element order"
        } else {
          "Element rank (1 = highest)"
        },
        side=2,
        line=2.65,
        cex=0.86
      )
    }
    graphics::abline(
      v=0,
      col=grDevices::adjustcolor("gray15", alpha.f=0.72),
      lty=2,
      lwd=0.85
    )
    graphics::box(col="gray25", lwd=0.75)
  }

  PlotColorKey <- function(metric, show_y_space=FALSE){
    TargetMetric <- metric
    Limits <- ColorLimits[base::which(ColorLimits$metric == TargetMetric)]
    Lower <- Limits$lower[[1]]
    Upper <- Limits$upper[[1]]
    Palette <- PaletteForMetric(metric)
    KeyValues <- seq(Lower, Upper, length.out=length(Palette))
    KeyMatrix <- matrix(
      rep(KeyValues, 2L),
      nrow=length(KeyValues),
      ncol=2L
    )
    graphics::par(
      mar=c(2.6, if(show_y_space) 4.3 else 1.25, 0.25, 0.75),
      mgp=c(1.55, 0.55, 0),
      tcl=-0.18
    )
    graphics::image(
      x=KeyValues,
      y=c(0, 1),
      z=KeyMatrix,
      col=Palette,
      zlim=c(Lower, Upper),
      axes=FALSE,
      xlab="",
      ylab="",
      useRaster=TRUE,
      xaxs="i",
      yaxs="i"
    )
    Baseline <- MetricBaseline(metric)
    KeyTicks <- pretty(c(Lower, Upper), n=4L)
    KeyTicks <- KeyTicks[KeyTicks >= Lower & KeyTicks <= Upper]
    if(is.finite(Baseline) && Baseline >= Lower && Baseline <= Upper){
      KeyTicks <- sort(unique(c(KeyTicks, Baseline)))
    }
    graphics::axis(
      1,
      at=KeyTicks,
      labels=format(signif(KeyTicks, 3), trim=TRUE),
      cex.axis=0.72
    )
    graphics::mtext(
      DisplayMetricLabel(metric),
      side=1,
      line=1.55,
      cex=0.76
    )
    if(is.finite(Baseline) && Baseline >= Lower && Baseline <= Upper){
      graphics::abline(
        v=Baseline,
        col=grDevices::adjustcolor("gray15", alpha.f=0.72),
        lwd=0.75,
        lty=2
      )
    }
    graphics::box(col="gray35", lwd=0.65)
  }

  for(PageIndex in seq_along(SelectedElements)){
    ElementClass <- SelectedElements[[PageIndex]]
    LayoutMatrix <- matrix(
      c(
        seq_len(NumberMetrics),
        NumberMetrics+seq_len(NumberMetrics)
      ),
      nrow=2L,
      byrow=TRUE
    )
    graphics::layout(
      LayoutMatrix,
      widths=rep(1, NumberMetrics),
      heights=c(8.0, 1.05)
    )
    graphics::par(oma=c(0.55, 0.55, 3.45, 0.45))
    for(MetricIndex in seq_along(PlotMetrics)){
      PlotHeatmapPanel(
        ElementClass,
        PlotMetrics[[MetricIndex]],
        show_y_axis=MetricIndex == 1L
      )
    }
    for(MetricIndex in seq_along(PlotMetrics)){
      PlotColorKey(
        PlotMetrics[[MetricIndex]],
        show_y_space=MetricIndex == 1L
      )
    }
    graphics::mtext(
      paste0(
        PrettyElementClass(ElementClass),
        " (n=", format(ElementCounts[[ElementClass]], big.mark=","), ")"
      ),
      outer=TRUE,
      side=3,
      line=1.15,
      font=2,
      cex=1.28,
      col="gray20"
    )
    graphics::mtext(
      paste0(
        SampleName, " | ", Assay, " | ", Alignment,
        " | collapsed | ",
        if(Log2Values) "log2 display" else "untransformed display",
        " | +/-", format(Window, big.mark=","), " bp | ordered by ",
        if(OrderBy == "genomic") "genomic position" else OrderBy
      ),
      outer=TRUE,
      side=3,
      line=0.08,
      cex=0.76,
      col="gray42"
    )
  }

  grDevices::dev.off(which=PdfDevice)
  message("Genomic-element heatmap report saved: ", OutputFile)

  invisible(list(
    pdf=OutputFile,
    sample_dir=SampleDir,
    sample_name=SampleName,
    assay=Assay,
    alignment=Alignment,
    strand_mode="collapsed",
    elements=SelectedElements,
    metrics=PlotMetrics,
    window=Window,
    step=Step,
    bin_width=BinWidth,
    offsets=Offsets,
    expected_bins_per_element=length(Offsets),
    log2_values=Log2Values,
    display_transform=if(Log2Values){
      "log2(1+x) for ip.score; log2(x) for positive ratio values; non-positive ratios shown as missing"
    } else {
      "untransformed"
    },
    order_by=OrderBy,
    order_direction=if(OrderBy == "genomic") "nuclear genomic order" else "decreasing mean across displayed window",
    ratio_file=RatioFile,
    ratio_chrM_rows_omitted=RatioChrMOmitted,
    element_files=ElementFiles,
    peak_element_selectors=intersect(SelectedElements, PeakElements),
    element_counts=ElementCounts,
    element_chrM_records_omitted=ElementChrMOmitted,
    anchors=Anchors,
    row_order=RowOrder,
    order_scores=OrderScores,
    row_metadata=RowMetadata,
    raw_heatmaps=RawHeatmaps,
    display_heatmaps=DisplayHeatmaps,
    color_limits=ColorLimits,
    robust_color_probabilities=RobustProbabilities,
    shared_coordinates=SharedCoordinates,
    excluded_annotations=c("ORF", "rDNA"),
    chromosomes=NuclearChromosomes,
    chrM_excluded=TRUE,
    element_centering="curated BED interval midpoint or saved primary-analysis peakSummit; nearest saved ratio-window centre",
    edge_handling="missing chromosome-edge bins retained as unavailable; no interpolation or zero padding",
    heatmap_smoothing=FALSE,
    row_normalization=FALSE,
    row_clustering=FALSE,
    raster_heatmap_vector_text=TRUE,
    page_count=PageCount,
    page_layout="one selected element cohort per page; all selected metrics in one horizontal row",
    pdf_dimensions_inches=c(width=PdfWidth, height=PdfHeight),
    primary_ratio_output_only=TRUE,
    annotation_source="project-local processed genomic-element BED files and/or sample-specific primary-analysis peak BED files",
    plotter_operations=c(
      bam_reading=FALSE,
      coverage_reading=FALSE,
      simulation=FALSE,
      noise_estimation=FALSE,
      signal_filtering=FALSE,
      ratio_recalculation=FALSE,
      strand_collapsing=FALSE,
      peak_calling=FALSE,
      pvalue_thresholding=FALSE,
      smoothing=FALSE,
      row_normalization=FALSE,
      row_clustering=FALSE
    ),
    display_operations=c(
      element_midpoint_window_extraction=TRUE,
      metric_log_transformation=Log2Values,
      robust_color_saturation=TRUE,
      shared_metric_color_scale=TRUE,
      raster_heatmap_cells=TRUE,
      vector_text_and_axes=TRUE
    )
  ))
}

## Validate the transferable bundle immediately when the main script is sourced.
## Large indexes and annotation tables are not loaded into memory here; their
## resolved paths are retained and the relevant function reads each one on demand.
.ChIPBrDU_Default_Paths <- ChIP_BrDU_Project_Paths(check=TRUE)


## Unified primary analysis for ChIP-seq or BrDU-seq. The alignment, coverage,
## peak-calling, noise-estimation, filtration, ratio, and rDNA modalities are
## unchanged from the former assay-specific functions. Assay only controls the
## assay FASTQ label and the established ChIP/BrDU output-file prefixes.
##
## Example:
## ChIP_BrDU_Primary_Analysis(
##   Input_R1="/path/to/input_R1.fastq.gz",
##   Input_R2="/path/to/input_R2.fastq.gz",
##   Assay_R1="/path/to/chip_R1.fastq.gz",
##   Assay_R2="/path/to/chip_R2.fastq.gz",
##   Assay="ChIP",
##   Alignment="generic",
##   ExpTitle="Smc5",
##   Directory="/path/to/ChIP_results"
## )
ChIP_BrDU_Primary_Analysis <- function(  Input_R1 = "/full/path/to/file_R1.fastq.gz",
                                       Input_R2 = "/full/path/to/file_R2.fastq.gz",

                                       Assay_R1 = "/full/path/to/file_R1.fastq.gz",
                                       Assay_R2 = "/full/path/to/file_R2.fastq.gz",

                                       Assay = c("ChIP", "BrDU"),

                                       Alignment = "generic",  # "generic" (bowtie2) / "malign" (Rsubread multi-aligner) / "mrdna" (Rsubread multi-aligner at rDNA locus)

                                       ExpTitle = "Smc5-trial",
                                       Directory = "None",
                                       slidingWindow = "YES" ) {

  Assay <- match.arg(Assay)

  ## load packages

  packages <- c("basicPlotteR", "plyr", "tidyverse", "dplyr", "plotrix", "rasterpdf", "imager",
                "VennDiagram", "grid", "gridBase", "gridExtra", "ShortRead", "csaw", "shiny",
                "BSgenome.Scerevisiae.UCSC.sacCer3", "Rsubread", "GenomicAlignments",
                "IRanges", "readxl", "data.table", "ORFik")

  suppressWarnings(suppressPackageStartupMessages(lapply(packages, require, character.only = TRUE)))

  SupportPaths <- ChIP_BrDU_Project_Paths(check=TRUE)
  All_Ori_Link <- SupportPaths$source_files$all_origins
  E_Ori_Link <- SupportPaths$source_files$early_origins
  L_Ori_Link <- SupportPaths$source_files$late_origins

  # Sequencing Alignment & Binned Coverage Calculation

  #
  useDef <- function(a,d) ifelse(isTruthy(a), a,d)

  ExpTitle = useDef(ExpTitle, "None")


  if(ExpTitle == "None"){
    Pro_1 <- unlist(strsplit(basename(Input_R1), split='_', fixed=TRUE))[[1]]
  } else {
    Pro_1 <- ExpTitle
  }

  #
  message(paste0("✅ Experiment: ", Pro_1))
  #

  #
  Directory = useDef(Directory, "None")

  if(Directory == "None"){
    dir <- "~/Desktop/"
  } else {
    dir <- paste0(Directory, "/")
  }
  #

  suppressWarnings(dir.create(paste0(dir, Pro_1)))

  ## Quality check of fastqs'
  # #
  # message("⏳ Running QC ...")
  # #
  # if(!file.exists(paste0(dir, Pro_1, "/", Pro_1, "_", "QR", ".html"))){
  #
  #   fls = c(Input_R1, Input_R2, Assay_R1, Assay_R2)
  #
  #   names(fls) = sub(".fastq", "", basename(fls))
  #
  #   qas = lapply(seq_along(fls),
  #                function(i, fls) qa(readFastq(fls[i]), names(fls)[i]),
  #                fls)
  #   qa = do.call(rbind, qas)
  #   rpt = report(qa, dest = paste0(dir, Pro_1, "/", Pro_1, "_", "QR", ".html"))
  #
  # }
  #
  ## Run alignment
  #
  message("✅ Reference yeast genome : S288C")
  message("⏳ Running alignments...")
  #
  if(Alignment == "generic"){

    if(!dir.exists(paste0(dir, Pro_1, "/", "Bam"))){

      RunAlignment_bowtie2 <- function(File_R1, File_R2, SampName){

        message(paste0("➤ Running alignment for ", Pro_1, "_", SampName))

        tempdir(check = TRUE)

        Sam <- tempfile(fileext = ".sam")
        Bam <- tempfile(fileext = ".bam")
        nmCollate <- tempfile(fileext = ".bam")
        fixMat <- tempfile(fileext = ".bam")
        SrtBam <- tempfile(fileext = ".bam")


        Pro_1 <- Pro_1
        Pro_2 <- SampName

        suppressWarnings(dir.create(paste0(dir, Pro_1, "/", "Bam")))

        AlnLog <- paste0(dir, Pro_1, "/", "Bam", "/", Pro_1, "_", Pro_2, ".log")
        SFBam <- paste0(dir, Pro_1, "/", "Bam", "/", Pro_1, "_", Pro_2, ".bam")

        #read the indexed reference genome for the alignment of sequenced data
        ref_index <- SupportPaths$indexes$bowtie2_s288c

        #following commands will run the alignemnt, check quality, sort, filter and index the resultant bam file

        system(sprintf("(/Applications/ngsAnalyser.app/Contents/Resources/app/bowtie2-2.4.4-macos-x86_64/bowtie2 -p 8  --no-discordant --fr -x %s -1 %s -2 %s -S %s) 2> %s",
                       ref_index, File_R1, File_R2, Sam, AlnLog))

        system(sprintf("/Applications/ngsAnalyser.app/Contents/Resources/app/samtools-1.13/samtools view -bS -@ 15 -q 30 -f 2 %s > %s", Sam, Bam))

        system(sprintf("/Applications/ngsAnalyser.app/Contents/Resources/app/samtools-1.13/samtools collate -@ 15 -o %s %s", nmCollate, Bam))

        system(sprintf("/Applications/ngsAnalyser.app/Contents/Resources/app/samtools-1.13/samtools fixmate -@ 15 -m %s %s", nmCollate, fixMat))

        system(sprintf("/Applications/ngsAnalyser.app/Contents/Resources/app/samtools-1.13/samtools sort -l 9 -@ 15 -m 1024M  -O bam -o %s %s", SrtBam, fixMat))

        system(sprintf("/Applications/ngsAnalyser.app/Contents/Resources/app/samtools-1.13/samtools markdup -@ 15 %s %s", SrtBam, SFBam))

        system(sprintf("/Applications/ngsAnalyser.app/Contents/Resources/app/samtools-1.13/samtools index -@ 15 %s", SFBam))

        unlink(c(Sam, Bam, nmCollate, fixMat, SrtBam), recursive = T, force = T)

      }

      RunAlignment_bowtie2(Input_R1, Input_R2, "Input")
      RunAlignment_bowtie2(Assay_R1, Assay_R2, Assay)

    }

  }

  if(Alignment == "malign"){

    if(!dir.exists(paste0(dir, Pro_1, "/", "Bam_ma"))){

      RunAlignment_subread_malign <- function(File_R1, File_R2, SampName){

        message(paste0("➤ Running Rsubread-based multiple-alignment for ", Pro_1, "_", SampName))

        Pro_1 <- Pro_1
        Pro_2 <- SampName

        suppressWarnings(dir.create(paste0(dir, Pro_1, "/", "Bam_ma")))

        resultBam <- paste0(dir, Pro_1, "/", "Bam_ma", "/", Pro_1, "_", Pro_2, ".bam")

        #read the indexed reference genome

        ref_index <- SupportPaths$indexes$rsubread_s288c

        #run alignment

        align(index = ref_index,
              readfile1 = File_R1,
              readfile2 = File_R2,
              output_format = "BAM",
              output_file = resultBam,
              color2base = F,
              type = "dna",
              unique = FALSE,
              nBestLocations = 16,
              nthreads = 8,
              sortReadsByCoordinates = TRUE)

      }

      RunAlignment_subread_malign(Input_R1, Input_R2, "Input")
      RunAlignment_subread_malign(Assay_R1, Assay_R2, Assay)

    }

  }

  if(Alignment == "mrdna"){

    if(!dir.exists(paste0(dir, Pro_1, "/", "Bam_ma_rdna"))){

      RunAlignment_subread_malign_rDNA <- function(File_R1, File_R2, SampName){

        message(paste0("➤ Running Rsubread-based multiple-alignment at rDNA for ", Pro_1, "_", SampName))

        Pro_1 <- Pro_1
        Pro_2 <- SampName

        suppressWarnings(dir.create(paste0(dir, Pro_1, "/", "Bam_ma_rdna")))

        resultBam <- paste0(dir, Pro_1, "/", "Bam_ma_rdna", "/", Pro_1, "_", Pro_2, ".bam")

        #read the indexed reference genome

        ref_index <- SupportPaths$indexes$rsubread_rdna

        #run alignment

        align(index = ref_index,
              readfile1 = File_R1,
              readfile2 = File_R2,
              output_format = "BAM",
              output_file = resultBam,
              color2base = F,
              type = "dna",
              unique = FALSE,
              nBestLocations = 16,
              nthreads = 8,
              sortReadsByCoordinates = TRUE)

      }

      RunAlignment_subread_malign_rDNA(Input_R1, Input_R2, "Input_rDNA")
      RunAlignment_subread_malign_rDNA(Assay_R1, Assay_R2, paste0(Assay, "_rDNA"))

      RunAlignment_subread_malign <- function(File_R1, File_R2, SampName){

        message(paste0("➤ Running Rsubread-based multiple-alignment for ", Pro_1, "_", SampName))

        Pro_1 <- Pro_1
        Pro_2 <- SampName

        suppressWarnings(dir.create(paste0(dir, Pro_1, "/", "Bam_ma_rdna")))

        resultBam <- paste0(dir, Pro_1, "/", "Bam_ma_rdna", "/", Pro_1, "_", Pro_2, ".bam")

        #read the indexed reference genome

        ref_index <- SupportPaths$indexes$rsubread_s288c

        #run alignment

        align(index = ref_index,
              readfile1 = File_R1,
              readfile2 = File_R2,
              output_format = "BAM",
              output_file = resultBam,
              color2base = F,
              type = "dna",
              unique = FALSE,
              nBestLocations = 16,
              nthreads = 8,
              sortReadsByCoordinates = TRUE)

      }

      RunAlignment_subread_malign(Input_R1, Input_R2, "Input_ma")
      RunAlignment_subread_malign(Assay_R1, Assay_R2, paste0(Assay, "_ma"))

    }

  }

  #
  ## Calculate genome-wide binned coverage
  #
  message("⏳ Calculating read coverage ...")
  #
  if(Alignment == "generic"){ BamFolder = "Bam" }
  if(Alignment == "malign"){ BamFolder = "Bam_ma" }
  if(Alignment == "mrdna"){ BamFolder = "Bam_ma_rdna" }
  #

  if(Alignment == "generic"){

    bamFiles <- c(paste0(dir, Pro_1, "/", BamFolder, "/", Pro_1, "_", Assay, ".bam"),
                  paste0(dir, Pro_1, "/", BamFolder, "/", Pro_1, "_Input.bam"))

    if(!dir.exists(paste0(dir, Pro_1, "/", "Coverage"))){

      #coverage
      BamCoverage <- function(bamFile, binSize = 300, stepSize = 10, slidingWindow = "YES", byReads_5p = T){

        SampleName = tools::file_path_sans_ext(basename(bamFile))
        Pro_2 = substring(SampleName, nchar(Pro_1)+2)

        suppressWarnings(dir.create(paste0(dir, Pro_1, "/", "Coverage")))

        tempdir(check = TRUE)

        GenomFile <- tempfile(fileext = ".txt")
        binFile <- tempfile(fileext = ".bed")

        command_1 <- "/Applications/ngsAnalyser.app/Contents/Resources/app/samtools-1.13/samtools idxstats %s | awk 'BEGIN {OFS=\"\\t\"} {if ($2>0) print ($1,$2)}' >  %s"
        system(sprintf(command_1, bamFile, GenomFile))

        if(slidingWindow=="YES"){
          command_2 <- "/Applications/ngsAnalyser.app/Contents/Resources/app/bedtools2/bin/bedtools makewindows -g %s -w %s -s %s | sort -k1,1V -k2,2n > %s"
          system(sprintf(command_2, GenomFile, binSize, stepSize, binFile))
        } else {
          command_2 <- "/Applications/ngsAnalyser.app/Contents/Resources/app/bedtools2/bin/bedtools makewindows -g %s -w %s | sort -k1,1V -k2,2n > %s"
          system(sprintf(command_2, GenomFile, binSize, binFile))
        }

        pncFiles_watson <- tempfile(fileext = ".bed")
        pncFiles_crick <- tempfile(fileext = ".bed")

        if(byReads_5p == TRUE){

          message(paste0("➤ Calculating coverage with 5' ends of first-mate reads for", " ",
                         tools::file_path_sans_ext(basename(bamFile)) ))

          # calculate coverage at watson strand by 5' end of the first mate reads
          command_3 <- paste0(
            "/Applications/ngsAnalyser.app/Contents/Resources/app/samtools-1.13/samtools view -h -@ 8 -q 30 -F 3840 -f 64 -L %s %s |",
            "grep -v XS:i: |",
            "/Applications/ngsAnalyser.app/Contents/Resources/app/samtools-1.13/samtools view -@ 8 -b - |",
            "/Applications/ngsAnalyser.app/Contents/Resources/app/bedtools2/bin/bedtools genomecov -ibam stdin -strand + -d -5 |",
            "awk 'BEGIN {OFS=\"\\t\"} {if ($3>0) print $1,$2,$2,\"%s\",$3}' | sort -k1,1V -k2,2n > %s"
          )

          # calculate coverage at crick strand by 5' end of the first mate reads
          command_4 <- paste0(
            "/Applications/ngsAnalyser.app/Contents/Resources/app/samtools-1.13/samtools view -h -@ 8 -q 30 -F 3840 -f 64 -L %s %s |",
            "grep -v XS:i: |",
            "/Applications/ngsAnalyser.app/Contents/Resources/app/samtools-1.13/samtools view -@ 8 -b - |",
            "/Applications/ngsAnalyser.app/Contents/Resources/app/bedtools2/bin/bedtools genomecov -ibam stdin -strand - -d -5 |",
            "awk 'BEGIN {OFS=\"\\t\"} {if ($3>0) print $1,$2,$2,\"%s\",$3}' | sort -k1,1V -k2,2n > %s"
          )
        }

        #
        # Watson (+)
        system(sprintf(command_3, binFile, bamFile,
                       paste0(tools::file_path_sans_ext(basename(bamFile)), "_watson"),
                       pncFiles_watson))

        # Crick (-)
        system(sprintf(command_4, binFile, bamFile,
                       paste0(tools::file_path_sans_ext(basename(bamFile)), "_crick"),
                       pncFiles_crick))

        #
        # sum the counts per bin for watson and crick separately and store in finFiles

        finFiles_watson <- paste0(dir, Pro_1, "/", "Coverage", "/", Pro_1, "_", Pro_2, "_", "watson.bed")
        finFiles_crick <- paste0(dir, Pro_1, "/", "Coverage", "/", Pro_1, "_", Pro_2, "_", "crick.bed")

        command_5 <- paste(
          "/Applications/ngsAnalyser.app/Contents/Resources/app/bedtools2/bin/bedtools map",
          "-a %s -b %s -null 0 -o sum |",
          "awk 'BEGIN {OFS=\"\\t\"} {if ($4>=0) print $1,$2,$3,\"%s\",$4}' > %s"
        )

        # Watson (+)
        system(sprintf(command_5, binFile, pncFiles_watson,
                       paste0(tools::file_path_sans_ext(basename(bamFile)), "_watson"),
                       finFiles_watson))
        # Crick (-)
        system(sprintf(command_5, binFile, pncFiles_crick,
                       paste0(tools::file_path_sans_ext(basename(bamFile)), "_crick"),
                       finFiles_crick))

        #

        unlink(c(GenomFile, binFile, pncFiles_watson, pncFiles_crick), recursive = T, force = T)

      }

      for(i in 1:length(bamFiles)){
        BamCoverage(bamFile = bamFiles[i])
      }

    }

  }

  if(Alignment == "malign"){

    bamFiles <- c(paste0(dir, Pro_1, "/", BamFolder, "/", Pro_1, "_", Assay, ".bam"),
                  paste0(dir, Pro_1, "/", BamFolder, "/", Pro_1, "_Input.bam"))

    if(!dir.exists(paste0(dir, Pro_1, "/", "Coverage_ma"))){

      BamCoverage <- function(bamFile, binSize=300, stepSize=10, byReads_5p=TRUE){

        SampleName = tools::file_path_sans_ext(basename(bamFile))
        Pro_2 = substring(SampleName, nchar(Pro_1)+2)

        suppressWarnings(dir.create(paste0(dir, Pro_1, "/", "Coverage_ma")))

        # whole-genome sliding windows
        Windows = tileGenome(seqlengths(Scerevisiae)[-17], tilewidth=stepSize)
        Windows = unlist(Windows)
        Windows = suppressWarnings(trim(IRanges::resize(Windows, width=binSize)))

        Counts_watson = numeric(length(Windows))
        Counts_crick = numeric(length(Windows))

        if(byReads_5p == TRUE){

          message(paste0("➤ Calculating multiple-alignment coverage using 5' ends of first-mate reads for ",
                         tools::file_path_sans_ext(basename(bamFile))))

        } else {

          message(paste0("➤ Calculating multiple-alignment coverage using fragment midpoints for ",
                         tools::file_path_sans_ext(basename(bamFile))))
        }

        for(i in 1:16){

          paramS = ScanBamParam(flag=scanBamFlag(isProperPair=TRUE, isUnmappedQuery=FALSE,
                                                 hasUnmappedMate=FALSE),
                                what=c("qname", "mapq", "isize", "seq"),
                                tag=c("NH", "NM"),
                                tagFilter=list(NH=i, NM=c(0:2)))

          AlignmentPairs = suppressWarnings(readGAlignmentPairs(bamFile, param=paramS, strandMode=1))

          if(length(AlignmentPairs) == 0) next

          if(byReads_5p == TRUE){

            # use the strand-specific 5' end of the first mate
            CoveragePoints = granges(GenomicAlignments::first(AlignmentPairs))

            fivePrimePosition = ifelse(as.character(strand(CoveragePoints)) == "+",
                                       start(CoveragePoints), end(CoveragePoints))

            start(CoveragePoints) = fivePrimePosition
            end(CoveragePoints) = fivePrimePosition

          } else {

            # use the midpoint of the complete paired-end fragment
            CoveragePoints = granges(AlignmentPairs)

            midpoint = round((start(CoveragePoints) + end(CoveragePoints))/2)

            start(CoveragePoints) = midpoint
            end(CoveragePoints) = midpoint
          }

          # fractional contribution of multiple alignments
          mcols(CoveragePoints)$weight = 1/i

          CoveragePoints_watson = CoveragePoints[as.character(strand(CoveragePoints)) == "+"]
          CoveragePoints_crick = CoveragePoints[as.character(strand(CoveragePoints)) == "-"]

          if(length(CoveragePoints_watson) > 0){

            Counts_watson = Counts_watson + countOverlapsW(Windows, CoveragePoints_watson,
                                                           weight="weight")
          }

          if(length(CoveragePoints_crick) > 0){

            Counts_crick = Counts_crick + countOverlapsW(Windows, CoveragePoints_crick,
                                                         weight="weight")
          }
        }

        finFile_watson = paste0(dir, Pro_1, "/Coverage_ma/", Pro_1, "_", Pro_2, "_watson.bed")
        finFile_crick = paste0(dir, Pro_1, "/Coverage_ma/", Pro_1, "_", Pro_2, "_crick.bed")

        bed_watson = data.frame(seqnames=as.character(seqnames(Windows)),
                                start=start(Windows)-1L,
                                end=end(Windows),
                                name=paste0(tools::file_path_sans_ext(basename(bamFile)), "_watson"),
                                score=Counts_watson)

        bed_crick = data.frame(seqnames=as.character(seqnames(Windows)),
                               start=start(Windows)-1L,
                               end=end(Windows),
                               name=paste0(tools::file_path_sans_ext(basename(bamFile)), "_crick"),
                               score=Counts_crick)

        write.table(bed_watson, file=finFile_watson, quote=FALSE, sep="\t",
                    row.names=FALSE, col.names=FALSE)

        write.table(bed_crick, file=finFile_crick, quote=FALSE, sep="\t",
                    row.names=FALSE, col.names=FALSE)
      }

      for(i in 1:length(bamFiles)){
        BamCoverage(bamFile = bamFiles[i])
      }

    }

  }

  if(Alignment == "mrdna"){

    if(!dir.exists(paste0(dir, Pro_1, "/", "Coverage_ma_rdna"))){

      BamCoverage <- function(bamFile, binSize=300, stepSize=10, byReads_5p=TRUE, rDNA=FALSE){

        SampleName = tools::file_path_sans_ext(basename(bamFile))

        suppressWarnings(dir.create(paste0(dir, Pro_1, "/", "Coverage_ma_rdna")))

        if(rDNA == FALSE){

          # whole-genome sliding windows
          Windows = tileGenome(seqlengths(Scerevisiae)[-17], tilewidth=stepSize)
          Windows = unlist(Windows)
          Windows = suppressWarnings(trim(IRanges::resize(Windows, width=binSize)))
        }

        if(rDNA == TRUE){

          # rDNA-reference sliding windows
          gen = Seqinfo(seqnames="Scer_2xrDNA_unit", seqlengths=18274,
                        isCircular=TRUE, genome="Scer_2xrDNA_unit")

          Windows = tileGenome(gen, tilewidth=stepSize)
          Windows = unlist(Windows)
          Windows = suppressWarnings(trim(IRanges::resize(Windows, width=binSize)))
        }

        Counts_watson = numeric(length(Windows))
        Counts_crick = numeric(length(Windows))

        if(byReads_5p == TRUE){

          message(paste0("➤ Calculating multiple-alignment coverage using 5' ends of first-mate reads for ",
                         SampleName))

        } else {

          message(paste0("➤ Calculating multiple-alignment coverage using fragment midpoints for ",
                         SampleName))
        }

        for(i in 1:16){

          paramS = ScanBamParam(flag=scanBamFlag(isProperPair=TRUE, isUnmappedQuery=FALSE,
                                                 hasUnmappedMate=FALSE),
                                what=c("qname", "mapq", "isize", "seq"),
                                tag=c("NH", "NM"),
                                tagFilter=list(NH=i, NM=c(0:2)))

          AlignmentPairs = suppressWarnings(readGAlignmentPairs(bamFile, param=paramS, strandMode=1))

          if(length(AlignmentPairs) == 0) next

          if(byReads_5p == TRUE){

            # use the strand-specific 5' end of the first mate
            CoveragePoints = granges(GenomicAlignments::first(AlignmentPairs))

            fivePrimePosition = ifelse(as.character(strand(CoveragePoints)) == "+",
                                       start(CoveragePoints), end(CoveragePoints))

            start(CoveragePoints) = fivePrimePosition
            end(CoveragePoints) = fivePrimePosition

          } else {

            # use the midpoint of the complete paired-end fragment
            CoveragePoints = granges(AlignmentPairs)

            midpoint = round((start(CoveragePoints) + end(CoveragePoints))/2)

            start(CoveragePoints) = midpoint
            end(CoveragePoints) = midpoint
          }

          # fractional contribution of multiple alignments
          mcols(CoveragePoints)$weight = 1/i

          CoveragePoints_watson = CoveragePoints[as.character(strand(CoveragePoints)) == "+"]
          CoveragePoints_crick = CoveragePoints[as.character(strand(CoveragePoints)) == "-"]

          if(length(CoveragePoints_watson) > 0){

            Counts_watson = Counts_watson + countOverlapsW(Windows, CoveragePoints_watson,
                                                           weight="weight")
          }

          if(length(CoveragePoints_crick) > 0){

            Counts_crick = Counts_crick + countOverlapsW(Windows, CoveragePoints_crick,
                                                         weight="weight")
          }
        }

        finFile_watson = paste0(dir, Pro_1, "/Coverage_ma_rdna/", SampleName, "_watson.bed")
        finFile_crick = paste0(dir, Pro_1, "/Coverage_ma_rdna/", SampleName, "_crick.bed")

        bed_watson = data.frame(seqnames=as.character(seqnames(Windows)),
                                start=start(Windows)-1L,
                                end=end(Windows),
                                name=paste0(SampleName, "_watson"),
                                score=Counts_watson)

        bed_crick = data.frame(seqnames=as.character(seqnames(Windows)),
                               start=start(Windows)-1L,
                               end=end(Windows),
                               name=paste0(SampleName, "_crick"),
                               score=Counts_crick)

        write.table(bed_watson, file=finFile_watson, quote=FALSE, sep="\t",
                    row.names=FALSE, col.names=FALSE)

        write.table(bed_crick, file=finFile_crick, quote=FALSE, sep="\t",
                    row.names=FALSE, col.names=FALSE)
      }

      BamCoverage(bamFile=paste0(dir, Pro_1, "/", BamFolder, "/", Pro_1, "_", Assay, "_rDNA.bam"), rDNA=TRUE)
      BamCoverage(bamFile=paste0(dir, Pro_1, "/", BamFolder, "/", Pro_1, "_Input_rDNA.bam"), rDNA=TRUE)
      BamCoverage(bamFile=paste0(dir, Pro_1, "/", BamFolder, "/", Pro_1, "_", Assay, "_ma.bam"), rDNA=FALSE)
      BamCoverage(bamFile=paste0(dir, Pro_1, "/", BamFolder, "/", Pro_1, "_Input_ma.bam"), rDNA=FALSE)

    }

  }


  ## Define and process peaks
  #
  message(paste0("⏳ Processing ", Assay, " peaks ..."))
  #

  if(Alignment == "generic"){

    if(!dir.exists(paste0(dir, Pro_1, "/", "Peaks"))){

      IP_Peaks_Processing <- function(IPBam, InBam){

        message(paste0("➤ Processing ", Assay, " peaks for ", Pro_1))

        suppressWarnings(dir.create(paste0(dir, Pro_1, "/", "Peaks")))

        tempdir(check=TRUE)

        IP = tempfile(fileext=".bed")
        Input = tempfile(fileext=".bed")
        peakFile = tempfile(fileext=".bed")
        outDir = tempfile(pattern="MACS2_")

        suppressWarnings(dir.create(outDir))

        # convert assay and Input BAM files to BED
        command_1 = "/Applications/ngsAnalyser.app/Contents/Resources/app/bedtools2/bin/bedtools bamtobed -i %s > %s"

        system(sprintf(command_1, IPBam, IP))
        system(sprintf(command_1, InBam, Input))

        # call genome-wide assay peaks
        command_2 = "macs2 callpeak -t %s -c %s -f BED -g 12157105 -p 10e-6 --nomodel -n Peak --outdir %s 2> /dev/null"

        system(sprintf(command_2, IP, Input, outDir))

        allPeaks = read.delim2(paste0(outDir, "/Peak_peaks.xls"), comment.char="#")

        write.table(allPeaks, file=peakFile, quote=FALSE, row.names=FALSE,
                    sep="\t", col.names=FALSE)

        ColHeads = "\"chrom\\tpeakStart\\tpeakEnd\\tpeakLength\\tpeakSummit\\toriName\\toriStart\\toriEnd\""

        # peaks associated with all known origins
        command_3 = paste0(
          "/Applications/ngsAnalyser.app/Contents/Resources/app/bedtools2/bin/bedtools intersect ",
          "-wa -wb -a %s -b %s | ",
          "awk 'BEGIN {print %s} {OFS=\"\\t\"} {print $1,$2,$3,$4,$5,$14,$12,$13}'"
        )

        Peaks_at_all_Origins = read.table(
          pipe(sprintf(command_3, peakFile, All_Ori_Link, ColHeads)),
          header=TRUE
        )

        # peaks associated with early origins
        Peaks_at_early_Origins = read.table(
          pipe(sprintf(command_3, peakFile, E_Ori_Link, ColHeads)),
          header=TRUE
        )

        # peaks associated with late origins
        Peaks_at_late_Origins = read.table(
          pipe(sprintf(command_3, peakFile, L_Ori_Link, ColHeads)),
          header=TRUE
        )

        # standardize the MACS2 peak columns
        allPeaks = dplyr::rename(allPeaks,
                                 chrom=chr,
                                 peakStart=start,
                                 peakEnd=end,
                                 peakLength=length,
                                 peakSummit=abs_summit)

        # peaks not associated with known origins
        Peaks_at_no_Origins = dplyr::anti_join(
          allPeaks,
          Peaks_at_all_Origins,
          by=c("chrom", "peakStart", "peakEnd")
        )

        # remove duplicate peak entries
        Peaks_at_all_Origins = Peaks_at_all_Origins[ !duplicated(Peaks_at_all_Origins$peakSummit), ]

        Peaks_at_early_Origins = Peaks_at_early_Origins[ !duplicated(Peaks_at_early_Origins$peakSummit), ]

        Peaks_at_late_Origins = Peaks_at_late_Origins[ !duplicated(Peaks_at_late_Origins$peakSummit), ]

        Peaks_at_no_Origins = Peaks_at_no_Origins[ !duplicated(Peaks_at_no_Origins$peakSummit), ]

        # print peak summary
        message("There are", " ",
                nrow(allPeaks), " genome-wide ", Assay, " peaks", "\n",
                nrow(Peaks_at_all_Origins), " were at known origins", "\n",
                nrow(Peaks_at_early_Origins), " were at early origins", "\n",
                nrow(Peaks_at_late_Origins), " were at late origins and", "\n",
                nrow(Peaks_at_no_Origins), " were at non-origin positions.")

        # save all five peak classes
        write.table(
          allPeaks[,1:5],
          file=paste0(dir, Pro_1, "/Peaks/", Pro_1, "_Genomewide_Peaks.bed"),
          quote=FALSE, row.names=FALSE, sep="\t"
        )

        write.table(
          Peaks_at_all_Origins,
          file=paste0(dir, Pro_1, "/Peaks/", Pro_1, "_Origin_Peaks.bed"),
          quote=FALSE, row.names=FALSE, sep="\t"
        )

        write.table(
          Peaks_at_early_Origins,
          file=paste0(dir, Pro_1, "/Peaks/", Pro_1, "_EarlyOrigin_Peaks.bed"),
          quote=FALSE, row.names=FALSE, sep="\t"
        )

        write.table(
          Peaks_at_late_Origins,
          file=paste0(dir, Pro_1, "/Peaks/", Pro_1, "_LateOrigin_Peaks.bed"),
          quote=FALSE, row.names=FALSE, sep="\t"
        )

        write.table(
          Peaks_at_no_Origins[,1:5],
          file=paste0(dir, Pro_1, "/Peaks/", Pro_1, "_NonOrigin_Peaks.bed"),
          quote=FALSE, row.names=FALSE, sep="\t"
        )

        unlink(c(IP, Input, peakFile), recursive=TRUE, force=TRUE)
        unlink(outDir, recursive=TRUE, force=TRUE)
      }

      IP_Peaks_Processing(IPBam=paste0(dir, Pro_1, "/", BamFolder, "/", Pro_1, "_", Assay, ".bam"),
                            InBam=paste0(dir, Pro_1, "/", BamFolder, "/", Pro_1, "_Input.bam"))

    }

  }

  if(Alignment == "malign"){

    if(!dir.exists(paste0(dir, Pro_1, "/", "Peaks_ma"))){

      IP_Peaks_Processing <- function(IPBam, InBam){

        message(paste0("➤ Processing ", Assay, " peaks for ", Pro_1))

        suppressWarnings(dir.create(paste0(dir, Pro_1, "/", "Peaks_ma")))

        tempdir(check=TRUE)

        IP = tempfile(fileext=".bed")
        Input = tempfile(fileext=".bed")
        peakFile = tempfile(fileext=".bed")
        outDir = tempfile(pattern="MACS2_")

        suppressWarnings(dir.create(outDir))

        # convert assay and Input BAM files to BED
        command_1 = "/Applications/ngsAnalyser.app/Contents/Resources/app/bedtools2/bin/bedtools bamtobed -i %s > %s"

        system(sprintf(command_1, IPBam, IP))
        system(sprintf(command_1, InBam, Input))

        # call genome-wide assay peaks
        command_2 = "macs2 callpeak -t %s -c %s -f BED -g 12157105 -p 10e-6 --nomodel -n Peak --outdir %s 2> /dev/null"

        system(sprintf(command_2, IP, Input, outDir))

        allPeaks = read.delim2(paste0(outDir, "/Peak_peaks.xls"), comment.char="#")

        write.table(allPeaks, file=peakFile, quote=FALSE, row.names=FALSE,
                    sep="\t", col.names=FALSE)

        ColHeads = "\"chrom\\tpeakStart\\tpeakEnd\\tpeakLength\\tpeakSummit\\toriName\\toriStart\\toriEnd\""

        # peaks associated with all known origins
        command_3 = paste0(
          "/Applications/ngsAnalyser.app/Contents/Resources/app/bedtools2/bin/bedtools intersect ",
          "-wa -wb -a %s -b %s | ",
          "awk 'BEGIN {print %s} {OFS=\"\\t\"} {print $1,$2,$3,$4,$5,$14,$12,$13}'"
        )

        Peaks_at_all_Origins = read.table(
          pipe(sprintf(command_3, peakFile, All_Ori_Link, ColHeads)),
          header=TRUE
        )

        # peaks associated with early origins
        Peaks_at_early_Origins = read.table(
          pipe(sprintf(command_3, peakFile, E_Ori_Link, ColHeads)),
          header=TRUE
        )

        # peaks associated with late origins
        Peaks_at_late_Origins = read.table(
          pipe(sprintf(command_3, peakFile, L_Ori_Link, ColHeads)),
          header=TRUE
        )

        # standardize the MACS2 peak columns
        allPeaks = dplyr::rename(allPeaks,
                                 chrom=chr,
                                 peakStart=start,
                                 peakEnd=end,
                                 peakLength=length,
                                 peakSummit=abs_summit)

        # peaks not associated with known origins
        Peaks_at_no_Origins = dplyr::anti_join(
          allPeaks,
          Peaks_at_all_Origins,
          by=c("chrom", "peakStart", "peakEnd")
        )

        # remove duplicate peak entries
        Peaks_at_all_Origins = Peaks_at_all_Origins[ !duplicated(Peaks_at_all_Origins$peakSummit), ]

        Peaks_at_early_Origins = Peaks_at_early_Origins[ !duplicated(Peaks_at_early_Origins$peakSummit), ]

        Peaks_at_late_Origins = Peaks_at_late_Origins[ !duplicated(Peaks_at_late_Origins$peakSummit), ]

        Peaks_at_no_Origins = Peaks_at_no_Origins[ !duplicated(Peaks_at_no_Origins$peakSummit), ]

        # print peak summary
        message("There are", " ",
                nrow(allPeaks), " genome-wide ", Assay, " peaks", "\n",
                nrow(Peaks_at_all_Origins), " were at known origins", "\n",
                nrow(Peaks_at_early_Origins), " were at early origins", "\n",
                nrow(Peaks_at_late_Origins), " were at late origins and", "\n",
                nrow(Peaks_at_no_Origins), " were at non-origin positions.")

        # save all five peak classes
        write.table(
          allPeaks[,1:5],
          file=paste0(dir, Pro_1, "/Peaks_ma/", Pro_1, "_Genomewide_Peaks.bed"),
          quote=FALSE, row.names=FALSE, sep="\t"
        )

        write.table(
          Peaks_at_all_Origins,
          file=paste0(dir, Pro_1, "/Peaks_ma/", Pro_1, "_Origin_Peaks.bed"),
          quote=FALSE, row.names=FALSE, sep="\t"
        )

        write.table(
          Peaks_at_early_Origins,
          file=paste0(dir, Pro_1, "/Peaks_ma/", Pro_1, "_EarlyOrigin_Peaks.bed"),
          quote=FALSE, row.names=FALSE, sep="\t"
        )

        write.table(
          Peaks_at_late_Origins,
          file=paste0(dir, Pro_1, "/Peaks_ma/", Pro_1, "_LateOrigin_Peaks.bed"),
          quote=FALSE, row.names=FALSE, sep="\t"
        )

        write.table(
          Peaks_at_no_Origins[,1:5],
          file=paste0(dir, Pro_1, "/Peaks_ma/", Pro_1, "_NonOrigin_Peaks.bed"),
          quote=FALSE, row.names=FALSE, sep="\t"
        )

        unlink(c(IP, Input, peakFile), recursive=TRUE, force=TRUE)
        unlink(outDir, recursive=TRUE, force=TRUE)
      }

      IP_Peaks_Processing(IPBam=paste0(dir, Pro_1, "/", BamFolder, "/", Pro_1, "_", Assay, ".bam"),
                            InBam=paste0(dir, Pro_1, "/", BamFolder, "/", Pro_1, "_Input.bam"))

    }

  }

  if(Alignment == "mrdna"){

    if(!dir.exists(paste0(dir, Pro_1, "/", "Peaks_ma"))){

      IP_Peaks_Processing <- function(IPBam, InBam){

        message(paste0("➤ Processing ", Assay, " peaks for ", Pro_1))

        suppressWarnings(dir.create(paste0(dir, Pro_1, "/", "Peaks_ma")))

        tempdir(check=TRUE)

        IP = tempfile(fileext=".bed")
        Input = tempfile(fileext=".bed")
        peakFile = tempfile(fileext=".bed")
        outDir = tempfile(pattern="MACS2_")

        suppressWarnings(dir.create(outDir))

        # convert assay and Input BAM files to BED
        command_1 = "/Applications/ngsAnalyser.app/Contents/Resources/app/bedtools2/bin/bedtools bamtobed -i %s > %s"

        system(sprintf(command_1, IPBam, IP))
        system(sprintf(command_1, InBam, Input))

        # call genome-wide assay peaks
        command_2 = "macs2 callpeak -t %s -c %s -f BED -g 12157105 -p 10e-6 --nomodel -n Peak --outdir %s 2> /dev/null"

        system(sprintf(command_2, IP, Input, outDir))

        allPeaks = read.delim2(paste0(outDir, "/Peak_peaks.xls"), comment.char="#")

        write.table(allPeaks, file=peakFile, quote=FALSE, row.names=FALSE,
                    sep="\t", col.names=FALSE)

        ColHeads = "\"chrom\\tpeakStart\\tpeakEnd\\tpeakLength\\tpeakSummit\\toriName\\toriStart\\toriEnd\""

        # peaks associated with all known origins
        command_3 = paste0(
          "/Applications/ngsAnalyser.app/Contents/Resources/app/bedtools2/bin/bedtools intersect ",
          "-wa -wb -a %s -b %s | ",
          "awk 'BEGIN {print %s} {OFS=\"\\t\"} {print $1,$2,$3,$4,$5,$14,$12,$13}'"
        )

        Peaks_at_all_Origins = read.table(
          pipe(sprintf(command_3, peakFile, All_Ori_Link, ColHeads)),
          header=TRUE
        )

        # peaks associated with early origins
        Peaks_at_early_Origins = read.table(
          pipe(sprintf(command_3, peakFile, E_Ori_Link, ColHeads)),
          header=TRUE
        )

        # peaks associated with late origins
        Peaks_at_late_Origins = read.table(
          pipe(sprintf(command_3, peakFile, L_Ori_Link, ColHeads)),
          header=TRUE
        )

        # standardize the MACS2 peak columns
        allPeaks = dplyr::rename(allPeaks,
                                 chrom=chr,
                                 peakStart=start,
                                 peakEnd=end,
                                 peakLength=length,
                                 peakSummit=abs_summit)

        # peaks not associated with known origins
        Peaks_at_no_Origins = dplyr::anti_join(
          allPeaks,
          Peaks_at_all_Origins,
          by=c("chrom", "peakStart", "peakEnd")
        )

        # remove duplicate peak entries
        Peaks_at_all_Origins = Peaks_at_all_Origins[ !duplicated(Peaks_at_all_Origins$peakSummit), ]

        Peaks_at_early_Origins = Peaks_at_early_Origins[ !duplicated(Peaks_at_early_Origins$peakSummit), ]

        Peaks_at_late_Origins = Peaks_at_late_Origins[ !duplicated(Peaks_at_late_Origins$peakSummit), ]

        Peaks_at_no_Origins = Peaks_at_no_Origins[ !duplicated(Peaks_at_no_Origins$peakSummit), ]

        # print peak summary
        message("There are", " ",
                nrow(allPeaks), " genome-wide ", Assay, " peaks", "\n",
                nrow(Peaks_at_all_Origins), " were at known origins", "\n",
                nrow(Peaks_at_early_Origins), " were at early origins", "\n",
                nrow(Peaks_at_late_Origins), " were at late origins and", "\n",
                nrow(Peaks_at_no_Origins), " were at non-origin positions.")

        # save all five peak classes
        write.table(
          allPeaks[,1:5],
          file=paste0(dir, Pro_1, "/Peaks_ma/", Pro_1, "_Genomewide_Peaks.bed"),
          quote=FALSE, row.names=FALSE, sep="\t"
        )

        write.table(
          Peaks_at_all_Origins,
          file=paste0(dir, Pro_1, "/Peaks_ma/", Pro_1, "_Origin_Peaks.bed"),
          quote=FALSE, row.names=FALSE, sep="\t"
        )

        write.table(
          Peaks_at_early_Origins,
          file=paste0(dir, Pro_1, "/Peaks_ma/", Pro_1, "_EarlyOrigin_Peaks.bed"),
          quote=FALSE, row.names=FALSE, sep="\t"
        )

        write.table(
          Peaks_at_late_Origins,
          file=paste0(dir, Pro_1, "/Peaks_ma/", Pro_1, "_LateOrigin_Peaks.bed"),
          quote=FALSE, row.names=FALSE, sep="\t"
        )

        write.table(
          Peaks_at_no_Origins[,1:5],
          file=paste0(dir, Pro_1, "/Peaks_ma/", Pro_1, "_NonOrigin_Peaks.bed"),
          quote=FALSE, row.names=FALSE, sep="\t"
        )

        unlink(c(IP, Input, peakFile), recursive=TRUE, force=TRUE)
        unlink(outDir, recursive=TRUE, force=TRUE)
      }

      IP_Peaks_Processing(IPBam=paste0(dir, Pro_1, "/", BamFolder, "/", Pro_1, "_", Assay, "_ma.bam"),
                            InBam=paste0(dir, Pro_1, "/", BamFolder, "/", Pro_1, "_Input_ma.bam"))

    }

  }


  ## Calculate Ratio
  #
  message("⏳ Calculating enrichment ratios...")
  #

  if(Alignment == "generic"){

    if(!dir.exists(paste0(dir, Pro_1, "/", "Ratios"))){

      CalculateRatio <- function(IP_coverage, Input_coverage, RatioName,
                                 NoiseChunkSizeBp=2000, NoiseIterations=2500,
                                 NoiseSeed=123, NoiseSmoothingSpar=0.65,
                                 NoiseFloor=1e-6){

        suppressWarnings(dir.create(paste0(dir, Pro_1, "/", "Ratios")))

        # read and optionally collapse coverage files
        ReadCoverage <- function(coverageFiles){

          coverage = read.table(coverageFiles[1], header=FALSE)

          if(length(coverageFiles) > 1){

            for(j in 2:length(coverageFiles)){

              additionalCoverage = read.table(coverageFiles[j], header=FALSE)

              coordinatesMatch = identical(as.character(coverage[,1]),
                                           as.character(additionalCoverage[,1])) &&
                identical(as.numeric(coverage[,2]), as.numeric(additionalCoverage[,2])) &&
                identical(as.numeric(coverage[,3]), as.numeric(additionalCoverage[,3]))

              if(coordinatesMatch == FALSE){
                stop("Coverage coordinates do not match for strand collapsing.")
              }

              coverage[,5] = as.numeric(coverage[,5]) + as.numeric(additionalCoverage[,5])
            }
          }

          coverage
        }

        IP.df = ReadCoverage(IP_coverage)
        In.df = ReadCoverage(Input_coverage)

        coordinatesMatch = identical(as.character(IP.df[,1]), as.character(In.df[,1])) &&
          identical(as.numeric(IP.df[,2]), as.numeric(In.df[,2])) &&
          identical(as.numeric(IP.df[,3]), as.numeric(In.df[,3]))

        if(coordinatesMatch == FALSE){
          stop(paste0(Assay, " and Input coverage coordinates do not match."))
        }

        IP.df[,5] = as.numeric(IP.df[,5])
        In.df[,5] = as.numeric(In.df[,5])

        # read genome-wide assay peaks
        PeakFile = paste0(dir, Pro_1, "/", "Peaks", "/",
                          Pro_1, "_Genomewide_Peaks.bed")

        if(!file.exists(PeakFile)){
          stop("Genome-wide peak file is missing: ", PeakFile)
        }

        Peaks = read.table(PeakFile, header=TRUE)

        Peaks$peakStart = as.numeric(Peaks$peakStart)
        Peaks$peakEnd = as.numeric(Peaks$peakEnd)

        # merge overlapping peak intervals
        MergeIntervals <- function(intervals){

          if(nrow(intervals) == 0){
            return(intervals)
          }

          intervals = intervals[order(intervals$start, intervals$end), ]
          merged = intervals[1, , drop=FALSE]

          if(nrow(intervals) > 1){

            for(j in 2:nrow(intervals)){

              last = nrow(merged)

              if(intervals$start[j] <= merged$end[last]){

                merged$end[last] = max(merged$end[last], intervals$end[j])

              } else {

                merged = rbind(merged, intervals[j, , drop=FALSE])
              }
            }
          }

          merged
        }

        # construct non-peak regions
        BuildNonPeakGaps <- function(chrom, chromLength){

          Peaks_chr = Peaks[Peaks$chrom == chrom, , drop=FALSE]

          if(nrow(Peaks_chr) == 0){

            return(data.frame(start=0, end=chromLength, length=chromLength))
          }

          intervals = data.frame(start=pmax(0, Peaks_chr$peakStart),
                                 end=pmin(chromLength, Peaks_chr$peakEnd))

          intervals = intervals[
            is.finite(intervals$start) &
              is.finite(intervals$end) &
              intervals$end > intervals$start, ]

          if(nrow(intervals) == 0){

            return(data.frame(start=0, end=chromLength, length=chromLength))
          }

          intervals = MergeIntervals(intervals)

          gaps = data.frame(start=numeric(), end=numeric())
          cursor = 0

          for(j in 1:nrow(intervals)){

            if(intervals$start[j] > cursor){

              gaps = rbind(gaps, data.frame(start=cursor,
                                            end=intervals$start[j]))
            }

            cursor = max(cursor, intervals$end[j])
          }

          if(cursor < chromLength){

            gaps = rbind(gaps, data.frame(start=cursor, end=chromLength))
          }

          if(nrow(gaps) == 0){

            return(data.frame(start=numeric(), end=numeric(),
                              length=numeric()))
          }

          gaps$length = gaps$end - gaps$start
          gaps = gaps[gaps$length >= 200, , drop=FALSE]

          gaps
        }

        SummariseValues <- function(values){

          values = values[is.finite(values)]

          if(length(values) == 0){
            return(NA_real_)
          }

          median(values)
        }

        # predict chromosome-position-dependent noise
        PredictNoise <- function(binCenters, sampleCenters, sampleValues,
                                 fallbackValues){

          sampleOK = is.finite(sampleCenters) & is.finite(sampleValues)

          sampleCenters = sampleCenters[sampleOK]
          sampleValues = sampleValues[sampleOK]

          positiveBackground = fallbackValues[
            is.finite(fallbackValues) & fallbackValues > NoiseFloor
          ]

          if(length(positiveBackground) > 0){

            backgroundFloor = max(
              NoiseFloor,
              as.numeric(quantile(positiveBackground, probs=0.01,
                                  na.rm=TRUE, names=FALSE))
            )

          } else {

            backgroundFloor = NoiseFloor
          }

          fallback = median(fallbackValues, na.rm=TRUE)

          if(!is.finite(fallback) || fallback < backgroundFloor){
            fallback = backgroundFloor
          }

          if(length(sampleValues) < 2 ||
             length(unique(sampleCenters)) < 2){

            return(rep(fallback, length(binCenters)))
          }

          # background smoothing is performed on the log scale
          sampleValues = log(pmax(sampleValues, backgroundFloor))

          sample.df = data.frame(center=round(sampleCenters),
                                 value=sampleValues)

          sample.df = aggregate(value~center, data=sample.df,
                                FUN=function(x) median(x, na.rm=TRUE))

          sample.df = sample.df[order(sample.df$center), ]

          if(nrow(sample.df) < 4 ||
             length(unique(sample.df$value)) < 2){

            prediction = approx(sample.df$center, sample.df$value, xout=binCenters,
                                rule=2, ties="ordered")$y

          } else {

            splineObject = tryCatch(
              smooth.spline(sample.df$center, sample.df$value,
                            spar=NoiseSmoothingSpar),
              error=function(e) NULL
            )

            if(is.null(splineObject)){

              prediction = approx(sample.df$center, sample.df$value, xout=binCenters,
                                  rule=2, ties="ordered")$y

            } else {

              prediction = predict(splineObject, binCenters)$y
            }
          }

          prediction[!is.finite(prediction)] = log(fallback)

          prediction = pmin(
            pmax(prediction, min(sample.df$value)),
            max(sample.df$value)
          )

          prediction = exp(prediction)
          prediction[prediction < backgroundFloor] = backgroundFloor

          prediction
        }

        # estimate assay and Input noise separately
        EstimateNoise <- function(){

          set.seed(NoiseSeed)

          IP_noise = numeric(nrow(IP.df))
          Input_noise = numeric(nrow(In.df))

          chroms = unique(as.character(IP.df[,1]))

          for(chr in chroms){

            chrIndex = which(IP.df[,1] == chr)

            chrStart = as.numeric(IP.df[chrIndex,2])
            chrEnd = as.numeric(IP.df[chrIndex,3])
            chrCenters = (chrStart + chrEnd)/2
            chrLength = max(chrEnd, na.rm=TRUE)

            gaps = BuildNonPeakGaps(chr, chrLength)

            if(nrow(gaps) == 0){

              IP_noise[chrIndex] = max(NoiseFloor,
                                         median(IP.df[chrIndex,5], na.rm=TRUE))

              Input_noise[chrIndex] = max(NoiseFloor,
                                          median(In.df[chrIndex,5], na.rm=TRUE))

              next
            }

            gapProbability = gaps$length/sum(gaps$length)

            sampledGapIndex = sample(1:nrow(gaps), size=NoiseIterations,
                                     replace=TRUE, prob=gapProbability)

            sampleCenters = numeric(NoiseIterations)
            sampledIP = numeric(NoiseIterations)
            sampledInput = numeric(NoiseIterations)

            for(j in 1:NoiseIterations){

              gap = gaps[sampledGapIndex[j], ]
              chunkSize = min(NoiseChunkSizeBp, gap$length)

              if(gap$length > chunkSize){

                chunkStart = runif(1, min=gap$start,
                                   max=gap$end-chunkSize)

              } else {

                chunkStart = gap$start
              }

              chunkEnd = chunkStart + chunkSize

              chunkIndex = which(chrCenters >= chunkStart &
                                   chrCenters <= chunkEnd)

              sampleCenters[j] = (chunkStart + chunkEnd)/2

              sampledIP[j] = SummariseValues(
                IP.df[chrIndex[chunkIndex],5]
              )

              sampledInput[j] = SummariseValues(
                In.df[chrIndex[chunkIndex],5]
              )
            }

            nonPeakIndex = rep(FALSE, length(chrIndex))

            for(j in 1:nrow(gaps)){

              nonPeakIndex = nonPeakIndex |
                (chrCenters >= gaps$start[j] &
                   chrCenters <= gaps$end[j])
            }

            IP_noise[chrIndex] = PredictNoise(
              binCenters=chrCenters,
              sampleCenters=sampleCenters,
              sampleValues=sampledIP,
              fallbackValues=IP.df[chrIndex[nonPeakIndex],5]
            )

            Input_noise[chrIndex] = PredictNoise(
              binCenters=chrCenters,
              sampleCenters=sampleCenters,
              sampleValues=sampledInput,
              fallbackValues=In.df[chrIndex[nonPeakIndex],5]
            )
          }

          list(IP_noise=IP_noise, Input_noise=Input_noise)
        }

        noise = EstimateNoise()

        # library-size normalization
        IP_Sum = sum(IP.df[,5], na.rm=TRUE)
        In_Sum = sum(In.df[,5], na.rm=TRUE)

        if(!is.finite(In_Sum) || In_Sum <= 0){
          stop("Input coverage sum is zero.")
        }

        corrFactor = IP_Sum/In_Sum

        In.score.norm = In.df[,5]*corrFactor
        In.noise.norm = noise$Input_noise*corrFactor

        # calculate the three enrichment ratios
        Ratio.ipin = IP.df[,5]/In.score.norm

        Ratio.ipnoise = IP.df[,5]/noise$IP_noise

        Ratio.ipin.noise = Ratio.ipnoise/
          (In.score.norm/In.noise.norm)

        Ratio.ipin[!is.finite(Ratio.ipin)] = 0
        Ratio.ipnoise[!is.finite(Ratio.ipnoise)] = 0
        Ratio.ipin.noise[!is.finite(Ratio.ipin.noise)] = 0

        # Poisson enrichment probability
        pvalue = ppois(q=IP.df[,5]-1, lambda=In.score.norm,
                       lower.tail=FALSE, log=FALSE)

        ratio.df = data.frame(
          chrom=IP.df[,1],
          chromStart=IP.df[,2],
          chromEnd=IP.df[,3],
          name=RatioName,
          ip.score=IP.df[,5],
          in.score=round(In.score.norm, 4),
          ip.noise=round(noise$IP_noise, 4),
          in.noise=round(In.noise.norm, 4),
          ratio.ipin=round(Ratio.ipin, 4),
          ratio.ipnoise=round(Ratio.ipnoise, 4),
          ratio.ipin.noise=round(Ratio.ipin.noise, 4),
          pvalue=pvalue
        )

        write.table(
          ratio.df,
          file=paste0(dir, Pro_1, "/", "Ratios", "/", RatioName, ".bed"),
          quote=FALSE, row.names=FALSE, sep="\t"
        )
      }

      # Watson-strand ratio
      CalculateRatio(IP_coverage=paste0(dir, Pro_1, "/Coverage/", Pro_1, "_", Assay, "_watson.bed"),
                     Input_coverage=paste0(dir, Pro_1, "/Coverage/", Pro_1, "_Input_watson.bed"),
                     RatioName=paste0(Pro_1, "_", Assay, "_watson"))

      # Crick-strand ratio
      CalculateRatio(IP_coverage=paste0(dir, Pro_1, "/Coverage/", Pro_1, "_", Assay, "_crick.bed"),
                     Input_coverage=paste0(dir, Pro_1, "/Coverage/", Pro_1, "_Input_crick.bed"),
                     RatioName=paste0(Pro_1, "_", Assay, "_crick"))

      # strand-collapsed ratio
      CalculateRatio(IP_coverage=c(paste0(dir, Pro_1, "/Coverage/", Pro_1, "_", Assay, "_watson.bed"),
                                   paste0(dir, Pro_1, "/Coverage/", Pro_1, "_", Assay, "_crick.bed")),
                     Input_coverage=c(paste0(dir, Pro_1, "/Coverage/", Pro_1, "_Input_watson.bed"),
                                      paste0(dir, Pro_1, "/Coverage/", Pro_1, "_Input_crick.bed")),
                     RatioName=paste0(Pro_1, "_", Assay, "_collapsed"))
    }
  }

  if(Alignment == "malign"){

    if(!dir.exists(paste0(dir, Pro_1, "/", "Ratios_ma"))){

      CalculateRatio <- function(IP_coverage, Input_coverage, RatioName,
                                 NoiseChunkSizeBp=2000, NoiseIterations=2500,
                                 NoiseSeed=123, NoiseSmoothingSpar=0.65,
                                 NoiseFloor=1e-6){

        suppressWarnings(dir.create(paste0(dir, Pro_1, "/", "Ratios_ma")))

        # read and optionally collapse coverage files
        ReadCoverage <- function(coverageFiles){

          coverage = read.table(coverageFiles[1], header=FALSE)

          if(length(coverageFiles) > 1){

            for(j in 2:length(coverageFiles)){

              additionalCoverage = read.table(coverageFiles[j], header=FALSE)

              coordinatesMatch = identical(as.character(coverage[,1]),
                                           as.character(additionalCoverage[,1])) &&
                identical(as.numeric(coverage[,2]), as.numeric(additionalCoverage[,2])) &&
                identical(as.numeric(coverage[,3]), as.numeric(additionalCoverage[,3]))

              if(coordinatesMatch == FALSE){
                stop("Coverage coordinates do not match for strand collapsing.")
              }

              coverage[,5] = as.numeric(coverage[,5]) + as.numeric(additionalCoverage[,5])
            }
          }

          coverage
        }

        IP.df = ReadCoverage(IP_coverage)
        In.df = ReadCoverage(Input_coverage)

        coordinatesMatch = identical(as.character(IP.df[,1]), as.character(In.df[,1])) &&
          identical(as.numeric(IP.df[,2]), as.numeric(In.df[,2])) &&
          identical(as.numeric(IP.df[,3]), as.numeric(In.df[,3]))

        if(coordinatesMatch == FALSE){
          stop(paste0(Assay, " and Input coverage coordinates do not match."))
        }

        IP.df[,5] = as.numeric(IP.df[,5])
        In.df[,5] = as.numeric(In.df[,5])

        # read genome-wide assay peaks
        PeakFile = paste0(dir, Pro_1, "/", "Peaks_ma", "/", Pro_1, "_Genomewide_Peaks.bed")

        if(!file.exists(PeakFile)){
          stop("Genome-wide peak file is missing: ", PeakFile)
        }

        Peaks = read.table(PeakFile, header=TRUE)

        Peaks$peakStart = as.numeric(Peaks$peakStart)
        Peaks$peakEnd = as.numeric(Peaks$peakEnd)

        # merge overlapping peak intervals
        MergeIntervals <- function(intervals){

          if(nrow(intervals) == 0){
            return(intervals)
          }

          intervals = intervals[order(intervals$start, intervals$end), ]
          merged = intervals[1, , drop=FALSE]

          if(nrow(intervals) > 1){

            for(j in 2:nrow(intervals)){

              last = nrow(merged)

              if(intervals$start[j] <= merged$end[last]){

                merged$end[last] = max(merged$end[last], intervals$end[j])

              } else {

                merged = rbind(merged, intervals[j, , drop=FALSE])
              }
            }
          }

          merged
        }

        # construct non-peak regions
        BuildNonPeakGaps <- function(chrom, chromLength){

          Peaks_chr = Peaks[Peaks$chrom == chrom, , drop=FALSE]

          if(nrow(Peaks_chr) == 0){

            return(data.frame(start=0, end=chromLength, length=chromLength))
          }

          intervals = data.frame(start=pmax(0, Peaks_chr$peakStart),
                                 end=pmin(chromLength, Peaks_chr$peakEnd))

          intervals = intervals[
            is.finite(intervals$start) &
              is.finite(intervals$end) &
              intervals$end > intervals$start, ]

          if(nrow(intervals) == 0){

            return(data.frame(start=0, end=chromLength, length=chromLength))
          }

          intervals = MergeIntervals(intervals)

          gaps = data.frame(start=numeric(), end=numeric())
          cursor = 0

          for(j in 1:nrow(intervals)){

            if(intervals$start[j] > cursor){

              gaps = rbind(gaps, data.frame(start=cursor,
                                            end=intervals$start[j]))
            }

            cursor = max(cursor, intervals$end[j])
          }

          if(cursor < chromLength){

            gaps = rbind(gaps, data.frame(start=cursor, end=chromLength))
          }

          if(nrow(gaps) == 0){

            return(data.frame(start=numeric(), end=numeric(),
                              length=numeric()))
          }

          gaps$length = gaps$end - gaps$start
          gaps = gaps[gaps$length >= 200, , drop=FALSE]

          gaps
        }

        SummariseValues <- function(values){

          values = values[is.finite(values)]

          if(length(values) == 0){
            return(NA_real_)
          }

          median(values)
        }

        # predict chromosome-position-dependent noise
        PredictNoise <- function(binCenters, sampleCenters, sampleValues,
                                 fallbackValues){

          sampleOK = is.finite(sampleCenters) & is.finite(sampleValues)

          sampleCenters = sampleCenters[sampleOK]
          sampleValues = sampleValues[sampleOK]

          positiveBackground = fallbackValues[
            is.finite(fallbackValues) & fallbackValues > NoiseFloor
          ]

          if(length(positiveBackground) > 0){

            backgroundFloor = max(
              NoiseFloor,
              as.numeric(quantile(positiveBackground, probs=0.01,
                                  na.rm=TRUE, names=FALSE))
            )

          } else {

            backgroundFloor = NoiseFloor
          }

          fallback = median(fallbackValues, na.rm=TRUE)

          if(!is.finite(fallback) || fallback < backgroundFloor){
            fallback = backgroundFloor
          }

          if(length(sampleValues) < 2 ||
             length(unique(sampleCenters)) < 2){

            return(rep(fallback, length(binCenters)))
          }

          # background smoothing is performed on the log scale
          sampleValues = log(pmax(sampleValues, backgroundFloor))

          sample.df = data.frame(center=round(sampleCenters),
                                 value=sampleValues)

          sample.df = aggregate(value~center, data=sample.df,
                                FUN=function(x) median(x, na.rm=TRUE))

          sample.df = sample.df[order(sample.df$center), ]

          if(nrow(sample.df) < 4 ||
             length(unique(sample.df$value)) < 2){

            prediction = approx(sample.df$center, sample.df$value, xout=binCenters,
                                rule=2, ties="ordered")$y

          } else {

            splineObject = tryCatch(
              smooth.spline(sample.df$center, sample.df$value,
                            spar=NoiseSmoothingSpar),
              error=function(e) NULL
            )

            if(is.null(splineObject)){

              prediction = approx(sample.df$center, sample.df$value, xout=binCenters,
                                  rule=2, ties="ordered")$y

            } else {

              prediction = predict(splineObject, binCenters)$y
            }
          }

          prediction[!is.finite(prediction)] = log(fallback)

          prediction = pmin(
            pmax(prediction, min(sample.df$value)),
            max(sample.df$value)
          )

          prediction = exp(prediction)
          prediction[prediction < backgroundFloor] = backgroundFloor

          prediction
        }

        # estimate assay and Input noise separately
        EstimateNoise <- function(){

          set.seed(NoiseSeed)

          IP_noise = numeric(nrow(IP.df))
          Input_noise = numeric(nrow(In.df))

          chroms = unique(as.character(IP.df[,1]))

          for(chr in chroms){

            chrIndex = which(IP.df[,1] == chr)

            chrStart = as.numeric(IP.df[chrIndex,2])
            chrEnd = as.numeric(IP.df[chrIndex,3])
            chrCenters = (chrStart + chrEnd)/2
            chrLength = max(chrEnd, na.rm=TRUE)

            gaps = BuildNonPeakGaps(chr, chrLength)

            if(nrow(gaps) == 0){

              IP_noise[chrIndex] = max(NoiseFloor,
                                         median(IP.df[chrIndex,5], na.rm=TRUE))

              Input_noise[chrIndex] = max(NoiseFloor,
                                          median(In.df[chrIndex,5], na.rm=TRUE))

              next
            }

            gapProbability = gaps$length/sum(gaps$length)

            sampledGapIndex = sample(1:nrow(gaps), size=NoiseIterations,
                                     replace=TRUE, prob=gapProbability)

            sampleCenters = numeric(NoiseIterations)
            sampledIP = numeric(NoiseIterations)
            sampledInput = numeric(NoiseIterations)

            for(j in 1:NoiseIterations){

              gap = gaps[sampledGapIndex[j], ]
              chunkSize = min(NoiseChunkSizeBp, gap$length)

              if(gap$length > chunkSize){

                chunkStart = runif(1, min=gap$start,
                                   max=gap$end-chunkSize)

              } else {

                chunkStart = gap$start
              }

              chunkEnd = chunkStart + chunkSize

              chunkIndex = which(chrCenters >= chunkStart &
                                   chrCenters <= chunkEnd)

              sampleCenters[j] = (chunkStart + chunkEnd)/2

              sampledIP[j] = SummariseValues(
                IP.df[chrIndex[chunkIndex],5]
              )

              sampledInput[j] = SummariseValues(
                In.df[chrIndex[chunkIndex],5]
              )
            }

            nonPeakIndex = rep(FALSE, length(chrIndex))

            for(j in 1:nrow(gaps)){

              nonPeakIndex = nonPeakIndex |
                (chrCenters >= gaps$start[j] &
                   chrCenters <= gaps$end[j])
            }

            IP_noise[chrIndex] = PredictNoise(
              binCenters=chrCenters,
              sampleCenters=sampleCenters,
              sampleValues=sampledIP,
              fallbackValues=IP.df[chrIndex[nonPeakIndex],5]
            )

            Input_noise[chrIndex] = PredictNoise(
              binCenters=chrCenters,
              sampleCenters=sampleCenters,
              sampleValues=sampledInput,
              fallbackValues=In.df[chrIndex[nonPeakIndex],5]
            )
          }

          list(IP_noise=IP_noise, Input_noise=Input_noise)
        }

        noise = EstimateNoise()

        # library-size normalization
        IP_Sum = sum(IP.df[,5], na.rm=TRUE)
        In_Sum = sum(In.df[,5], na.rm=TRUE)

        if(!is.finite(In_Sum) || In_Sum <= 0){
          stop("Input coverage sum is zero.")
        }

        corrFactor = IP_Sum/In_Sum

        In.score.norm = In.df[,5]*corrFactor
        In.noise.norm = noise$Input_noise*corrFactor

        # calculate the three enrichment ratios
        Ratio.ipin = IP.df[,5]/In.score.norm

        Ratio.ipnoise = IP.df[,5]/noise$IP_noise

        Ratio.ipin.noise = Ratio.ipnoise/(In.score.norm/In.noise.norm)

        Ratio.ipin[!is.finite(Ratio.ipin)] = 0
        Ratio.ipnoise[!is.finite(Ratio.ipnoise)] = 0
        Ratio.ipin.noise[!is.finite(Ratio.ipin.noise)] = 0


        ratio.df = data.frame(
          chrom=IP.df[,1],
          chromStart=IP.df[,2],
          chromEnd=IP.df[,3],
          name=RatioName,
          ip.score=IP.df[,5],
          in.score=round(In.score.norm, 4),
          ip.noise=round(noise$IP_noise, 4),
          in.noise=round(In.noise.norm, 4),
          ratio.ipin=round(Ratio.ipin, 4),
          ratio.ipnoise=round(Ratio.ipnoise, 4),
          ratio.ipin.noise=round(Ratio.ipin.noise, 4)
        )

        write.table(
          ratio.df,
          file=paste0(dir, Pro_1, "/", "Ratios_ma", "/", RatioName, ".bed"),
          quote=FALSE, row.names=FALSE, sep="\t"
        )
      }

      # Watson-strand ratio
      CalculateRatio(IP_coverage=paste0(dir, Pro_1, "/Coverage_ma/", Pro_1, "_", Assay, "_watson.bed"),
                     Input_coverage=paste0(dir, Pro_1, "/Coverage_ma/", Pro_1, "_Input_watson.bed"),
                     RatioName=paste0(Pro_1, "_", Assay, "_watson"))

      # Crick-strand ratio
      CalculateRatio(IP_coverage=paste0(dir, Pro_1, "/Coverage_ma/", Pro_1, "_", Assay, "_crick.bed"),
                     Input_coverage=paste0(dir, Pro_1, "/Coverage_ma/", Pro_1, "_Input_crick.bed"),
                     RatioName=paste0(Pro_1, "_", Assay, "_crick"))

      # strand-collapsed ratio
      CalculateRatio(IP_coverage=c(paste0(dir, Pro_1, "/Coverage_ma/", Pro_1, "_", Assay, "_watson.bed"),
                                   paste0(dir, Pro_1, "/Coverage_ma/", Pro_1, "_", Assay, "_crick.bed")),
                     Input_coverage=c(paste0(dir, Pro_1, "/Coverage_ma/", Pro_1, "_Input_watson.bed"),
                                      paste0(dir, Pro_1, "/Coverage_ma/", Pro_1, "_Input_crick.bed")),
                     RatioName=paste0(Pro_1, "_", Assay, "_collapsed"))
    }

  }

  if(Alignment == "mrdna"){

    if(!dir.exists(paste0(dir, Pro_1, "/", "Ratios_ma_rdna"))){

      CalculateRatio <- function(IP_coverage, Input_coverage,
                                 Noise_IP_coverage, Noise_Input_coverage,
                                 RatioName, NoiseChunkSizeBp=2000,
                                 NoiseIterations=2500, NoiseSeed=123,
                                 NoiseSmoothingSpar=0.65, NoiseFloor=1e-6){

        suppressWarnings(dir.create(paste0(dir, Pro_1, "/", "Ratios_ma_rdna")))

        # read and optionally collapse coverage files
        ReadCoverage <- function(coverageFiles){

          coverage = read.table(coverageFiles[1], header=FALSE)

          if(length(coverageFiles) > 1){

            for(j in 2:length(coverageFiles)){

              additionalCoverage = read.table(coverageFiles[j], header=FALSE)

              coordinatesMatch = identical(as.character(coverage[,1]),
                                           as.character(additionalCoverage[,1])) &&
                identical(as.numeric(coverage[,2]), as.numeric(additionalCoverage[,2])) &&
                identical(as.numeric(coverage[,3]), as.numeric(additionalCoverage[,3]))

              if(coordinatesMatch == FALSE){
                stop("Coverage coordinates do not match for strand collapsing.")
              }

              coverage[,5] = as.numeric(coverage[,5]) +
                as.numeric(additionalCoverage[,5])
            }
          }

          coverage
        }

        # rDNA-reference coverage used for final ratio calculation
        IP.df = ReadCoverage(IP_coverage)
        In.df = ReadCoverage(Input_coverage)

        coordinatesMatch = identical(as.character(IP.df[,1]),
                                     as.character(In.df[,1])) &&
          identical(as.numeric(IP.df[,2]), as.numeric(In.df[,2])) &&
          identical(as.numeric(IP.df[,3]), as.numeric(In.df[,3]))

        if(coordinatesMatch == FALSE){
          stop(paste0("rDNA ", Assay, " and Input coverage coordinates do not match."))
        }

        IP.df[,5] = as.numeric(IP.df[,5])
        In.df[,5] = as.numeric(In.df[,5])

        # whole-genome coverage used for background estimation
        Noise.IP.df = ReadCoverage(Noise_IP_coverage)
        Noise.In.df = ReadCoverage(Noise_Input_coverage)

        noiseCoordinatesMatch = identical(as.character(Noise.IP.df[,1]),
                                          as.character(Noise.In.df[,1])) &&
          identical(as.numeric(Noise.IP.df[,2]),
                    as.numeric(Noise.In.df[,2])) &&
          identical(as.numeric(Noise.IP.df[,3]),
                    as.numeric(Noise.In.df[,3]))

        if(noiseCoordinatesMatch == FALSE){
          stop(paste0("Whole-genome ", Assay, " and Input coverage coordinates do not match."))
        }

        Noise.IP.df[,5] = as.numeric(Noise.IP.df[,5])
        Noise.In.df[,5] = as.numeric(Noise.In.df[,5])

        # read peaks obtained from whole-genome multiple alignments
        PeakFile = paste0(dir, Pro_1, "/", "Peaks_ma", "/",
                          Pro_1, "_Genomewide_Peaks.bed")

        if(!file.exists(PeakFile)){
          stop("Genome-wide peak file is missing: ", PeakFile)
        }

        Peaks = read.table(PeakFile, header=TRUE)

        Peaks$peakStart = as.numeric(Peaks$peakStart)
        Peaks$peakEnd = as.numeric(Peaks$peakEnd)

        # merge overlapping peak intervals
        MergeIntervals <- function(intervals){

          if(nrow(intervals) == 0){
            return(intervals)
          }

          intervals = intervals[order(intervals$start, intervals$end), ]
          merged = intervals[1, , drop=FALSE]

          if(nrow(intervals) > 1){

            for(j in 2:nrow(intervals)){

              last = nrow(merged)

              if(intervals$start[j] <= merged$end[last]){

                merged$end[last] = max(merged$end[last],
                                       intervals$end[j])

              } else {

                merged = rbind(merged, intervals[j, , drop=FALSE])
              }
            }
          }

          merged
        }

        # construct whole-genome non-peak regions
        BuildNonPeakGaps <- function(chrom, chromLength){

          Peaks_chr = Peaks[Peaks$chrom == chrom, , drop=FALSE]

          if(nrow(Peaks_chr) == 0){

            return(data.frame(start=0, end=chromLength,
                              length=chromLength))
          }

          intervals = data.frame(start=pmax(0, Peaks_chr$peakStart),
                                 end=pmin(chromLength, Peaks_chr$peakEnd))

          intervals = intervals[
            is.finite(intervals$start) &
              is.finite(intervals$end) &
              intervals$end > intervals$start, ]

          if(nrow(intervals) == 0){

            return(data.frame(start=0, end=chromLength,
                              length=chromLength))
          }

          intervals = MergeIntervals(intervals)

          gaps = data.frame(start=numeric(), end=numeric())
          cursor = 0

          for(j in 1:nrow(intervals)){

            if(intervals$start[j] > cursor){

              gaps = rbind(
                gaps,
                data.frame(start=cursor, end=intervals$start[j])
              )
            }

            cursor = max(cursor, intervals$end[j])
          }

          if(cursor < chromLength){

            gaps = rbind(
              gaps,
              data.frame(start=cursor, end=chromLength)
            )
          }

          if(nrow(gaps) == 0){

            return(data.frame(start=numeric(), end=numeric(),
                              length=numeric()))
          }

          gaps$length = gaps$end - gaps$start
          gaps = gaps[gaps$length >= 200, , drop=FALSE]

          gaps
        }

        SummariseValues <- function(values){

          values = values[is.finite(values)]

          if(length(values) == 0){
            return(NA_real_)
          }

          median(values)
        }

        # predict chromosome-position-dependent background
        PredictNoise <- function(binCenters, sampleCenters, sampleValues,
                                 fallbackValues){

          sampleOK = is.finite(sampleCenters) &
            is.finite(sampleValues)

          sampleCenters = sampleCenters[sampleOK]
          sampleValues = sampleValues[sampleOK]

          positiveBackground = fallbackValues[
            is.finite(fallbackValues) &
              fallbackValues > NoiseFloor
          ]

          if(length(positiveBackground) > 0){

            backgroundFloor = max(
              NoiseFloor,
              as.numeric(
                quantile(
                  positiveBackground,
                  probs=0.01,
                  na.rm=TRUE,
                  names=FALSE
                )
              )
            )

          } else {

            backgroundFloor = NoiseFloor
          }

          fallback = median(fallbackValues, na.rm=TRUE)

          if(!is.finite(fallback) || fallback < backgroundFloor){
            fallback = backgroundFloor
          }

          if(length(sampleValues) < 2 ||
             length(unique(sampleCenters)) < 2){

            return(rep(fallback, length(binCenters)))
          }

          # background smoothing is performed on the log scale
          sampleValues = log(pmax(sampleValues, backgroundFloor))

          sample.df = data.frame(center=round(sampleCenters),
                                 value=sampleValues)

          sample.df = aggregate(
            value~center,
            data=sample.df,
            FUN=function(x) median(x, na.rm=TRUE)
          )

          sample.df = sample.df[order(sample.df$center), ]

          if(nrow(sample.df) < 4 ||
             length(unique(sample.df$value)) < 2){

            prediction = approx(sample.df$center, sample.df$value, xout=binCenters,
                                rule=2, ties="ordered")$y

          } else {

            splineObject = tryCatch(
              smooth.spline(
                sample.df$center,
                sample.df$value,
                spar=NoiseSmoothingSpar
              ),
              error=function(e) NULL
            )

            if(is.null(splineObject)){

              prediction = approx(sample.df$center, sample.df$value, xout=binCenters,
                                  rule=2, ties="ordered")$y

            } else {

              prediction = predict(splineObject, binCenters)$y
            }
          }

          prediction[!is.finite(prediction)] = log(fallback)

          prediction = pmin(
            pmax(prediction, min(sample.df$value)),
            max(sample.df$value)
          )

          prediction = exp(prediction)
          prediction[prediction < backgroundFloor] = backgroundFloor

          prediction
        }

        # estimate background from whole-genome non-peak coverage
        EstimateNoise <- function(){

          set.seed(NoiseSeed)

          IP_noise = numeric(nrow(Noise.IP.df))
          Input_noise = numeric(nrow(Noise.In.df))

          chroms = unique(as.character(Noise.IP.df[,1]))

          for(chr in chroms){

            chrIndex = which(Noise.IP.df[,1] == chr)

            chrStart = as.numeric(Noise.IP.df[chrIndex,2])
            chrEnd = as.numeric(Noise.IP.df[chrIndex,3])
            chrCenters = (chrStart + chrEnd)/2
            chrLength = max(chrEnd, na.rm=TRUE)

            gaps = BuildNonPeakGaps(chr, chrLength)

            if(nrow(gaps) == 0){

              IP_noise[chrIndex] = max(
                NoiseFloor,
                median(Noise.IP.df[chrIndex,5], na.rm=TRUE)
              )

              Input_noise[chrIndex] = max(
                NoiseFloor,
                median(Noise.In.df[chrIndex,5], na.rm=TRUE)
              )

              next
            }

            gapProbability = gaps$length/sum(gaps$length)

            sampledGapIndex = sample(
              1:nrow(gaps),
              size=NoiseIterations,
              replace=TRUE,
              prob=gapProbability
            )

            sampleCenters = numeric(NoiseIterations)
            sampledIP = numeric(NoiseIterations)
            sampledInput = numeric(NoiseIterations)

            for(j in 1:NoiseIterations){

              gap = gaps[sampledGapIndex[j], ]
              chunkSize = min(NoiseChunkSizeBp, gap$length)

              if(gap$length > chunkSize){

                chunkStart = runif(
                  1,
                  min=gap$start,
                  max=gap$end-chunkSize
                )

              } else {

                chunkStart = gap$start
              }

              chunkEnd = chunkStart + chunkSize

              chunkIndex = which(
                chrCenters >= chunkStart &
                  chrCenters <= chunkEnd
              )

              sampleCenters[j] = (chunkStart + chunkEnd)/2

              sampledIP[j] = SummariseValues(
                Noise.IP.df[chrIndex[chunkIndex],5]
              )

              sampledInput[j] = SummariseValues(
                Noise.In.df[chrIndex[chunkIndex],5]
              )
            }

            nonPeakIndex = rep(FALSE, length(chrIndex))

            for(j in 1:nrow(gaps)){

              nonPeakIndex = nonPeakIndex |
                (chrCenters >= gaps$start[j] &
                   chrCenters <= gaps$end[j])
            }

            IP_noise[chrIndex] = PredictNoise(
              binCenters=chrCenters,
              sampleCenters=sampleCenters,
              sampleValues=sampledIP,
              fallbackValues=Noise.IP.df[
                chrIndex[nonPeakIndex],5
              ]
            )

            Input_noise[chrIndex] = PredictNoise(
              binCenters=chrCenters,
              sampleCenters=sampleCenters,
              sampleValues=sampledInput,
              fallbackValues=Noise.In.df[
                chrIndex[nonPeakIndex],5
              ]
            )
          }

          list(IP_noise=IP_noise,
               Input_noise=Input_noise)
        }

        noise = EstimateNoise()

        # whole-genome library-size normalization
        IP_Sum = sum(Noise.IP.df[,5], na.rm=TRUE)
        In_Sum = sum(Noise.In.df[,5], na.rm=TRUE)

        if(!is.finite(In_Sum) || In_Sum <= 0){
          stop("Whole-genome Input coverage sum is zero.")
        }

        corrFactor = IP_Sum/In_Sum

        # convert whole-genome background profiles into transferable levels
        positive.IP.noise = noise$IP_noise[
          is.finite(noise$IP_noise) & noise$IP_noise > NoiseFloor
        ]

        positive.In.noise = noise$Input_noise[
          is.finite(noise$Input_noise) & noise$Input_noise > NoiseFloor
        ]

        IP.noise = median(positive.IP.noise, na.rm=TRUE)
        In.noise = median(positive.In.noise, na.rm=TRUE)*corrFactor

        if(!is.finite(IP.noise) || IP.noise < NoiseFloor){
          IP.noise = NoiseFloor
        }

        if(!is.finite(In.noise) || In.noise < NoiseFloor){
          In.noise = NoiseFloor
        }

        # normalize rDNA Input using the whole-genome correction factor
        In.score.norm = In.df[,5]*corrFactor

        # calculate rDNA enrichment ratios
        Ratio.ipin = IP.df[,5]/In.score.norm

        Ratio.ipnoise = IP.df[,5]/IP.noise

        Ratio.ipin.noise = Ratio.ipnoise/
          (In.score.norm/In.noise)

        Ratio.ipin[!is.finite(Ratio.ipin)] = 0
        Ratio.ipnoise[!is.finite(Ratio.ipnoise)] = 0
        Ratio.ipin.noise[!is.finite(Ratio.ipin.noise)] = 0

        # output contains rDNA coordinates only
        ratio.df = data.frame(
          chrom=IP.df[,1],
          chromStart=IP.df[,2],
          chromEnd=IP.df[,3],
          name=RatioName,
          ip.score=IP.df[,5],
          in.score=round(In.score.norm, 4),
          ip.noise=round(rep(IP.noise, nrow(IP.df)), 4),
          in.noise=round(rep(In.noise, nrow(IP.df)), 4),
          ratio.ipin=round(Ratio.ipin, 4),
          ratio.ipnoise=round(Ratio.ipnoise, 4),
          ratio.ipin.noise=round(Ratio.ipin.noise, 4)
        )

        write.table(
          ratio.df,
          file=paste0(dir, Pro_1, "/", "Ratios_ma_rdna", "/",
                      RatioName, ".bed"),
          quote=FALSE, row.names=FALSE, sep="\t"
        )
      }

      # Watson-strand rDNA ratio
      CalculateRatio(
        IP_coverage=paste0(
          dir, Pro_1, "/Coverage_ma_rdna/",
          Pro_1, "_", Assay, "_rDNA_watson.bed"
        ),
        Input_coverage=paste0(
          dir, Pro_1, "/Coverage_ma_rdna/",
          Pro_1, "_Input_rDNA_watson.bed"
        ),
        Noise_IP_coverage=paste0(
          dir, Pro_1, "/Coverage_ma_rdna/",
          Pro_1, "_", Assay, "_ma_watson.bed"
        ),
        Noise_Input_coverage=paste0(
          dir, Pro_1, "/Coverage_ma_rdna/",
          Pro_1, "_Input_ma_watson.bed"
        ),
        RatioName=paste0(Pro_1, "_", Assay, "_rDNA_watson")
      )

      # Crick-strand rDNA ratio
      CalculateRatio(
        IP_coverage=paste0(
          dir, Pro_1, "/Coverage_ma_rdna/",
          Pro_1, "_", Assay, "_rDNA_crick.bed"
        ),
        Input_coverage=paste0(
          dir, Pro_1, "/Coverage_ma_rdna/",
          Pro_1, "_Input_rDNA_crick.bed"
        ),
        Noise_IP_coverage=paste0(
          dir, Pro_1, "/Coverage_ma_rdna/",
          Pro_1, "_", Assay, "_ma_crick.bed"
        ),
        Noise_Input_coverage=paste0(
          dir, Pro_1, "/Coverage_ma_rdna/",
          Pro_1, "_Input_ma_crick.bed"
        ),
        RatioName=paste0(Pro_1, "_", Assay, "_rDNA_crick")
      )

      # strand-collapsed rDNA ratio
      CalculateRatio(
        IP_coverage=c(
          paste0(
            dir, Pro_1, "/Coverage_ma_rdna/",
            Pro_1, "_", Assay, "_rDNA_watson.bed"
          ),
          paste0(
            dir, Pro_1, "/Coverage_ma_rdna/",
            Pro_1, "_", Assay, "_rDNA_crick.bed"
          )
        ),
        Input_coverage=c(
          paste0(
            dir, Pro_1, "/Coverage_ma_rdna/",
            Pro_1, "_Input_rDNA_watson.bed"
          ),
          paste0(
            dir, Pro_1, "/Coverage_ma_rdna/",
            Pro_1, "_Input_rDNA_crick.bed"
          )
        ),
        Noise_IP_coverage=c(
          paste0(
            dir, Pro_1, "/Coverage_ma_rdna/",
            Pro_1, "_", Assay, "_ma_watson.bed"
          ),
          paste0(
            dir, Pro_1, "/Coverage_ma_rdna/",
            Pro_1, "_", Assay, "_ma_crick.bed"
          )
        ),
        Noise_Input_coverage=c(
          paste0(
            dir, Pro_1, "/Coverage_ma_rdna/",
            Pro_1, "_Input_ma_watson.bed"
          ),
          paste0(
            dir, Pro_1, "/Coverage_ma_rdna/",
            Pro_1, "_Input_ma_crick.bed"
          )
        ),
        RatioName=paste0(Pro_1, "_", Assay, "_rDNA_collapsed")
      )
    }

  }

  ##

  rm(list=ls())
  gc()

  #
  message("✅ Alignment & Primary Analysis complete!")
  #

}



##


## Focused Early/Late origin enrichment report for either ChIP or BrDU. This
## single public function replaces the duplicated ChIPseq_Analysis_early_late
## and BrDUseq_Analysis_early_late implementations. It reads the processed
## project-local Early/Late BED files and the final ratio table(s) written by
## the current primary analysis. It never reads BAM/coverage files, simulates
## positions, estimates noise, filters signal, or recalculates ratios. chrM is
## excluded. Median midpoint-centred profiles use no interpolation or zero
## padding; spline smoothing and optional log transformation are display-only.
## Strand-separated profiles keep Watson positive and mirror Crick below zero.
## Untransformed ratio panels mark 1 as the neutral reference (0 after log2),
## without rebasing the saved ratio values. Raw coverage remains data-scaled.
##
## The original three profile pages are retained and a fourth comparative
## distribution page is added:
##   1. experiment title and Early/Late origin counts;
##   2. Early and Late rows by all four final metrics;
##   3. Early-versus-Late profiles for all four final metrics;
##   4. four strand-collapsed metric panels, each containing side-by-side Early
##      and Late per-origin boxplots. Each origin contributes its arithmetic
##      mean within +/-Window; outlier dots are hidden. For a strand-separated
##      report, page 4 reads the saved collapsed primary-analysis ratio table.
##
## Example:
## ChIP_BrDU_Early_Late_Enrichment_Plotter(
##   SampleDir="/path/to/sample-ChIP",
##   Assay="ChIP",
##   Alignment="generic",
##   StrandMode="collapsed",
##   Log2Profile=FALSE,
##   Window=3000
## )
ChIP_BrDU_Early_Late_Enrichment_Plotter <- function(
    SampleDir,
    Assay=c("ChIP", "BrDU"),
    Alignment=c("generic", "malign"),
    StrandMode=c("collapsed", "separated"),
    Log2Profile=FALSE,
    Window=3000,
    OutputDir=NULL){

  Metrics <- c("ip.score", "ratio.ipin", "ratio.ipnoise", "ratio.ipin.noise")
  MetricYLabels <- c(
    "Coverage",
    "Enrichment over input",
    "Enrichment over noise",
    "Clean enrichment"
  )
  names(MetricYLabels) <- Metrics
  OriginClasses <- c("EarlyOrigin", "LateOrigin")
  NuclearChromosomes <- paste0("chr", as.character(as.roman(seq_len(16L))))
  ProfileColor <- "darkorchid4"
  WatsonColor <- "brown3"
  CrickColor <- "cornflowerblue"
  EarlyColor <- grDevices::adjustcolor("darkorchid4", alpha.f=0.9)
  LateColor <- grDevices::adjustcolor("darkorange3", alpha.f=0.9)
  SmoothingSpar <- 0.5
  PdfWidth <- 12
  PdfHeight <- 10

  Assay <- match.arg(Assay)
  Alignment <- match.arg(Alignment)
  StrandMode <- match.arg(StrandMode)
  MetricTitles <- if(Assay == "BrDU"){
    c("BrDU", "BrDU / Input", "BrDU / Noise", "Clean")
  } else {
    c("ChIP", "ChIP / Input", "ChIP / Noise", "Clean")
  }
  names(MetricTitles) <- Metrics
  if(!is.logical(Log2Profile) || length(Log2Profile) != 1L ||
     is.na(Log2Profile)){
    stop("Log2Profile must be TRUE or FALSE.", call.=FALSE)
  }
  TransformLabel <- if(Log2Profile){
    if(StrandMode == "separated") "log2(1+x)" else "log2(x)"
  } else {
    "untransformed"
  }
  if(length(SampleDir) != 1L || is.na(SampleDir) || !nzchar(SampleDir)){
    stop("SampleDir must be one existing sample directory.", call.=FALSE)
  }
  if(!dir.exists(SampleDir)){
    stop("SampleDir does not exist: ", SampleDir, call.=FALSE)
  }
  SampleDir <- normalizePath(SampleDir, winslash="/", mustWork=TRUE)
  SampleName <- basename(SampleDir)
  if(length(Window) != 1L || !is.numeric(Window) || !is.finite(Window) ||
     Window <= 0 || abs(Window-round(Window)) > sqrt(.Machine$double.eps)){
    stop("Window must be one positive whole number of base pairs.", call.=FALSE)
  }
  Window <- as.integer(round(Window))

  if(is.null(OutputDir)){
    OutputDir <- SampleDir
  }
  if(length(OutputDir) != 1L || is.na(OutputDir) || !nzchar(OutputDir)){
    stop("OutputDir must be NULL or one directory path.", call.=FALSE)
  }
  if(!dir.exists(OutputDir)){
    dir.create(OutputDir, recursive=TRUE, showWarnings=FALSE)
  }
  if(!dir.exists(OutputDir)){
    stop("Could not create OutputDir: ", OutputDir, call.=FALSE)
  }
  OutputDir <- normalizePath(OutputDir, winslash="/", mustWork=TRUE)

  if(!requireNamespace("data.table", quietly=TRUE)){
    stop(
      "The data.table package is required to read and summarize Early/Late profiles efficiently.",
      call.=FALSE
    )
  }

  SupportPaths <- ChIP_BrDU_Project_Paths(check=TRUE)
  OriginFiles <- c(
    EarlyOrigin=SupportPaths$elements$early_origins,
    LateOrigin=SupportPaths$elements$late_origins
  )
  RatioFolder <- if(Alignment == "generic") "Ratios" else "Ratios_ma"
  RatioDir <- file.path(SampleDir, RatioFolder)
  CollapsedRatioFile <- file.path(
    RatioDir,
    paste0(SampleName, "_", Assay, "_collapsed.bed")
  )
  RatioFiles <- if(StrandMode == "collapsed"){
    c(collapsed=CollapsedRatioFile)
  } else {
    c(
      watson=file.path(
        RatioDir,
        paste0(SampleName, "_", Assay, "_watson.bed")
      ),
      crick=file.path(
        RatioDir,
        paste0(SampleName, "_", Assay, "_crick.bed")
      )
    )
  }
  RequiredFiles <- unique(c(
    OriginFiles,
    RatioFiles,
    collapsed_boxplots=CollapsedRatioFile
  ))
  MissingFiles <- RequiredFiles[!file.exists(RequiredFiles)]
  if(length(MissingFiles) > 0L){
    stop(
      "Required support or primary-analysis output file(s) are missing:\n",
      paste(MissingFiles, collapse="\n"),
      call.=FALSE
    )
  }

  PrettyOriginClass <- function(origin_class){
    switch(
      origin_class,
      EarlyOrigin="Early origins",
      LateOrigin="Late origins",
      origin_class
    )
  }
  ShortOriginClass <- function(origin_class){
    if(origin_class == "EarlyOrigin") "E" else "L"
  }
  ReadOriginFile <- function(file, origin_class){
    Origins <- data.table::fread(
      file,
      header=TRUE,
      sep="\t",
      showProgress=FALSE,
      data.table=TRUE
    )
    RequiredColumns <- c(
      "chrom", "chromStart", "chromEnd", "name", "score", "strand", "type"
    )
    MissingColumns <- setdiff(RequiredColumns, names(Origins))
    if(length(MissingColumns) > 0L){
      stop(
        PrettyOriginClass(origin_class),
        " annotation is missing required column(s): ",
        paste(MissingColumns, collapse=", "), "\n", file,
        call.=FALSE
      )
    }
    Origins <- Origins[, .(
      chrom=as.character(chrom),
      chromStart=as.numeric(chromStart),
      chromEnd=as.numeric(chromEnd),
      originName=as.character(name)
    )]
    ChrMOmitted <- sum(Origins$chrom == "chrM", na.rm=TRUE)
    Origins <- Origins[chrom != "chrM"]
    if(nrow(Origins) == 0L){
      stop(
        "No nuclear records remain in the ", PrettyOriginClass(origin_class),
        " annotation after excluding chrM: ", file,
        call.=FALSE
      )
    }
    CoordinateValues <- unlist(
      Origins[, .(chromStart, chromEnd)],
      use.names=FALSE
    )
    if(any(!nzchar(Origins$chrom)) || any(!is.finite(CoordinateValues)) ||
       any(Origins$chromStart < 0) ||
       any(Origins$chromEnd <= Origins$chromStart)){
      stop("Invalid nuclear origin coordinates in: ", file, call.=FALSE)
    }
    UnexpectedChromosomes <- setdiff(unique(Origins$chrom), NuclearChromosomes)
    if(length(UnexpectedChromosomes) > 0L){
      stop(
        "Unexpected chromosome name(s) in ", file, ": ",
        paste(UnexpectedChromosomes, collapse=", "),
        call.=FALSE
      )
    }
    OriginKey <- paste(
      Origins$chrom, Origins$chromStart, Origins$chromEnd,
      sep="\r"
    )
    if(anyDuplicated(OriginKey)){
      stop(
        "Duplicated nuclear coordinates were found in the ",
        PrettyOriginClass(origin_class), " annotation: ", file,
        call.=FALSE
      )
    }
    Origins[, originCenter := (chromStart+chromEnd)/2]
    data.table::setorder(Origins, chrom, originCenter, chromStart, chromEnd)
    list(table=Origins, chrM_omitted=ChrMOmitted)
  }

  OriginResults <- lapply(
    OriginClasses,
    function(origin_class){
      ReadOriginFile(OriginFiles[[origin_class]], origin_class)
    }
  )
  names(OriginResults) <- OriginClasses
  Origins <- lapply(OriginResults, `[[`, "table")
  OriginCounts <- vapply(Origins, nrow, integer(1))
  OriginChrMOmitted <- vapply(OriginResults, `[[`, integer(1), "chrM_omitted")

  RatioColumns <- c("chrom", "chromStart", "chromEnd", Metrics)
  ReadRatioTable <- function(file, table_label){
    RatioHeader <- names(data.table::fread(
      file,
      header=TRUE,
      sep="\t",
      nrows=0L,
      showProgress=FALSE,
      data.table=TRUE
    ))
    MissingRatioColumns <- setdiff(RatioColumns, RatioHeader)
    if(length(MissingRatioColumns) > 0L){
      stop(
        table_label, " ratio table is missing required column(s): ",
        paste(MissingRatioColumns, collapse=", "), "\n", file,
        call.=FALSE
      )
    }
    Ratio <- data.table::fread(
      file,
      header=TRUE,
      sep="\t",
      select=RatioColumns,
      showProgress=FALSE,
      data.table=TRUE
    )
    if(nrow(Ratio) == 0L){
      stop(table_label, " ratio table is empty: ", file, call.=FALSE)
    }
    Ratio[, chrom := as.character(chrom)]
    for(column in setdiff(RatioColumns, "chrom")){
      data.table::set(Ratio, j=column, value=as.numeric(Ratio[[column]]))
    }
    if(any(!nzchar(Ratio$chrom)) ||
       any(!is.finite(Ratio$chromStart)) ||
       any(!is.finite(Ratio$chromEnd))){
      stop(
        table_label, " ratio table contains invalid genomic coordinates: ",
        file,
        call.=FALSE
      )
    }
    ChrMOmitted <- sum(Ratio$chrom == "chrM", na.rm=TRUE)
    Ratio <- Ratio[chrom != "chrM"]
    if(nrow(Ratio) == 0L){
      stop(
        table_label,
        " ratio table has no nuclear rows after excluding chrM: ", file,
        call.=FALSE
      )
    }
    TableBinWidths <- Ratio$chromEnd-Ratio$chromStart
    if(any(!is.finite(TableBinWidths)) || any(TableBinWidths <= 0)){
      stop(
        table_label, " ratio table contains a non-positive genomic-window width: ",
        file,
        call.=FALSE
      )
    }
    BinWidthCounts <- data.table::data.table(binWidth=TableBinWidths)[
      , .N, by=binWidth
    ][order(-N, binWidth)]
    TableBinWidth <- as.numeric(BinWidthCounts$binWidth[[1]])
    MetricValues <- unlist(Ratio[, ..Metrics], use.names=FALSE)
    if(any(!is.finite(MetricValues))){
      stop(
        table_label, " ratio table contains a non-finite nuclear metric value: ",
        file,
        call.=FALSE
      )
    }
    if(Log2Profile && any(MetricValues < 0)){
      stop(
        table_label,
        " ratio table contains a negative nuclear value, which cannot use Log2Profile: ",
        file,
        call.=FALSE
      )
    }
    if(anyDuplicated(Ratio[, .(chrom, chromStart)])){
      stop(
        table_label,
        " ratio table contains duplicated nuclear chrom/chromStart coordinates: ",
        file,
        call.=FALSE
      )
    }
    data.table::setorder(Ratio, chrom, chromStart)
    StepCounts <- Ratio[, .(
      delta=diff(sort(unique(chromStart)))
    ), by=chrom][delta > 0, .N, by=delta][order(-N, delta)]
    if(nrow(StepCounts) == 0L || !is.finite(StepCounts$delta[[1]]) ||
       StepCounts$delta[[1]] <= 0){
      stop(
        "Could not infer a positive sliding-window step from ",
        table_label, " ratio table: ", file,
        call.=FALSE
      )
    }
    TableStep <- as.numeric(StepCounts$delta[[1]])
    if(abs(TableStep-round(TableStep)) > sqrt(.Machine$double.eps)){
      stop(
        "The inferred sliding-window step in the ", table_label,
        " ratio table is not a whole number of base pairs.",
        call.=FALSE
      )
    }
    list(
      table=Ratio,
      step=as.integer(round(TableStep)),
      bin_width=TableBinWidth,
      chrM_omitted=ChrMOmitted
    )
  }

  RatioResults <- lapply(
    names(RatioFiles),
    function(table_label){
      ReadRatioTable(RatioFiles[[table_label]], table_label)
    }
  )
  names(RatioResults) <- names(RatioFiles)
  RatioTables <- lapply(RatioResults, `[[`, "table")
  RatioSteps <- vapply(RatioResults, `[[`, integer(1), "step")
  RatioBinWidths <- vapply(RatioResults, `[[`, numeric(1), "bin_width")
  RatioChrMOmitted <- vapply(RatioResults, `[[`, integer(1), "chrM_omitted")
  if(length(unique(RatioSteps)) != 1L){
    stop(
      "Watson and Crick ratio tables do not use the same sliding-window step.",
      call.=FALSE
    )
  }
  Step <- unname(RatioSteps[[1]])
  BinWidth <- unname(RatioBinWidths[[1]])
  if(StrandMode == "separated"){
    WatsonRatio <- RatioTables$watson
    CrickRatio <- RatioTables$crick
    CoordinatesMatch <-
      nrow(WatsonRatio) == nrow(CrickRatio) &&
      identical(WatsonRatio$chrom, CrickRatio$chrom) &&
      identical(WatsonRatio$chromStart, CrickRatio$chromStart) &&
      identical(WatsonRatio$chromEnd, CrickRatio$chromEnd)
    if(!CoordinatesMatch){
      stop(
        "Watson and Crick nuclear ratio-table coordinates do not match for ",
        SampleName, ".",
        call.=FALSE
      )
    }
  }
  if(abs(Window/Step-round(Window/Step)) > sqrt(.Machine$double.eps)){
    stop(
      "Window (", Window, " bp) must be an exact multiple of the inferred ",
      "sliding-window step (", Step, " bp).",
      call.=FALSE
    )
  }
  Offsets <- seq.int(-Window, Window, by=Step)
  OffsetRows <- seq.int(-Window/Step, Window/Step)
  AllOrigins <- data.table::rbindlist(
    lapply(
      OriginClasses,
      function(origin_class){
        OriginTable <- data.table::copy(Origins[[origin_class]])
        OriginTable[, origin_class := origin_class]
        OriginTable[, origin_id := seq_len(.N)]
        OriginTable[, .(
          origin_class,
          origin_id,
          chrom,
          originCenter
        )]
      }
    ),
    use.names=TRUE
  )

  MedianOrNA <- function(values){
    if(all(is.na(values))){
      NA_real_
    } else {
      stats::median(values, na.rm=TRUE)
    }
  }
  BuildProfilesFromRatio <- function(Ratio, table_label){
    Ratio <- data.table::copy(Ratio)
    Ratio[, ratioRow := seq_len(.N), by=chrom]
    Ratio[, binCenter := chromStart+(chromEnd-chromStart)/2]
    AnchorLookup <- Ratio[, .(
      chrom,
      anchorCenter=binCenter,
      anchorRow=ratioRow
    )]
    Anchors <- AnchorLookup[
      AllOrigins,
      on=.(chrom, anchorCenter=originCenter),
      roll="nearest",
      .(
        origin_class=i.origin_class,
        origin_id=i.origin_id,
        chrom=i.chrom,
        originCenter=i.originCenter,
        anchorRow,
        matchedCenter=x.anchorCenter
      )
    ]
    if(anyNA(Anchors$anchorRow)){
      MissingChromosomes <- unique(Anchors[is.na(anchorRow), chrom])
      stop(
        "Origins refer to chromosome(s) absent from the nuclear ",
        table_label, " ratio table: ",
        paste(MissingChromosomes, collapse=", "),
        call.=FALSE
      )
    }
    Anchors[, anchorDistance := matchedCenter-originCenter]
    Queries <- Anchors[, .(
      offset=Offsets,
      targetRow=anchorRow+OffsetRows
    ), by=.(origin_class, origin_id, chrom)]
    Signal <- Ratio[
      Queries,
      on=.(chrom, ratioRow=targetRow),
      .(
        origin_class=i.origin_class,
        origin_id=i.origin_id,
        offset=i.offset,
        ip.score,
        ratio.ipin,
        ratio.ipnoise,
        ratio.ipin.noise
      )
    ]
    BuildProfile <- function(origin_class){
      TargetClass <- origin_class
      ClassSignal <- Signal[
        base::which(Signal$origin_class == TargetClass)
      ]
      Profile <- ClassSignal[, c(
        list(n_contributing=sum(!is.na(ip.score))),
        lapply(.SD, MedianOrNA)
      ), by=offset, .SDcols=Metrics]
      FullOffsets <- data.table::data.table(offset=Offsets)
      Profile <- Profile[FullOffsets, on=.(offset)]
      data.table::setorder(Profile, offset)
      Profile
    }
    OriginProfiles <- lapply(OriginClasses, BuildProfile)
    names(OriginProfiles) <- OriginClasses
    list(profiles=OriginProfiles, anchors=Anchors, signal=Signal)
  }

  ProfileResults <- lapply(
    names(RatioTables),
    function(table_label){
      BuildProfilesFromRatio(RatioTables[[table_label]], table_label)
    }
  )
  names(ProfileResults) <- names(RatioTables)
  Profiles <- if(StrandMode == "collapsed"){
    ProfileResults$collapsed$profiles
  } else {
    list(
      watson=ProfileResults$watson$profiles,
      crick=ProfileResults$crick$profiles
    )
  }
  AnchorsByTable <- lapply(ProfileResults, `[[`, "anchors")

  ## Page 4 always compares strand-collapsed per-origin distributions. When
  ## pages 2-3 are strand separated, the already-saved collapsed primary ratio
  ## table is read solely for this distribution page; no strand collapsing or
  ## ratio recalculation is performed here.
  BoxplotRatioResult <- if(StrandMode == "collapsed"){
    RatioResults$collapsed
  } else {
    ReadRatioTable(CollapsedRatioFile, "collapsed boxplot")
  }
  if(BoxplotRatioResult$step != Step ||
     !isTRUE(all.equal(BoxplotRatioResult$bin_width, BinWidth))){
    stop(
      "The collapsed boxplot ratio table does not use the same sliding-window step and bin width as the plotted ratio tables.",
      call.=FALSE
    )
  }
  BoxplotProfileResult <- if(StrandMode == "collapsed"){
    ProfileResults$collapsed
  } else {
    BuildProfilesFromRatio(
      BoxplotRatioResult$table,
      "collapsed boxplot"
    )
  }
  MeanOrNA <- function(values){
    if(all(is.na(values))){
      NA_real_
    } else {
      mean(values, na.rm=TRUE)
    }
  }
  OriginBoxScores <- BoxplotProfileResult$signal[, c(
    list(n_bins=sum(!is.na(ip.score))),
    lapply(.SD, MeanOrNA)
  ), by=.(origin_class, origin_id), .SDcols=Metrics]
  OriginBoxDisplayScores <- data.table::melt(
    OriginBoxScores,
    id.vars=c("origin_class", "origin_id", "n_bins"),
    measure.vars=Metrics,
    variable.name="metric",
    value.name="raw_value",
    variable.factor=FALSE
  )
  OriginBoxDisplayScores[, display_value := raw_value]
  if(Log2Profile){
    OriginBoxDisplayScores[
      is.finite(raw_value) & raw_value > 0,
      display_value := log2(raw_value)
    ]
    OriginBoxDisplayScores[
      is.finite(raw_value) & raw_value == 0,
      display_value := 0
    ]
    OriginBoxDisplayScores[
      !is.finite(raw_value) | raw_value < 0,
      display_value := NA_real_
    ]
  }
  OriginBoxDisplayScores[, display_finite := is.finite(display_value)]
  OriginBoxSummaries <- data.table::rbindlist(
    lapply(
      Metrics,
      function(metric){
        TargetMetric <- metric
        data.table::rbindlist(
          lapply(
            OriginClasses,
            function(origin_class){
              TargetClass <- origin_class
              Values <- OriginBoxDisplayScores[
                metric == TargetMetric &
                origin_class == TargetClass &
                display_finite,
                display_value
              ]
              if(length(Values) == 0L){
                return(data.table::data.table(
                  origin_class=TargetClass,
                  metric=TargetMetric,
                  n=0L,
                  whisker_low=NA_real_,
                  q1=NA_real_,
                  median=NA_real_,
                  q3=NA_real_,
                  whisker_high=NA_real_,
                  n_outliers=0L
                ))
              }
              BoxStats <- grDevices::boxplot.stats(
                Values,
                coef=1.5,
                do.conf=FALSE,
                do.out=TRUE
              )
              data.table::data.table(
                origin_class=TargetClass,
                metric=TargetMetric,
                n=length(Values),
                whisker_low=BoxStats$stats[[1]],
                q1=BoxStats$stats[[2]],
                median=BoxStats$stats[[3]],
                q3=BoxStats$stats[[4]],
                whisker_high=BoxStats$stats[[5]],
                n_outliers=length(BoxStats$out)
              )
            }
          ),
          use.names=TRUE
        )
      }
    ),
    use.names=TRUE
  )
  OriginBoxYLimits <- setNames(
    lapply(
      Metrics,
      function(metric){
        TargetMetric <- metric
        Whiskers <- unlist(
          OriginBoxSummaries[metric == TargetMetric, .(
            whisker_low,
            whisker_high
          )],
          use.names=FALSE
        )
        Whiskers <- Whiskers[is.finite(Whiskers)]
        if(length(Whiskers) == 0L){
          stop(
            "No finite Early/Late boxplot values remain for metric: ",
            TargetMetric,
            call.=FALSE
          )
        }
        Baseline <- if(TargetMetric == "ip.score"){
          NA_real_
        } else if(Log2Profile){
          0
        } else {
          1
        }
        Limits <- range(c(Whiskers, Baseline), finite=TRUE)
        Span <- diff(Limits)
        Padding <- if(Span > 0){
          0.08*Span
        } else {
          max(0.1, abs(Limits[[1]])*0.08)
        }
        Lower <- Limits[[1]]-Padding
        if(TargetMetric == "ip.score" && !Log2Profile && Limits[[1]] >= 0){
          Lower <- max(0, Lower)
        }
        c(Lower, Limits[[2]]+Padding)
      }
    ),
    Metrics
  )

  TransformProfileForDisplay <- function(values){
    values <- suppressWarnings(as.numeric(values))
    if(!Log2Profile){
      return(values)
    }
    Transformed <- rep(NA_real_, length(values))
    Finite <- is.finite(values)
    if(StrandMode == "separated"){
      Transformed[Finite] <- log2(1+values[Finite])
    } else {
      Positive <- Finite & values > 0
      Zero <- Finite & values == 0
      Transformed[Positive] <- log2(values[Positive])
      Transformed[Zero] <- 0
    }
    Transformed
  }
  DisplayMetricLabel <- function(metric){
    Label <- MetricYLabels[[metric]]
    if(!Log2Profile){
      return(Label)
    }
    if(StrandMode == "separated"){
      paste0("log2(1 + ", Label, ")")
    } else {
      paste0("log2(", Label, ")")
    }
  }
  SmoothProfile <- function(x, y){
    Smooth <- rep(NA_real_, length(y))
    Good <- which(is.finite(x) & is.finite(y))
    if(length(Good) < 4L || length(unique(x[Good])) < 4L){
      Smooth[Good] <- y[Good]
      return(Smooth)
    }
    Fit <- try(
      stats::smooth.spline(x[Good], y[Good], spar=SmoothingSpar),
      silent=TRUE
    )
    if(inherits(Fit, "try-error")){
      Smooth[Good] <- y[Good]
    } else {
      Smooth[Good] <- Fit$y
    }
    Smooth
  }
  AddDistanceAxis <- function(){
    AxisAt <- seq(-Window, Window, length.out=9)/1000
    AxisLabels <- signif(seq(-Window, Window, length.out=9)/1000, 2)
    AxisLabels[c(2, 4, 6, 8)] <- NA
    graphics::axis(
      1,
      at=AxisAt,
      labels=AxisLabels,
      las=1,
      cex.axis=0.95
    )
  }
  PlotProfile <- function(origin_class, metric){
    PlotHeader <- MetricTitles[[metric]]
    OriginLegend <- if(origin_class == "EarlyOrigin") "E" else "L"
    X <- Offsets/1000
    if(StrandMode == "collapsed"){
      Profile <- Profiles[[origin_class]]
      Y <- SmoothProfile(
        Profile$offset,
        TransformProfileForDisplay(Profile[[metric]])
      )
      FiniteY <- Y[is.finite(Y)]
      if(length(FiniteY) == 0L){
        graphics::plot.new()
        graphics::text(0.5, 0.5, "No finite origin profile", cex=1.1, font=2)
        return(invisible(NULL))
      }
      Baseline <- if(metric == "ip.score"){
        NA_real_
      } else if(Log2Profile){
        0
      } else {
        1
      }
      YRange <- range(c(FiniteY, Baseline), finite=TRUE)
      YPad <- diff(YRange)*0.08
      if(!is.finite(YPad) || YPad == 0){
        YPad <- max(0.1, abs(YRange[[1]])*0.08)
      }
      graphics::plot(
        X,
        Y,
        ylim=YRange+c(-YPad, YPad),
        xlim=c(-Window, Window)/1000,
        main=PlotHeader,
        ylab=DisplayMetricLabel(metric),
        cex.main=1,
        xlab="Distance from OriCenter (Kbp)",
        xaxt="n",
        col=ProfileColor,
        type="l",
        lwd=2,
        bty="n",
        las=1,
        xaxs="i",
        yaxs="i",
        cex.lab=0.95,
        cex.axis=0.90
      )
      if(is.finite(Baseline)){
        graphics::abline(h=Baseline, col="gray72", lwd=0.7, lty=2)
      }
      graphics::abline(v=0, col="gray72", lwd=0.7)
      AddDistanceAxis()
      graphics::legend(
        "topright",
        legend=OriginLegend,
        col=ProfileColor,
        lwd=2,
        bty="n",
        cex=0.85
      )
      return(invisible(NULL))
    }

    WatsonProfile <- Profiles$watson[[origin_class]]
    CrickProfile <- Profiles$crick[[origin_class]]
    Watson <- SmoothProfile(
      WatsonProfile$offset,
      TransformProfileForDisplay(WatsonProfile[[metric]])
    )
    Crick <- -SmoothProfile(
      CrickProfile$offset,
      TransformProfileForDisplay(CrickProfile[[metric]])
    )
    YMax <- max(abs(c(Watson, Crick)), na.rm=TRUE)
    if(!is.finite(YMax) || YMax == 0){
      YMax <- 0.5
    }
    graphics::plot(
      X,
      Watson,
      ylim=c(-YMax, YMax),
      xlim=c(-Window, Window)/1000,
      main=PlotHeader,
      ylab=DisplayMetricLabel(metric),
      cex.main=1,
      xlab="Distance from OriCenter (Kbp)",
      xaxt="n",
      col=WatsonColor,
      type="l",
      lwd=2,
      bty="n",
      las=1,
      xaxs="i",
      yaxs="i",
      cex.lab=0.95,
      cex.axis=0.90
    )
    graphics::lines(X, Crick, col=CrickColor, lwd=2)
    graphics::abline(h=0, col="grey50", lty=2)
    graphics::abline(v=0, col="gray72", lwd=0.7)
    graphics::legend(
      "topright",
      legend=c(
        paste0(OriginLegend, " Watson (+)"),
        paste0(OriginLegend, " Crick (-)")
      ),
      col=c(WatsonColor, CrickColor),
      lwd=2,
      bty="n",
      cex=0.8
    )
    AddDistanceAxis()
  }
  PlotPairwise <- function(metric){
    X <- Offsets/1000
    PlotHeader <- MetricTitles[[metric]]
    if(StrandMode == "collapsed"){
      EarlyProfile <- Profiles$EarlyOrigin
      LateProfile <- Profiles$LateOrigin
      Early <- SmoothProfile(
        EarlyProfile$offset,
        TransformProfileForDisplay(EarlyProfile[[metric]])
      )
      Late <- SmoothProfile(
        LateProfile$offset,
        TransformProfileForDisplay(LateProfile[[metric]])
      )
      Baseline <- if(metric == "ip.score"){
        NA_real_
      } else if(Log2Profile){
        0
      } else {
        1
      }
      YRange <- range(c(Early, Late, Baseline), finite=TRUE)
      YPad <- diff(YRange)*0.08
      if(!is.finite(YPad) || YPad == 0){
        YPad <- max(0.1, abs(YRange[[1]])*0.08)
      }
      graphics::plot(
        X,
        Early,
        ylim=YRange+c(-YPad, YPad),
        xlim=c(-Window, Window)/1000,
        main=PlotHeader,
        ylab=DisplayMetricLabel(metric),
        cex.main=1,
        xlab="Distance from OriCenter (Kbp)",
        xaxt="n",
        col=EarlyColor,
        type="l",
        lwd=2,
        bty="n",
        las=1,
        xaxs="i",
        yaxs="i",
        cex.lab=0.95,
        cex.axis=0.90
      )
      graphics::lines(X, Late, col=LateColor, lwd=2)
      if(is.finite(Baseline)){
        graphics::abline(h=Baseline, col="gray72", lwd=0.7, lty=2)
      }
      graphics::abline(v=0, col="gray72", lwd=0.7)
      graphics::legend(
        "topright",
        legend=c("E", "L"),
        col=c(EarlyColor, LateColor),
        lwd=2,
        bty="n",
        cex=0.8
      )
      AddDistanceAxis()
      return(invisible(NULL))
    }

    EarlyWatson <- Profiles$watson$EarlyOrigin
    EarlyCrick <- Profiles$crick$EarlyOrigin
    LateWatson <- Profiles$watson$LateOrigin
    LateCrick <- Profiles$crick$LateOrigin
    EW <- SmoothProfile(
      EarlyWatson$offset,
      TransformProfileForDisplay(EarlyWatson[[metric]])
    )
    EC <- -SmoothProfile(
      EarlyCrick$offset,
      TransformProfileForDisplay(EarlyCrick[[metric]])
    )
    LW <- SmoothProfile(
      LateWatson$offset,
      TransformProfileForDisplay(LateWatson[[metric]])
    )
    LC <- -SmoothProfile(
      LateCrick$offset,
      TransformProfileForDisplay(LateCrick[[metric]])
    )
    YMax <- max(abs(c(EW, EC, LW, LC)), na.rm=TRUE)
    if(!is.finite(YMax) || YMax == 0){
      YMax <- 0.5
    }
    graphics::plot(
      X,
      EW,
      ylim=c(-YMax, YMax),
      xlim=c(-Window, Window)/1000,
      main=PlotHeader,
      ylab=DisplayMetricLabel(metric),
      cex.main=1,
      xlab="Distance from OriCenter (Kbp)",
      xaxt="n",
      col=WatsonColor,
      type="l",
      lwd=2,
      bty="n",
      las=1,
      xaxs="i",
      yaxs="i",
      cex.lab=0.95,
      cex.axis=0.90
    )
    graphics::lines(X, EC, col=CrickColor, lwd=2)
    graphics::lines(X, LW, col=WatsonColor, lwd=2, lty=2)
    graphics::lines(X, LC, col=CrickColor, lwd=2, lty=2)
    graphics::abline(h=0, col="grey50", lty=3)
    graphics::abline(v=0, col="gray72", lwd=0.7)
    graphics::legend(
      "topright",
      legend=c("E Watson", "E Crick", "L Watson", "L Crick"),
      col=c(WatsonColor, CrickColor, WatsonColor, CrickColor),
      lty=c(1, 1, 2, 2),
      lwd=2,
      bty="n",
      cex=0.7
    )
    AddDistanceAxis()
  }
  PlotEarlyLateBox <- function(metric){
    TargetMetric <- metric
    Values <- lapply(
      OriginClasses,
      function(origin_class){
        TargetClass <- origin_class
        OriginBoxDisplayScores[
          metric == TargetMetric &
          origin_class == TargetClass &
          display_finite,
          display_value
        ]
      }
    )
    names(Values) <- c("E", "L")
    graphics::boxplot(
      Values,
      outline=FALSE,
      ylim=OriginBoxYLimits[[TargetMetric]],
      main=MetricTitles[[TargetMetric]],
      ylab=if(Log2Profile){
        paste0("log2(", MetricYLabels[[TargetMetric]], ")")
      } else {
        MetricYLabels[[TargetMetric]]
      },
      names=c(
        paste0("E\n(n=", length(Values$E), ")"),
        paste0("L\n(n=", length(Values$L), ")")
      ),
      col=c(
        grDevices::adjustcolor(EarlyColor, alpha.f=0.75),
        grDevices::adjustcolor(LateColor, alpha.f=0.75)
      ),
      border=c(EarlyColor, LateColor),
      boxwex=0.52,
      staplewex=0.65,
      medlwd=1.8,
      whisklwd=1.1,
      staplelwd=1.1,
      las=1,
      cex.main=1,
      cex.lab=0.95,
      cex.axis=0.90,
      cex.names=0.84,
      bty="n"
    )
    Baseline <- if(TargetMetric == "ip.score"){
      NA_real_
    } else if(Log2Profile){
      0
    } else {
      1
    }
    if(is.finite(Baseline)){
      graphics::abline(h=Baseline, col="gray72", lwd=0.7, lty=2)
    }
    graphics::legend(
      "topright",
      legend=c("Early", "Late"),
      fill=c(EarlyColor, LateColor),
      border=c(EarlyColor, LateColor),
      bty="n",
      cex=0.75
    )
    graphics::box(col="gray45", lwd=0.75)
  }

  OutputFile <- file.path(
    OutputDir,
    paste0(
      SampleName, "_", Assay, "_early_late_", Alignment, "_", StrandMode,
      "_", if(Log2Profile) "log2" else "linear", ".pdf"
    )
  )
  grDevices::pdf(
    OutputFile,
    width=PdfWidth,
    height=PdfHeight,
    useDingbats=FALSE
  )
  PdfDevice <- grDevices::dev.cur()
  on.exit({
    OpenDevices <- grDevices::dev.list()
    if(!is.null(OpenDevices) && PdfDevice %in% OpenDevices){
      grDevices::dev.off(which=PdfDevice)
    }
  }, add=TRUE)

  ## Page 1: original title and two origin-count circles.
  graphics::par(oma=c(2, 1, 1, 1), mar=c(0, 0, 0, 0))
  PlotMatrix <- matrix(
    c(
      0,0,0,0,0,0,0,0,
      1,1,1,1,1,1,1,1,
      0,2,2,2,3,3,3,0,
      0,4,4,4,5,5,5,0,
      0,0,0,0,0,0,0,0
    ),
    nrow=5,
    ncol=8,
    byrow=TRUE
  )
  graphics::layout(
    PlotMatrix,
    widths=rep(1, 8),
    heights=c(0.2, 0.7, 0.3, 1.15, 0.25),
    respect=FALSE
  )
  graphics::plot.new()
  graphics::text(
    0.5, 0.62,
    labels=paste0("Experiment: ", SampleName),
    cex=2.2,
    font=2,
    family="serif"
  )
  graphics::text(
    0.5, 0.30,
    labels=paste0(
      "Early and late origin ", Assay,
      " signals centered on origin midpoint"
    ),
    cex=1.45,
    font=3,
    family="serif"
  )
  graphics::text(
    0.5, 0.08,
    labels=paste0(Alignment, " | ", StrandMode, " | ", TransformLabel,
                  " | ", date()),
    cex=1.15,
    font=3,
    family="serif",
    col="gray35"
  )
  for(origin_class in OriginClasses){
    graphics::plot(
      NA,
      xlim=c(0, 1),
      ylim=c(0, 1),
      axes=FALSE,
      xlab="",
      ylab="",
      bty="n"
    )
    graphics::text(
      0.5, 0.35,
      labels=PrettyOriginClass(origin_class),
      cex=1.35,
      font=2,
      family="serif"
    )
  }
  graphics::par(mar=c(1, 1, 2, 1), pty="s")
  for(origin_class in OriginClasses){
    graphics::plot(
      NA,
      xlim=c(0, 1),
      ylim=c(0, 1),
      axes=FALSE,
      xlab="",
      ylab="",
      bty="n",
      xaxs="i",
      yaxs="i"
    )
    graphics::symbols(
      0.5, 0.5,
      circles=0.34,
      inches=FALSE,
      add=TRUE,
      fg=grDevices::adjustcolor("cornflowerblue", alpha.f=0.82),
      bg=grDevices::adjustcolor("cornflowerblue", alpha.f=0.45),
      lwd=2
    )
    graphics::text(
      0.5, 0.5,
      labels=format(OriginCounts[[origin_class]], big.mark=","),
      cex=1.6,
      font=3,
      family="serif"
    )
  }
  graphics::mtext(
    "Page 1 of 4",
    side=1,
    outer=TRUE,
    line=0,
    font=3,
    cex=1
  )

  ## Page 2: two origin rows and four final-metric columns.
  graphics::layout(matrix(seq_len(8L), nrow=2, ncol=4, byrow=TRUE))
  graphics::par(oma=c(3, 1, 3, 1), mar=c(4, 4, 4, 2)+0.1)
  for(origin_class in OriginClasses){
    for(metric in Metrics){
      PlotProfile(origin_class, metric)
    }
  }
  graphics::mtext(
    "Read enrichments at early and late origins",
    side=3,
    line=0,
    outer=TRUE,
    font=2,
    cex=2
  )
  graphics::mtext(
    "Page 2 of 4",
    side=1,
    line=0,
    outer=TRUE,
    font=3,
    cex=1
  )

  ## Page 3: original 3 x 4 layout with four pairwise panels in row 1.
  graphics::layout(matrix(seq_len(12L), nrow=3, ncol=4, byrow=TRUE))
  graphics::par(oma=c(3, 1, 3, 1), mar=c(4, 4, 4, 2)+0.1)
  for(metric in Metrics){
    PlotPairwise(metric)
  }
  for(index in seq_len(8L)){
    graphics::plot.new()
  }
  graphics::mtext(
    "Pairwise comparative enrichment at early and late origins",
    side=3,
    line=0,
    outer=TRUE,
    font=2,
    cex=2
  )
  graphics::mtext(
    "Page 3 of 4",
    side=1,
    line=0,
    outer=TRUE,
    font=3,
    cex=1
  )

  ## Page 4: collapsed per-origin distributions, two boxes per metric panel.
  graphics::layout(matrix(seq_len(12L), nrow=3, ncol=4, byrow=TRUE))
  graphics::par(oma=c(3, 1, 3, 1), mar=c(4, 4, 4, 2)+0.1)
  for(metric in Metrics){
    PlotEarlyLateBox(metric)
  }
  for(index in seq_len(8L)){
    graphics::plot.new()
  }
  graphics::mtext(
    "Strand-collapsed Early-versus-Late enrichment distributions",
    side=3,
    line=0,
    outer=TRUE,
    font=2,
    cex=2
  )
  graphics::mtext(
    paste0(
      "Arithmetic mean within +/-", format(Window, big.mark=","),
      " bp; outlier points hidden"
    ),
    side=1,
    line=0.85,
    outer=TRUE,
    cex=0.78,
    col="gray40"
  )
  graphics::mtext(
    "Page 4 of 4",
    side=1,
    line=0,
    outer=TRUE,
    font=3,
    cex=1
  )

  grDevices::dev.off(which=PdfDevice)
  message("Early/Late enrichment report saved: ", OutputFile)

  OriginAnchorDistance <- lapply(
    AnchorsByTable,
    function(anchors){
      setNames(
        lapply(
          OriginClasses,
          function(origin_class){
            TargetClass <- origin_class
            summary(
              anchors$anchorDistance[
                anchors$origin_class == TargetClass
              ]
            )
          }
        ),
        OriginClasses
      )
    }
  )
  if(StrandMode == "collapsed"){
    OriginAnchorDistance <- OriginAnchorDistance$collapsed
  }
  invisible(list(
    pdf=OutputFile,
    sample_dir=SampleDir,
    sample_name=SampleName,
    assay=Assay,
    alignment=Alignment,
    strand_mode=StrandMode,
    log2_profile=Log2Profile,
    display_transform=TransformLabel,
    window=Window,
    step=Step,
    bin_width=BinWidth,
    ratio_steps=RatioSteps,
    bin_widths=RatioBinWidths,
    ratio_chrM_rows_omitted=RatioChrMOmitted,
    origin_anchor_distance=OriginAnchorDistance,
    ratio_file=if(StrandMode == "collapsed") unname(RatioFiles[[1]]) else NULL,
    ratio_files=RatioFiles,
    origin_files=OriginFiles,
    origin_counts=OriginCounts,
    origin_chrM_records_omitted=OriginChrMOmitted,
    chromosomes=NuclearChromosomes,
    chrM_excluded=TRUE,
    origin_centering="BED interval midpoint",
    profiles=Profiles,
    boxplot_ratio_file=CollapsedRatioFile,
    boxplot_ratio_chrM_rows_omitted=BoxplotRatioResult$chrM_omitted,
    boxplot_scores=OriginBoxScores,
    boxplot_display_scores=OriginBoxDisplayScores,
    boxplot_summaries=OriginBoxSummaries,
    boxplot_y_limits=OriginBoxYLimits,
    boxplot_statistic="arithmetic mean of final saved collapsed metric values within origin-midpoint window",
    boxplot_outlier_points_plotted=FALSE,
    metrics=Metrics,
    profile_statistic="median",
    edge_handling="missing chromosome-edge bins excluded; no zero padding",
    page_count=4L,
    primary_ratio_output_only=TRUE,
    annotation_source="project-local processed Early/Late origin BED files",
    plotter_operations=c(
      bam_reading=FALSE,
      coverage_reading=FALSE,
      simulation=FALSE,
      noise_estimation=FALSE,
      signal_filtering=FALSE,
      ratio_recalculation=FALSE,
      strand_collapsing=FALSE,
      peak_calling=FALSE,
      pvalue_thresholding=FALSE
    ),
    display_operations=c(
      origin_midpoint_median=TRUE,
      spline_smoothing=TRUE,
      shared_pairwise_scale=TRUE,
      ratio_neutral_reference_line=TRUE,
      profile_rebasing=FALSE,
      raw_coverage_forced_to_zero=FALSE,
      watson_positive=StrandMode == "separated",
      crick_negative_mirroring=StrandMode == "separated",
      log_transformation=Log2Profile,
      separated_log1p=StrandMode == "separated" && Log2Profile,
      collapsed_early_late_boxplots=TRUE,
      boxplot_outlier_points_hidden=TRUE
    )
  ))
}

## Direct ChIP-BrDU genomic-element enrichment comparison. This function
## serves the specific paired-assay use case and is intentionally separate from
## ChIP_BrDU_Early_Late_Enrichment_Plotter, which remains the focused
## single-assay report. One explicitly supplied ChIP sample and one explicitly
## supplied BrDU sample are compared per call; there is no directory-wide
## sample discovery, genotype assumption, or fixed pair count.
##
## The function reads only selected processed project-local genomic-element BED
## files and/or one sample's final saved peak BEDs plus final strand-collapsed
## ratio tables written by the current primary analysis. PeakSource="ChIP"
## (default) or "BrDU" chooses the one common peak list used for both assays;
## this prevents invalid comparisons between different loci. It never reads
## BAM/coverage files, simulates positions, estimates noise, filters signal,
## recalculates ratios, calls/re-filters peaks, or collapses strands. chrM,
## ORFs, and rDNA are excluded. Missing chromosome-edge bins remain unavailable without
## interpolation or zero padding. Median element-centred profiles are spline
## smoothed only for display. Log2Profile=FALSE preserves the original
## untransformed presentation. Log2Profile=TRUE uses log2(1+x) for coverage and
## log2(x) for positive ratio values; non-positive ratios remain unavailable.
##
## Each selected genomic element occupies one row and each selected final metric
## occupies one column, with at most three element rows per page. ChIP is drawn
## as a solid line against the left y-axis and BrDU as a dotted line against the
## right y-axis. In the untransformed display, ratio baselines are aligned at 1
## between axes and coverage is aligned at 0; every log2 baseline is aligned at
## 0. Automatic limits are shared by metric across every selected element and
## page. Optional y_val_chip and y_val_brdu values set assay-specific upper
## limits and may be a scalar, an unnamed vector in selected-metric order, or a
## partially/fully named vector keyed by metric.
##
## Example:
## ChIP_BrDU_Enrichment_Comparison_Plotter(
##   ChIPSampleDir="/path/to/sample-ChIP",
##   BrDUSampleDir="/path/to/sample-BrDU",
##   Alignment="generic",
##   PeakSource="ChIP",
##   Elements=c("OriginPeaks", "EarlyOriginPeaks", "LateOriginPeaks"),
##   Metric="all",
##   Window=3000,
##   Log2Profile=FALSE
## )
ChIP_BrDU_Enrichment_Comparison_Plotter <- function(
    ChIPSampleDir,
    BrDUSampleDir,
    Alignment=c("generic", "malign"),
    Elements=c("EarlyOrigin", "LateOrigin"),
    Metric="all",
    Window=3000,
    Log2Profile=FALSE,
    y_val_chip=NULL,
    y_val_brdu=NULL,
    OutputDir=NULL,
    PeakSource=c("ChIP", "BrDU")){

  AllMetrics <- c(
    "ip.score", "ratio.ipin", "ratio.ipnoise", "ratio.ipin.noise"
  )
  MetricTitles <- c(
    ip.score="Coverage",
    ratio.ipin="Enrichment over input",
    ratio.ipnoise="Enrichment over noise",
    ratio.ipin.noise="Clean enrichment"
  )
  RawNeutralBaselines <- c(
    ip.score=0,
    ratio.ipin=1,
    ratio.ipnoise=1,
    ratio.ipin.noise=1
  )
  CuratedElements <- c(
    "ARS", "EarlyOrigin", "LateOrigin",
    "TER", "Ty", "tRNA",
    "Centromere", "Convergent", "Divergent",
    "CTrans", "WTrans"
  )
  PeakElements <- c(
    "GenomewidePeaks", "NonOriginPeaks", "OriginPeaks",
    "EarlyOriginPeaks", "LateOriginPeaks"
  )
  PeakClassNames <- c(
    GenomewidePeaks="Genomewide",
    NonOriginPeaks="NonOrigin",
    OriginPeaks="Origin",
    EarlyOriginPeaks="EarlyOrigin",
    LateOriginPeaks="LateOrigin"
  )
  ValidElements <- c(CuratedElements, PeakElements)
  ElementPathKeys <- c(
    ARS="ars",
    EarlyOrigin="early_origins",
    LateOrigin="late_origins",
    TER="termination_regions",
    Ty="ty_elements",
    tRNA="trnas",
    Centromere="centromeres",
    Convergent="convergent_regions",
    Divergent="divergent_regions",
    CTrans="crick_transcribed_regions",
    WTrans="watson_transcribed_regions"
  )
  NuclearChromosomes <- paste0("chr", as.character(as.roman(seq_len(16L))))
  ChIPColor <- "darkorchid4"
  BrDUColor <- "darkorange3"
  BaselineColor <- "gray65"
  SmoothingSpar <- 0.5
  MaxRowsPerPage <- 3L

  Alignment <- match.arg(Alignment)
  PeakSource <- match.arg(PeakSource)
  if(!is.logical(Log2Profile) || length(Log2Profile) != 1L ||
     is.na(Log2Profile)){
    stop("Log2Profile must be TRUE or FALSE.", call.=FALSE)
  }
  NeutralBaselines <- if(Log2Profile){
    setNames(rep(0, length(AllMetrics)), AllMetrics)
  } else {
    RawNeutralBaselines
  }
  ScaleTag <- if(Log2Profile) "log2" else "linear"
  ScaleLabel <- if(Log2Profile){
    "log2 display"
  } else {
    "untransformed display"
  }

  ValidateSampleDir <- function(path, label){
    if(length(path) != 1L || !is.character(path) || is.na(path) ||
       !nzchar(path)){
      stop(label, " must be one existing sample directory.", call.=FALSE)
    }
    if(!dir.exists(path)){
      stop(label, " does not exist: ", path, call.=FALSE)
    }
    normalizePath(path, winslash="/", mustWork=TRUE)
  }
  ChIPSampleDir <- ValidateSampleDir(ChIPSampleDir, "ChIPSampleDir")
  BrDUSampleDir <- ValidateSampleDir(BrDUSampleDir, "BrDUSampleDir")
  ChIPSampleName <- basename(ChIPSampleDir)
  BrDUSampleName <- basename(BrDUSampleDir)

  if(!is.character(Elements) || length(Elements) == 0L ||
     anyNA(Elements) || any(!nzchar(Elements))){
    stop("Elements must contain at least one supported element class.", call.=FALSE)
  }
  if(anyDuplicated(Elements)){
    stop("Elements must not contain duplicated element classes.", call.=FALSE)
  }
  InvalidElements <- setdiff(Elements, ValidElements)
  if(length(InvalidElements) > 0L){
    stop(
      "Unsupported Elements value(s): ",
      paste(InvalidElements, collapse=", "),
      ". Supported values are: ",
      paste(ValidElements, collapse=", "),
      call.=FALSE
    )
  }
  SelectedElements <- Elements

  if(!is.character(Metric) || length(Metric) == 0L ||
     anyNA(Metric) || any(!nzchar(Metric))){
    stop(
      "Metric must be \"all\" or one or more final ratio-table metric names.",
      call.=FALSE
    )
  }
  if("all" %in% Metric && length(Metric) > 1L){
    stop("Metric=\"all\" cannot be combined with named metrics.", call.=FALSE)
  }
  PlotMetrics <- if(identical(Metric, "all")) AllMetrics else Metric
  InvalidMetrics <- setdiff(PlotMetrics, AllMetrics)
  if(length(InvalidMetrics) > 0L){
    stop(
      "Unsupported Metric value(s): ",
      paste(InvalidMetrics, collapse=", "),
      ". Supported values are: all, ",
      paste(AllMetrics, collapse=", "),
      call.=FALSE
    )
  }
  if(anyDuplicated(PlotMetrics)){
    stop("Metric must not contain duplicated metric names.", call.=FALSE)
  }

  if(length(Window) != 1L || !is.numeric(Window) || !is.finite(Window) ||
     Window <= 0 || abs(Window-round(Window)) > sqrt(.Machine$double.eps)){
    stop("Window must be one positive whole number of base pairs.", call.=FALSE)
  }
  Window <- as.integer(round(Window))

  ResolveYValues <- function(values, label){
    Resolved <- setNames(rep(NA_real_, length(PlotMetrics)), PlotMetrics)
    if(is.null(values)){
      return(Resolved)
    }
    if(!is.numeric(values) || length(values) == 0L ||
       anyNA(values) || any(!is.finite(values))){
      stop(
        label,
        " must be NULL or finite numeric upper limit(s).",
        call.=FALSE
      )
    }
    ValueNames <- names(values)
    HasNames <- !is.null(ValueNames) && any(nzchar(ValueNames))
    if(HasNames){
      if(any(!nzchar(ValueNames))){
        stop(label, " cannot mix named and unnamed values.", call.=FALSE)
      }
      if(anyDuplicated(ValueNames)){
        stop(label, " contains duplicated metric names.", call.=FALSE)
      }
      InvalidNames <- setdiff(ValueNames, PlotMetrics)
      if(length(InvalidNames) > 0L){
        stop(
          label, " contains metric name(s) not selected by Metric: ",
          paste(InvalidNames, collapse=", "),
          call.=FALSE
        )
      }
      Resolved[ValueNames] <- as.numeric(values)
    } else if(length(values) == 1L){
      Resolved[] <- as.numeric(values)
    } else if(length(values) == length(PlotMetrics)){
      Resolved[] <- as.numeric(values)
    } else {
      stop(
        label,
        " must be one value, one value per selected metric, or a named vector.",
        call.=FALSE
      )
    }
    Provided <- is.finite(Resolved)
    InvalidUpper <- Provided &
      Resolved <= NeutralBaselines[names(Resolved)]
    if(any(InvalidUpper)){
      stop(
        label,
        " must be greater than the neutral baseline for: ",
        paste(names(Resolved)[InvalidUpper], collapse=", "),
        call.=FALSE
      )
    }
    Resolved
  }
  ChIPYValues <- ResolveYValues(y_val_chip, "y_val_chip")
  BrDUYValues <- ResolveYValues(y_val_brdu, "y_val_brdu")

  if(is.null(OutputDir)){
    ParentDirs <- unique(dirname(c(ChIPSampleDir, BrDUSampleDir)))
    OutputDir <- if(length(ParentDirs) == 1L){
      ParentDirs[[1]]
    } else {
      ChIPSampleDir
    }
  }
  if(length(OutputDir) != 1L || !is.character(OutputDir) ||
     is.na(OutputDir) || !nzchar(OutputDir)){
    stop("OutputDir must be NULL or one directory path.", call.=FALSE)
  }
  if(!dir.exists(OutputDir)){
    dir.create(OutputDir, recursive=TRUE, showWarnings=FALSE)
  }
  if(!dir.exists(OutputDir)){
    stop("Could not create OutputDir: ", OutputDir, call.=FALSE)
  }
  OutputDir <- normalizePath(OutputDir, winslash="/", mustWork=TRUE)

  if(!requireNamespace("data.table", quietly=TRUE)){
    stop(
      "The data.table package is required to read and summarize paired ChIP-BrDU profiles efficiently.",
      call.=FALSE
    )
  }

  ProjectPaths <- ChIP_BrDU_Project_Paths(check=TRUE)
  PeakSampleDir <- if(PeakSource == "ChIP") ChIPSampleDir else BrDUSampleDir
  PeakSampleName <- if(PeakSource == "ChIP") ChIPSampleName else BrDUSampleName
  PeakDir <- file.path(
    PeakSampleDir,
    if(Alignment == "generic") "Peaks" else "Peaks_ma"
  )
  ElementFiles <- setNames(
    vapply(
      SelectedElements,
      function(element_class){
        if(element_class %in% PeakElements){
          file.path(
            PeakDir,
            paste0(
              PeakSampleName, "_", PeakClassNames[[element_class]], "_Peaks.bed"
            )
          )
        } else {
          ProjectPaths$elements[[ElementPathKeys[[element_class]]]]
        }
      },
      character(1)
    ),
    SelectedElements
  )
  RatioFolder <- if(Alignment == "generic") "Ratios" else "Ratios_ma"
  RatioFiles <- c(
    ChIP=file.path(
      ChIPSampleDir,
      RatioFolder,
      paste0(ChIPSampleName, "_ChIP_collapsed.bed")
    ),
    BrDU=file.path(
      BrDUSampleDir,
      RatioFolder,
      paste0(BrDUSampleName, "_BrDU_collapsed.bed")
    )
  )
  RequiredFiles <- c(ElementFiles, RatioFiles)
  MissingFiles <- RequiredFiles[!file.exists(RequiredFiles)]
  if(length(MissingFiles) > 0L){
    stop(
      "Required support or primary-analysis output file(s) are missing:\n",
      paste(MissingFiles, collapse="\n"),
      call.=FALSE
    )
  }

  PrettyElementClass <- function(element_class){
    switch(
      element_class,
      ARS="ARS",
      EarlyOrigin="Early-firing origins",
      LateOrigin="Late-firing origins",
      TER="Termination regions",
      Ty="Ty elements",
      tRNA="tRNAs",
      Centromere="Centromeres",
      Convergent="Convergent regions",
      Divergent="Divergent regions",
      CTrans="Crick-transcribed regions",
      WTrans="Watson-transcribed regions",
      GenomewidePeaks="Genome-wide peaks",
      NonOriginPeaks="Non-origin peaks",
      OriginPeaks="Origin-associated peaks",
      EarlyOriginPeaks="Early-origin peaks",
      LateOriginPeaks="Late-origin peaks",
      element_class
    )
  }
  ReadElementFile <- function(file, element_class){
    ElementTable <- data.table::fread(
      file,
      header=TRUE,
      sep="\t",
      showProgress=FALSE,
      data.table=TRUE
    )
    IsPeakClass <- element_class %in% PeakElements
    RequiredColumns <- if(IsPeakClass){
      c("chrom", "peakStart", "peakEnd", "peakSummit")
    } else {
      c("chrom", "chromStart", "chromEnd", "name", "score", "strand", "type")
    }
    MissingColumns <- setdiff(RequiredColumns, names(ElementTable))
    if(length(MissingColumns) > 0L){
      stop(
        PrettyElementClass(element_class),
        " annotation is missing required column(s): ",
        paste(MissingColumns, collapse=", "), "\n", file,
        call.=FALSE
      )
    }
    if(IsPeakClass){
      PeakNames <- if("oriName" %in% names(ElementTable)){
        as.character(ElementTable$oriName)
      } else {
        rep(NA_character_, nrow(ElementTable))
      }
      MissingNames <- is.na(PeakNames) | !nzchar(PeakNames)
      PeakNames[MissingNames] <- paste0(
        PeakClassNames[[element_class]], "Peak_", which(MissingNames)
      )
      ElementTable <- ElementTable[, .(
        chrom=as.character(chrom),
        chromStart=as.numeric(peakStart),
        chromEnd=as.numeric(peakEnd),
        element_name=PeakNames,
        strand=".",
        type=paste0(PeakClassNames[[element_class]], "Peak"),
        elementCenter=as.numeric(peakSummit)
      )]
    } else {
      ElementTable <- ElementTable[, .(
        chrom=as.character(chrom),
        chromStart=as.numeric(chromStart),
        chromEnd=as.numeric(chromEnd),
        element_name=as.character(name),
        strand=as.character(strand),
        type=as.character(type),
        elementCenter=(as.numeric(chromStart)+as.numeric(chromEnd))/2
      )]
    }
    ChrMOmitted <- sum(ElementTable$chrom == "chrM", na.rm=TRUE)
    ElementTable <- ElementTable[chrom != "chrM"]
    if(nrow(ElementTable) == 0L){
      stop(
        "No nuclear records remain in the ",
        PrettyElementClass(element_class),
        " annotation after excluding chrM: ", file,
        call.=FALSE
      )
    }
    CoordinateValues <- unlist(
      ElementTable[, .(chromStart, chromEnd)],
      use.names=FALSE
    )
    if(any(!nzchar(ElementTable$chrom)) ||
       any(!is.finite(CoordinateValues)) ||
       any(ElementTable$chromStart < 0) ||
       any(ElementTable$chromEnd <= ElementTable$chromStart) ||
       any(!is.finite(ElementTable$elementCenter)) ||
       any(ElementTable$elementCenter < ElementTable$chromStart) ||
       any(ElementTable$elementCenter > ElementTable$chromEnd)){
      stop("Invalid nuclear element coordinates in: ", file, call.=FALSE)
    }
    UnexpectedChromosomes <- setdiff(
      unique(ElementTable$chrom),
      NuclearChromosomes
    )
    if(length(UnexpectedChromosomes) > 0L){
      stop(
        "Unexpected chromosome name(s) in ", file, ": ",
        paste(UnexpectedChromosomes, collapse=", "),
        call.=FALSE
      )
    }
    ElementKey <- paste(
      ElementTable$chrom,
      ElementTable$chromStart,
      ElementTable$chromEnd,
      ElementTable$elementCenter,
      sep="\r"
    )
    if(anyDuplicated(ElementKey)){
      stop(
        "Duplicated nuclear coordinates were found in the ",
        PrettyElementClass(element_class), " annotation: ", file,
        call.=FALSE
      )
    }
    ElementTable[, chromosome_order := match(chrom, NuclearChromosomes)]
    data.table::setorder(
      ElementTable,
      chromosome_order,
      elementCenter,
      chromStart,
      chromEnd
    )
    ElementTable[, chromosome_order := NULL]
    list(table=ElementTable, chrM_omitted=ChrMOmitted)
  }

  ElementResults <- lapply(
    SelectedElements,
    function(element_class){
      ReadElementFile(ElementFiles[[element_class]], element_class)
    }
  )
  names(ElementResults) <- SelectedElements
  ElementTables <- lapply(
    ElementResults,
    function(result) result$table
  )
  ElementCounts <- vapply(ElementTables, nrow, integer(1))
  ElementChrMOmitted <- vapply(
    ElementResults,
    function(result) result$chrM_omitted,
    integer(1)
  )

  RatioColumns <- c("chrom", "chromStart", "chromEnd", PlotMetrics)
  ReadRatioTable <- function(file, assay_label){
    RatioHeader <- names(data.table::fread(
      file,
      header=TRUE,
      sep="\t",
      nrows=0L,
      showProgress=FALSE,
      data.table=TRUE
    ))
    MissingColumns <- setdiff(RatioColumns, RatioHeader)
    if(length(MissingColumns) > 0L){
      stop(
        assay_label, " ratio table is missing required column(s): ",
        paste(MissingColumns, collapse=", "), "\n", file,
        call.=FALSE
      )
    }
    Ratio <- data.table::fread(
      file,
      header=TRUE,
      sep="\t",
      select=RatioColumns,
      showProgress=FALSE,
      data.table=TRUE
    )
    if(nrow(Ratio) == 0L){
      stop(assay_label, " ratio table is empty: ", file, call.=FALSE)
    }
    Ratio[, chrom := as.character(chrom)]
    for(column in setdiff(RatioColumns, "chrom")){
      data.table::set(
        Ratio,
        j=column,
        value=suppressWarnings(as.numeric(Ratio[[column]]))
      )
    }
    if(any(!nzchar(Ratio$chrom)) ||
       any(!is.finite(Ratio$chromStart)) ||
       any(!is.finite(Ratio$chromEnd))){
      stop(
        assay_label,
        " ratio table contains invalid genomic coordinates: ",
        file,
        call.=FALSE
      )
    }
    ChrMOmitted <- sum(Ratio$chrom == "chrM", na.rm=TRUE)
    Ratio <- Ratio[chrom != "chrM"]
    if(nrow(Ratio) == 0L){
      stop(
        assay_label,
        " ratio table has no nuclear rows after excluding chrM: ",
        file,
        call.=FALSE
      )
    }
    UnexpectedChromosomes <- setdiff(unique(Ratio$chrom), NuclearChromosomes)
    if(length(UnexpectedChromosomes) > 0L){
      stop(
        assay_label, " ratio table contains unexpected chromosome name(s): ",
        paste(UnexpectedChromosomes, collapse=", "),
        call.=FALSE
      )
    }
    MetricValues <- unlist(Ratio[, ..PlotMetrics], use.names=FALSE)
    if(any(!is.finite(MetricValues))){
      stop(
        assay_label,
        " ratio table contains a non-finite nuclear metric value: ",
        file,
        call.=FALSE
      )
    }
    BinWidths <- Ratio$chromEnd-Ratio$chromStart
    if(any(!is.finite(BinWidths)) || any(BinWidths <= 0)){
      stop(
        assay_label,
        " ratio table contains a non-positive genomic-window width: ",
        file,
        call.=FALSE
      )
    }
    BinWidthCounts <- data.table::data.table(bin_width=BinWidths)[
      , .N, by=bin_width
    ][order(-N, bin_width)]
    BinWidth <- as.numeric(BinWidthCounts$bin_width[[1]])
    if(anyDuplicated(Ratio[, .(chrom, chromStart)])){
      stop(
        assay_label,
        " ratio table contains duplicated nuclear chrom/chromStart coordinates: ",
        file,
        call.=FALSE
      )
    }
    Ratio[, chromosome_order := match(chrom, NuclearChromosomes)]
    data.table::setorder(Ratio, chromosome_order, chromStart, chromEnd)
    Ratio[, chromosome_order := NULL]
    StepCounts <- Ratio[, .(
      delta=diff(sort(unique(chromStart)))
    ), by=chrom][delta > 0, .N, by=delta][order(-N, delta)]
    if(nrow(StepCounts) == 0L ||
       !is.finite(StepCounts$delta[[1]]) ||
       StepCounts$delta[[1]] <= 0){
      stop(
        "Could not infer a positive sliding-window step from the ",
        assay_label, " ratio table: ", file,
        call.=FALSE
      )
    }
    Step <- as.numeric(StepCounts$delta[[1]])
    if(abs(Step-round(Step)) > sqrt(.Machine$double.eps)){
      stop(
        "The inferred sliding-window step in the ",
        assay_label,
        " ratio table is not a whole number of base pairs.",
        call.=FALSE
      )
    }
    list(
      table=Ratio,
      step=as.integer(round(Step)),
      bin_width=BinWidth,
      chrM_omitted=ChrMOmitted
    )
  }

  RatioResults <- list(
    ChIP=ReadRatioTable(RatioFiles[["ChIP"]], "ChIP"),
    BrDU=ReadRatioTable(RatioFiles[["BrDU"]], "BrDU")
  )
  RatioTables <- lapply(
    RatioResults,
    function(result) result$table
  )
  RatioSteps <- vapply(
    RatioResults,
    function(result) result$step,
    integer(1)
  )
  RatioBinWidths <- vapply(
    RatioResults,
    function(result) result$bin_width,
    numeric(1)
  )
  RatioChrMOmitted <- vapply(
    RatioResults,
    function(result) result$chrM_omitted,
    integer(1)
  )
  if(length(unique(RatioSteps)) != 1L){
    stop(
      "ChIP and BrDU ratio tables do not use the same sliding-window step.",
      call.=FALSE
    )
  }
  CoordinatesMatch <-
    nrow(RatioTables$ChIP) == nrow(RatioTables$BrDU) &&
    identical(RatioTables$ChIP$chrom, RatioTables$BrDU$chrom) &&
    identical(RatioTables$ChIP$chromStart, RatioTables$BrDU$chromStart) &&
    identical(RatioTables$ChIP$chromEnd, RatioTables$BrDU$chromEnd)
  if(!CoordinatesMatch){
    stop(
      "ChIP and BrDU nuclear ratio-table coordinates do not match exactly.",
      call.=FALSE
    )
  }
  Step <- unname(RatioSteps[[1]])
  if(abs(Window/Step-round(Window/Step)) > sqrt(.Machine$double.eps)){
    stop(
      "Window (", Window, " bp) must be an exact multiple of the inferred ",
      "sliding-window step (", Step, " bp).",
      call.=FALSE
    )
  }
  Offsets <- seq.int(-Window, Window, by=Step)
  OffsetRows <- seq.int(-Window/Step, Window/Step)

  AllElements <- data.table::rbindlist(
    lapply(
      SelectedElements,
      function(element_class){
        TargetClass <- element_class
        ElementTable <- data.table::copy(ElementTables[[TargetClass]])
        ElementTable[, element_class := TargetClass]
        ElementTable[, element_id := seq_len(.N)]
        ElementTable[, element_key := paste(
          chrom,
          chromStart,
          chromEnd,
          elementCenter,
          sep="\r"
        )]
        ElementTable[, .(
          element_class,
          element_id,
          element_key,
          chrom,
          chromStart,
          chromEnd,
          elementCenter,
          element_name
        )]
      }
    ),
    use.names=TRUE
  )

  ReferenceRatio <- data.table::copy(RatioTables$ChIP)
  ReferenceRatio[, ratioRow := seq_len(.N), by=chrom]
  ReferenceRatio[, binCenter := chromStart+(chromEnd-chromStart)/2]
  AnchorLookup <- ReferenceRatio[, .(
    chrom,
    anchorCenter=binCenter,
    anchorRow=ratioRow
  )]
  Anchors <- AnchorLookup[
    AllElements,
    on=.(chrom, anchorCenter=elementCenter),
    roll="nearest",
    .(
      element_class=i.element_class,
      element_id=i.element_id,
      element_key=i.element_key,
      chrom=i.chrom,
      chromStart=i.chromStart,
      chromEnd=i.chromEnd,
      elementCenter=i.elementCenter,
      element_name=i.element_name,
      anchorRow,
      matchedCenter=x.anchorCenter
    )
  ]
  if(anyNA(Anchors$anchorRow)){
    MissingChromosomes <- unique(Anchors[is.na(anchorRow), chrom])
    stop(
      "Genomic elements refer to chromosome(s) absent from the paired ",
      "nuclear ratio tables: ",
      paste(MissingChromosomes, collapse=", "),
      call.=FALSE
    )
  }
  Anchors[, anchorDistance := matchedCenter-elementCenter]
  Queries <- Anchors[, .(
    offset=Offsets,
    targetRow=anchorRow+OffsetRows
  ), by=.(element_class, element_id, chrom)]

  MedianOrNA <- function(values){
    if(all(is.na(values))){
      NA_real_
    } else {
      stats::median(values, na.rm=TRUE)
    }
  }
  ExtractAssayProfiles <- function(Ratio){
    Ratio <- data.table::copy(Ratio)
    Ratio[, ratioRow := seq_len(.N), by=chrom]
    Signal <- Ratio[
      Queries,
      on=.(chrom, ratioRow=targetRow),
      c(
        list(
          element_class=i.element_class,
          element_id=i.element_id,
          offset=i.offset
        ),
        mget(PlotMetrics)
      )
    ]
    BuildElementProfile <- function(element_class){
      TargetClass <- element_class
      ClassSignal <- Signal[
        base::which(Signal$element_class == TargetClass)
      ]
      Profile <- ClassSignal[, {
        MetricSummaries <- lapply(.SD, MedianOrNA)
        c(
          list(n_contributing=sum(is.finite(.SD[[1]]))),
          MetricSummaries
        )
      }, by=offset, .SDcols=PlotMetrics]
      FullOffsets <- data.table::data.table(offset=Offsets)
      Profile <- Profile[FullOffsets, on=.(offset)]
      data.table::setorder(Profile, offset)
      Profile
    }
    ElementProfiles <- lapply(SelectedElements, BuildElementProfile)
    names(ElementProfiles) <- SelectedElements
    ElementProfiles
  }
  Profiles <- list(
    ChIP=ExtractAssayProfiles(RatioTables$ChIP),
    BrDU=ExtractAssayProfiles(RatioTables$BrDU)
  )

  SmoothProfile <- function(x, y){
    Smoothed <- rep(NA_real_, length(y))
    Good <- which(is.finite(x) & is.finite(y))
    if(length(Good) < 4L || length(unique(x[Good])) < 4L){
      Smoothed[Good] <- y[Good]
      return(Smoothed)
    }
    Fit <- try(
      stats::smooth.spline(x[Good], y[Good], spar=SmoothingSpar),
      silent=TRUE
    )
    if(inherits(Fit, "try-error")){
      Smoothed[Good] <- y[Good]
    } else {
      Smoothed[Good] <- Fit$y
    }
    Smoothed
  }
  TransformProfileForDisplay <- function(values, metric){
    Values <- suppressWarnings(as.numeric(values))
    if(!Log2Profile){
      return(Values)
    }
    Transformed <- rep(NA_real_, length(Values))
    Finite <- is.finite(Values)
    if(metric == "ip.score"){
      NonNegative <- Finite & Values >= 0
      Transformed[NonNegative] <- log2(1+Values[NonNegative])
    } else {
      Positive <- Finite & Values > 0
      Transformed[Positive] <- log2(Values[Positive])
    }
    Transformed
  }
  DisplayMetricTitle <- function(metric){
    if(!Log2Profile){
      return(MetricTitles[[metric]])
    }
    if(metric == "ip.score"){
      paste0("log2(1 + ", MetricTitles[[metric]], ")")
    } else {
      paste0("log2(", MetricTitles[[metric]], ")")
    }
  }
  BuildDisplayProfiles <- function(AssayProfiles){
    SmoothedProfiles <- lapply(
      SelectedElements,
      function(element_class){
        Profile <- data.table::copy(AssayProfiles[[element_class]])
        for(metric in PlotMetrics){
          DisplayValues <- TransformProfileForDisplay(
            Profile[[metric]],
            metric
          )
          data.table::set(
            Profile,
            j=metric,
            value=SmoothProfile(Profile$offset, DisplayValues)
          )
        }
        Profile
      }
    )
    names(SmoothedProfiles) <- SelectedElements
    SmoothedProfiles
  }
  DisplayProfiles <- list(
    ChIP=BuildDisplayProfiles(Profiles$ChIP),
    BrDU=BuildDisplayProfiles(Profiles$BrDU)
  )

  CollectProfileValues <- function(assay_label, metric){
    unlist(
      lapply(
        DisplayProfiles[[assay_label]],
        function(Profile) Profile[[metric]]
      ),
      use.names=FALSE
    )
  }
  AutomaticLimits <- function(values, baseline){
    Values <- values[is.finite(values)]
    if(length(Values) == 0L){
      stop("No finite profile values remain for y-axis calculation.", call.=FALSE)
    }
    Lower <- min(c(Values, baseline))
    Upper <- max(c(Values, baseline))
    Span <- Upper-Lower
    if(!is.finite(Span) || Span == 0){
      Span <- max(0.5, abs(Upper)*0.10)
    }
    Lower <- Lower-0.08*Span
    Upper <- Upper+0.08*Span
    if(baseline == 0 && all(Values >= 0)){
      Lower <- 0
    }
    c(Lower, Upper)
  }
  AlignLimitsAtBaseline <- function(ChIPLimits, BrDULimits, baseline){
    BaselineFraction <- function(Limits){
      (baseline-Limits[[1]])/diff(Limits)
    }
    Fractions <- c(
      ChIP=BaselineFraction(ChIPLimits),
      BrDU=BaselineFraction(BrDULimits)
    )
    TargetFraction <- max(Fractions)
    if(!is.finite(TargetFraction) ||
       TargetFraction <= sqrt(.Machine$double.eps) ||
       TargetFraction >= 1-sqrt(.Machine$double.eps)){
      return(list(ChIP=ChIPLimits, BrDU=BrDULimits))
    }
    ExpandLower <- function(Limits, fraction){
      if(fraction+sqrt(.Machine$double.eps) >= TargetFraction){
        return(Limits)
      }
      NewLower <- (
        baseline-TargetFraction*Limits[[2]]
      )/(1-TargetFraction)
      Limits[[1]] <- min(Limits[[1]], NewLower)
      Limits
    }
    list(
      ChIP=ExpandLower(ChIPLimits, Fractions[["ChIP"]]),
      BrDU=ExpandLower(BrDULimits, Fractions[["BrDU"]])
    )
  }

  YLimitRows <- lapply(
    PlotMetrics,
    function(metric){
      Baseline <- NeutralBaselines[[metric]]
      ChIPValues <- CollectProfileValues("ChIP", metric)
      BrDUValues <- CollectProfileValues("BrDU", metric)
      ChIPLimits <- AutomaticLimits(ChIPValues, Baseline)
      BrDULimits <- AutomaticLimits(BrDUValues, Baseline)
      ChIPSource <- "automatic"
      BrDUSource <- "automatic"
      if(is.finite(ChIPYValues[[metric]])){
        ChIPLimits[[2]] <- ChIPYValues[[metric]]
        ChIPSource <- "y_val_chip"
      }
      if(is.finite(BrDUYValues[[metric]])){
        BrDULimits[[2]] <- BrDUYValues[[metric]]
        BrDUSource <- "y_val_brdu"
      }
      if(ChIPLimits[[2]] <= ChIPLimits[[1]]){
        ChIPLimits[[1]] <- min(Baseline, ChIPLimits[[2]]-0.5)
      }
      if(BrDULimits[[2]] <= BrDULimits[[1]]){
        BrDULimits[[1]] <- min(Baseline, BrDULimits[[2]]-0.5)
      }
      Aligned <- AlignLimitsAtBaseline(
        ChIPLimits,
        BrDULimits,
        Baseline
      )
      ChIPFinite <- ChIPValues[is.finite(ChIPValues)]
      BrDUFinite <- BrDUValues[is.finite(BrDUValues)]
      data.table::data.table(
        metric=metric,
        baseline=Baseline,
        chip_lower=Aligned$ChIP[[1]],
        chip_upper=Aligned$ChIP[[2]],
        brdu_lower=Aligned$BrDU[[1]],
        brdu_upper=Aligned$BrDU[[2]],
        chip_source=ChIPSource,
        brdu_source=BrDUSource,
        chip_clipped_low=sum(ChIPFinite < Aligned$ChIP[[1]]),
        chip_clipped_high=sum(ChIPFinite > Aligned$ChIP[[2]]),
        brdu_clipped_low=sum(BrDUFinite < Aligned$BrDU[[1]]),
        brdu_clipped_high=sum(BrDUFinite > Aligned$BrDU[[2]])
      )
    }
  )
  YLimitTable <- data.table::rbindlist(YLimitRows, use.names=TRUE)
  YLimits <- setNames(
    lapply(
      PlotMetrics,
      function(metric){
        TargetMetric <- metric
        Row <- YLimitTable[
          base::which(YLimitTable$metric == TargetMetric)
        ]
        list(
          ChIP=c(Row$chip_lower[[1]], Row$chip_upper[[1]]),
          BrDU=c(Row$brdu_lower[[1]], Row$brdu_upper[[1]])
        )
      }
    ),
    PlotMetrics
  )

  KeyMembership <- unique(AllElements[, .(
    element_key,
    element_class,
    chrom,
    chromStart,
    chromEnd,
    element_name
  )])
  SharedKeys <- KeyMembership[, .(
    n_classes=data.table::uniqueN(element_class)
  ), by=element_key][n_classes > 1L, element_key]
  SharedCoordinates <- KeyMembership[element_key %in% SharedKeys]
  if(nrow(SharedCoordinates) > 0L){
    SharedCoordinates[, element_order := match(
      element_class,
      SelectedElements
    )]
    SharedCoordinates[, chromosome_order := match(
      chrom,
      NuclearChromosomes
    )]
    data.table::setorder(
      SharedCoordinates,
      chromosome_order,
      chromStart,
      chromEnd,
      element_order
    )
    SharedCoordinates[
      , c("element_order", "chromosome_order") := NULL
    ]
  }

  ChIPPrefix <- sub("-ChIP$", "", ChIPSampleName)
  BrDUPrefix <- sub("-BrDU$", "", BrDUSampleName)
  PairLabel <- if(identical(ChIPPrefix, BrDUPrefix)){
    ChIPPrefix
  } else {
    paste0(ChIPSampleName, " vs ", BrDUSampleName)
  }
  PairTag <- gsub("[^A-Za-z0-9._-]+", "_", PairLabel)
  ElementTag <- paste(SelectedElements, collapse="-")
  PeakSourceTag <- if(any(SelectedElements %in% PeakElements)){
    paste0("_", PeakSource, "Peaks")
  } else {
    ""
  }
  MetricTag <- if(identical(PlotMetrics, AllMetrics)){
    "all_metrics"
  } else {
    paste(gsub("[^A-Za-z0-9]+", "", PlotMetrics), collapse="-")
  }
  OutputFile <- file.path(
    OutputDir,
    paste0(
      PairTag,
      "_ChIP_BrDU_",
      Alignment,
      "_collapsed_",
      ScaleTag,
      "_",
      ElementTag,
      PeakSourceTag,
      "_",
      MetricTag,
      "_Element_Comparison.pdf"
    )
  )

  PageCount <- as.integer(ceiling(
    length(SelectedElements)/MaxRowsPerPage
  ))
  ColumnsPerPage <- length(PlotMetrics)
  RowsPerFullPage <- min(MaxRowsPerPage, length(SelectedElements))
  PdfWidth <- max(6.5, 3.5*ColumnsPerPage)
  PdfHeight <- c(4.8, 7.6, 10.2)[[RowsPerFullPage]]

  AddDistanceAxis <- function(){
    AxisAt <- seq(-Window, Window, length.out=5L)/1000
    graphics::axis(
      1,
      at=AxisAt,
      labels=format(signif(AxisAt, 3), trim=TRUE),
      las=1,
      cex.axis=0.86,
      mgp=c(1.8, 0.45, 0),
      tcl=-0.22
    )
  }
  PlotPanel <- function(element_class, metric, show_legend=FALSE){
    X <- DisplayProfiles$ChIP[[element_class]]$offset/1000
    ChIPValues <- DisplayProfiles$ChIP[[element_class]][[metric]]
    BrDUValues <- DisplayProfiles$BrDU[[element_class]][[metric]]
    ChIPLimits <- YLimits[[metric]]$ChIP
    BrDULimits <- YLimits[[metric]]$BrDU
    Baseline <- NeutralBaselines[[metric]]

    graphics::plot(
      X,
      ChIPValues,
      type="n",
      xlim=c(-Window, Window)/1000,
      ylim=ChIPLimits,
      axes=FALSE,
      xlab="",
      ylab="",
      main=DisplayMetricTitle(metric),
      cex.main=1,
      font.main=2,
      bty="n",
      xaxs="i",
      yaxs="i"
    )
    graphics::abline(
      h=Baseline,
      col=BaselineColor,
      lty=2,
      lwd=0.8
    )
    graphics::lines(
      X,
      ChIPValues,
      col=ChIPColor,
      lty=1,
      lwd=2
    )
    AddDistanceAxis()
    ChIPTicks <- pretty(ChIPLimits, n=5)
    ChIPTicks <- ChIPTicks[
      ChIPTicks >= ChIPLimits[[1]] &
      ChIPTicks <= ChIPLimits[[2]]
    ]
    graphics::axis(
      2,
      at=ChIPTicks,
      labels=signif(ChIPTicks, 3),
      las=1,
      cex.axis=0.80,
      col=ChIPColor,
      col.ticks=ChIPColor,
      col.axis=ChIPColor,
      mgp=c(2.2, 0.48, 0),
      tcl=-0.22
    )
    graphics::mtext(
      paste0("ChIP ", DisplayMetricTitle(metric)),
      side=2,
      line=2.65,
      cex=0.72,
      col=ChIPColor
    )
    graphics::mtext(
      if(element_class %in% PeakElements){
        "Distance from peak summit (kb)"
      } else {
        "Distance from element midpoint (kb)"
      },
      side=1,
      line=2.0,
      cex=0.80
    )
    graphics::box(bty="l", col="gray35", lwd=0.8)

    graphics::par(new=TRUE)
    graphics::plot(
      X,
      BrDUValues,
      type="n",
      xlim=c(-Window, Window)/1000,
      ylim=BrDULimits,
      axes=FALSE,
      xlab="",
      ylab="",
      bty="n",
      xaxs="i",
      yaxs="i"
    )
    graphics::lines(
      X,
      BrDUValues,
      col=BrDUColor,
      lty=3,
      lwd=2
    )
    BrDUTicks <- pretty(BrDULimits, n=5)
    BrDUTicks <- BrDUTicks[
      BrDUTicks >= BrDULimits[[1]] &
      BrDUTicks <= BrDULimits[[2]]
    ]
    graphics::axis(
      4,
      at=BrDUTicks,
      labels=signif(BrDUTicks, 3),
      las=1,
      cex.axis=0.80,
      col=BrDUColor,
      col.ticks=BrDUColor,
      col.axis=BrDUColor,
      mgp=c(2.2, 0.48, 0),
      tcl=-0.22
    )
    graphics::mtext(
      paste0("BrDU ", DisplayMetricTitle(metric)),
      side=4,
      line=2.65,
      cex=0.72,
      col=BrDUColor
    )
    CurrentLimits <- graphics::par("usr")
    graphics::segments(
      x0=CurrentLimits[[2]],
      y0=CurrentLimits[[3]],
      x1=CurrentLimits[[2]],
      y1=CurrentLimits[[4]],
      col=BrDUColor,
      lty=3,
      lwd=1.1,
      xpd=FALSE
    )
    if(show_legend){
      graphics::legend(
        "topright",
        legend=c("ChIP (left axis)", "BrDU (right axis)"),
        col=c(ChIPColor, BrDUColor),
        lty=c(1, 3),
        lwd=2,
        bty="n",
        cex=0.76,
        title=PrettyElementClass(element_class),
        text.font=1,
        title.adj=0
      )
    }
  }
  AddPageLabels <- function(page_number){
    graphics::mtext(
      paste0("ChIP-BrDU genomic-element comparison: ", PairLabel),
      outer=TRUE,
      side=3,
      line=2.15,
      font=2,
      cex=1.18,
      col="gray22"
    )
    graphics::mtext(
      paste0(
        Alignment,
        " | collapsed final ratio tables | ",
        ScaleLabel
      ),
      outer=TRUE,
      side=3,
      line=1.05,
      cex=0.68,
      col="gray42"
    )
    graphics::mtext(
      paste0(
        "median profiles | +/-",
        format(Window, big.mark=","),
        " bp",
        if(any(SelectedElements %in% PeakElements)){
          paste0(" | peaks: ", PeakSource)
        } else {
          ""
        },
        " | ChIP solid/left axis | BrDU dotted/right axis"
      ),
      outer=TRUE,
      side=3,
      line=0.12,
      cex=0.64,
      col="gray42"
    )
    graphics::mtext(
      paste0("Page ", page_number, " of ", PageCount),
      outer=TRUE,
      side=1,
      line=0.45,
      font=3,
      cex=0.74,
      col="gray42"
    )
  }

  grDevices::pdf(
    OutputFile,
    width=PdfWidth,
    height=PdfHeight,
    useDingbats=FALSE
  )
  PdfDevice <- grDevices::dev.cur()
  on.exit({
    OpenDevices <- grDevices::dev.list()
    if(!is.null(OpenDevices) && PdfDevice %in% OpenDevices){
      grDevices::dev.off(which=PdfDevice)
    }
  }, add=TRUE)

  for(PageIndex in seq_len(PageCount)){
    FirstElement <- (PageIndex-1L)*MaxRowsPerPage+1L
    LastElement <- min(
      PageIndex*MaxRowsPerPage,
      length(SelectedElements)
    )
    PageElements <- SelectedElements[FirstElement:LastElement]
    graphics::par(
      mfrow=c(RowsPerFullPage, ColumnsPerPage),
      oma=c(2.0, 0.9, 4.25, 0.9),
      mar=c(3.4, 4.1, 2.2, 4.1),
      mgp=c(2.2, 0.55, 0),
      tcl=-0.22
    )
    PanelNumber <- 0L
    for(element_class in PageElements){
      for(metric in PlotMetrics){
        PanelNumber <- PanelNumber+1L
        PlotPanel(
          element_class,
          metric,
          show_legend=TRUE
        )
      }
    }
    BlankPanelCount <- (
      RowsPerFullPage-length(PageElements)
    )*ColumnsPerPage
    if(BlankPanelCount > 0L){
      for(BlankPanel in seq_len(BlankPanelCount)){
        graphics::plot.new()
      }
    }
    AddPageLabels(PageIndex)
  }

  grDevices::dev.off(which=PdfDevice)
  message("ChIP-BrDU element comparison saved: ", OutputFile)

  invisible(list(
    pdf=OutputFile,
    output_pdf=OutputFile,
    chip_sample_dir=ChIPSampleDir,
    brdu_sample_dir=BrDUSampleDir,
    chip_sample_name=ChIPSampleName,
    brdu_sample_name=BrDUSampleName,
    pair_label=PairLabel,
    alignment=Alignment,
    peak_source=if(any(SelectedElements %in% PeakElements)) PeakSource else NULL,
    peak_source_sample_dir=if(any(SelectedElements %in% PeakElements)) PeakSampleDir else NULL,
    strand_mode="collapsed",
    log2_profile=Log2Profile,
    display_transform=if(Log2Profile){
      "log2(1+x) for ip.score; log2(x) for positive ratio values; non-positive ratios shown as missing"
    } else {
      "untransformed"
    },
    elements=SelectedElements,
    peak_element_selectors=intersect(SelectedElements, PeakElements),
    metrics=PlotMetrics,
    window=Window,
    step=Step,
    bin_widths=RatioBinWidths,
    offsets=Offsets,
    expected_bins_per_element=length(Offsets),
    ratio_files=RatioFiles,
    ratio_chrM_rows_omitted=RatioChrMOmitted,
    paired_ratio_coordinates_identical=CoordinatesMatch,
    element_files=ElementFiles,
    element_counts=ElementCounts,
    element_chrM_records_omitted=ElementChrMOmitted,
    anchors=Anchors,
    shared_coordinates=SharedCoordinates,
    profiles=Profiles,
    display_profiles=DisplayProfiles,
    profile_statistic="median",
    y_val_chip=ChIPYValues,
    y_val_brdu=BrDUYValues,
    y_limits=YLimits,
    y_limit_table=YLimitTable,
    y_limit_semantics="assay-specific upper limits; named values may override selected metrics independently",
    raw_neutral_baselines=RawNeutralBaselines[PlotMetrics],
    neutral_baselines=NeutralBaselines[PlotMetrics],
    edge_handling="missing chromosome-edge bins excluded; no interpolation or zero padding",
    chromosomes=NuclearChromosomes,
    chrM_excluded=TRUE,
    excluded_annotations=c("ORF", "rDNA"),
    element_centering="curated BED interval midpoint or saved primary-analysis peakSummit; nearest saved ratio-window centre",
    page_count=PageCount,
    maximum_element_rows_per_page=MaxRowsPerPage,
    page_layout="one element per row; selected final metrics in columns; ChIP and BrDU overlaid with separate aligned y-axes",
    pdf_dimensions_inches=c(width=PdfWidth, height=PdfHeight),
    primary_ratio_output_only=TRUE,
    annotation_source="project-local processed genomic-element BED files and/or one explicitly selected sample-specific primary-analysis peak source",
    plotter_operations=c(
      bam_reading=FALSE,
      coverage_reading=FALSE,
      simulation=FALSE,
      noise_estimation=FALSE,
      signal_filtering=FALSE,
      ratio_recalculation=FALSE,
      strand_collapsing=FALSE,
      peak_calling=FALSE,
      pvalue_thresholding=FALSE,
      interpolation=FALSE,
      zero_padding=FALSE
    ),
    display_operations=c(
      element_midpoint_median=TRUE,
      spline_smoothing=TRUE,
      dual_y_axes=TRUE,
      neutral_baseline_alignment=TRUE,
      shared_limits_by_assay_and_metric=TRUE,
      chip_solid_line=TRUE,
      brdu_dotted_line=TRUE,
      log_transformation=Log2Profile,
      coverage_log1p=Log2Profile,
      ratio_log2_positive_only=Log2Profile
    )
  ))
}


## One-call primary analysis and standard single-assay report wrapper.
## The wrapper does not run the whole-genome, Early/Late-only, ChIP-BrDU
## enrichment-comparison, or ChIP-BrDU regional-comparison plotters.
## Regions is optional; when supplied it must be a data frame containing
## Chromosome, RegionStart, and RegionEnd (zero-based, half-open coordinates).
## Standard generic/malign runs produce peak, genomic-element profile, boxplot,
## heatmap, and optional regional PDFs. An mrdna run produces rDNA PDFs only.
## ProfileElements=NULL retains all curated cohorts in the profile report;
## Elements controls the boxplot and heatmap cohorts. Either may use the five
## sample-specific *Peaks selectors documented by the individual plotters.
##
## Example:
## ChIP_BrDU_Complete_Analysis(
##   Input_R1="/path/to/input_R1.fastq.gz",
##   Input_R2="/path/to/input_R2.fastq.gz",
##   Assay_R1="/path/to/chip_R1.fastq.gz",
##   Assay_R2="/path/to/chip_R2.fastq.gz",
##   Assay="ChIP",
##   Alignment="generic",
##   ExpTitle="Smc5",
##   Directory="/path/to/ChIP_results"
## )
ChIP_BrDU_Complete_Analysis <- function(
    Input_R1="/full/path/to/file_R1.fastq.gz",
    Input_R2="/full/path/to/file_R2.fastq.gz",
    Assay_R1="/full/path/to/file_R1.fastq.gz",
    Assay_R2="/full/path/to/file_R2.fastq.gz",
    Assay=c("ChIP", "BrDU"),
    Alignment=c("generic", "malign", "mrdna"),
    ExpTitle="Smc5-trial",
    Directory="None",
    slidingWindow="YES",
    StrandModes=c("collapsed", "separated"),
    Elements=c("EarlyOrigin", "LateOrigin"),
    Regions=NULL,
    ReportDir=NULL,
    ProfileElements=NULL){

  Assay <- match.arg(Assay)
  Alignment <- match.arg(Alignment)
  StrandModes <- unique(match.arg(
    StrandModes,
    choices=c("collapsed", "separated"),
    several.ok=TRUE
  ))

  ValidateText <- function(value, name){
    if(length(value) != 1L || is.na(value) || !nzchar(as.character(value))){
      stop(name, " must be one non-empty value.", call.=FALSE)
    }
    as.character(value)
  }

  FastqPaths <- c(
    Input_R1=ValidateText(Input_R1, "Input_R1"),
    Input_R2=ValidateText(Input_R2, "Input_R2"),
    Assay_R1=ValidateText(Assay_R1, "Assay_R1"),
    Assay_R2=ValidateText(Assay_R2, "Assay_R2")
  )
  FastqNames <- names(FastqPaths)
  FastqPaths <- path.expand(FastqPaths)
  names(FastqPaths) <- FastqNames
  MissingFastqs <- FastqPaths[!file.exists(FastqPaths)]
  if(length(MissingFastqs) > 0L){
    stop(
      "FASTQ file(s) not found:\n",
      paste(MissingFastqs, collapse="\n"),
      call.=FALSE
    )
  }
  FastqPaths <- normalizePath(FastqPaths, winslash="/", mustWork=TRUE)
  names(FastqPaths) <- FastqNames

  if(length(ExpTitle) == 0L || is.null(ExpTitle) ||
     is.na(ExpTitle[[1]]) || !nzchar(as.character(ExpTitle[[1]]))){
    ExpTitle <- "None"
  } else {
    ExpTitle <- ValidateText(ExpTitle, "ExpTitle")
  }
  if(length(Directory) == 0L || is.null(Directory) ||
     is.na(Directory[[1]]) || !nzchar(as.character(Directory[[1]]))){
    Directory <- "None"
  } else {
    Directory <- ValidateText(Directory, "Directory")
  }
  if(length(slidingWindow) != 1L || is.na(slidingWindow)){
    stop("slidingWindow must contain one value.", call.=FALSE)
  }
  if(!is.character(Elements) || length(Elements) == 0L ||
     any(is.na(Elements) | !nzchar(Elements))){
    stop("Elements must contain at least one non-empty element name.", call.=FALSE)
  }
  Elements <- unique(Elements)
  SupportedElementSelectors <- c(
    "ARS", "EarlyOrigin", "LateOrigin", "TER", "Ty", "tRNA",
    "Centromere", "Convergent", "Divergent", "CTrans", "WTrans",
    "GenomewidePeaks", "NonOriginPeaks", "OriginPeaks",
    "EarlyOriginPeaks", "LateOriginPeaks"
  )
  InvalidElements <- setdiff(Elements, SupportedElementSelectors)
  if(length(InvalidElements) > 0L){
    stop(
      "Unsupported Elements value(s): ",
      paste(InvalidElements, collapse=", "),
      ". Supported values are: ",
      paste(SupportedElementSelectors, collapse=", "),
      ".",
      call.=FALSE
    )
  }
  if(!is.null(ProfileElements)){
    if(!is.character(ProfileElements) || length(ProfileElements) == 0L ||
       any(is.na(ProfileElements) | !nzchar(ProfileElements))){
      stop(
        "ProfileElements must be NULL or contain at least one non-empty element name.",
        call.=FALSE
      )
    }
    ProfileElements <- unique(ProfileElements)
    InvalidProfileElements <- setdiff(
      ProfileElements,
      SupportedElementSelectors
    )
    if(length(InvalidProfileElements) > 0L){
      stop(
        "Unsupported ProfileElements value(s): ",
        paste(InvalidProfileElements, collapse=", "),
        ". Supported values are: ",
        paste(SupportedElementSelectors, collapse=", "),
        ".",
        call.=FALSE
      )
    }
  }

  if(!is.null(Regions)){
    if(!is.data.frame(Regions)){
      stop(
        "Regions must be NULL or a data frame with Chromosome, RegionStart, and RegionEnd columns.",
        call.=FALSE
      )
    }
    RequiredRegionColumns <- c("Chromosome", "RegionStart", "RegionEnd")
    MissingRegionColumns <- setdiff(RequiredRegionColumns, names(Regions))
    if(length(MissingRegionColumns) > 0L){
      stop(
        "Regions is missing column(s): ",
        paste(MissingRegionColumns, collapse=", "),
        call.=FALSE
      )
    }
    Regions <- Regions[, RequiredRegionColumns, drop=FALSE]
    if(nrow(Regions) == 0L){
      Regions <- NULL
    } else {
      Regions$Chromosome <- as.character(Regions$Chromosome)
      Regions$RegionStart <- suppressWarnings(as.numeric(Regions$RegionStart))
      Regions$RegionEnd <- suppressWarnings(as.numeric(Regions$RegionEnd))
      InvalidRegions <- is.na(Regions$Chromosome) |
        !nzchar(Regions$Chromosome) |
        !is.finite(Regions$RegionStart) |
        !is.finite(Regions$RegionEnd) |
        Regions$RegionStart < 0 |
        Regions$RegionEnd <= Regions$RegionStart
      if(any(InvalidRegions)){
        stop(
          "Every Regions row must contain a chromosome and valid start < end coordinates.",
          call.=FALSE
        )
      }
    }
  }
  if(Alignment == "mrdna" && !is.null(Regions)){
    stop(
      "Regions cannot be used with Alignment='mrdna'; use the rDNA report for that modality.",
      call.=FALSE
    )
  }

  SampleName <- if(ExpTitle == "None"){
    strsplit(basename(FastqPaths[["Input_R1"]]), "_", fixed=TRUE)[[1]][[1]]
  } else {
    ExpTitle
  }
  BaseDirectory <- if(Directory == "None"){
    path.expand("~/Desktop")
  } else {
    path.expand(Directory)
  }
  SampleDir <- file.path(BaseDirectory, SampleName)

  message("Starting primary analysis for ", SampleName, " [", Assay, "/", Alignment, "]...")
  ChIP_BrDU_Primary_Analysis(
    Input_R1=FastqPaths[["Input_R1"]],
    Input_R2=FastqPaths[["Input_R2"]],
    Assay_R1=FastqPaths[["Assay_R1"]],
    Assay_R2=FastqPaths[["Assay_R2"]],
    Assay=Assay,
    Alignment=Alignment,
    ExpTitle=ExpTitle,
    Directory=Directory,
    slidingWindow=slidingWindow
  )

  if(!dir.exists(SampleDir)){
    stop(
      "Primary analysis completed without creating the expected sample directory: ",
      SampleDir,
      call.=FALSE
    )
  }
  SampleDir <- normalizePath(SampleDir, winslash="/", mustWork=TRUE)

  if(is.null(ReportDir)){
    ReportDir <- file.path(SampleDir, "Complete_Analysis_Reports")
  } else {
    ReportDir <- ValidateText(ReportDir, "ReportDir")
    ReportDir <- path.expand(ReportDir)
  }
  dir.create(ReportDir, recursive=TRUE, showWarnings=FALSE)
  if(!dir.exists(ReportDir)){
    stop("Could not create ReportDir: ", ReportDir, call.=FALSE)
  }
  ReportDir <- normalizePath(ReportDir, winslash="/", mustWork=TRUE)
  ManifestFile <- file.path(ReportDir, "Analysis_Manifest.tsv")

  Manifest <- data.frame(
    analysis="primary_analysis",
    mode=paste(Assay, Alignment, sep="/"),
    status="complete",
    output=SampleDir,
    note="",
    stringsAsFactors=FALSE
  )
  Results <- list()

  SaveManifest <- function(){
    utils::write.table(
      Manifest,
      file=ManifestFile,
      quote=FALSE,
      row.names=FALSE,
      sep="\t",
      na=""
    )
  }
  SaveManifest()

  RelativeOutput <- function(paths){
    paths <- unique(as.character(paths))
    paths <- paths[!is.na(paths) & nzchar(paths)]
    if(length(paths) == 0L) return("")
    Normalized <- vapply(
      paths,
      function(path){
        if(file.exists(path)){
          normalizePath(path, winslash="/", mustWork=TRUE)
        } else {
          path.expand(path)
        }
      },
      character(1)
    )
    Prefix <- paste0(ReportDir, "/")
    Inside <- startsWith(Normalized, Prefix)
    Normalized[Inside] <- substring(Normalized[Inside], nchar(Prefix)+1L)
    paste(Normalized, collapse="; ")
  }

  RecordStage <- function(analysis, mode, status, output="", note=""){
    Manifest <<- rbind(
      Manifest,
      data.frame(
        analysis=analysis,
        mode=mode,
        status=status,
        output=output,
        note=note,
        stringsAsFactors=FALSE
      )
    )
    SaveManifest()
  }

  RunStage <- function(key, analysis, mode, expression){
    Result <- tryCatch(
      force(expression),
      error=function(error) error
    )
    if(inherits(Result, "error")){
      Note <- conditionMessage(Result)
      Results[[key]] <<- list(status="failed", error=Note)
      RecordStage(analysis, mode, "failed", note=Note)
      return(invisible(NULL))
    }
    Pdfs <- character()
    if(is.list(Result)){
      if(!is.null(Result$pdf)) Pdfs <- c(Pdfs, Result$pdf)
      if(!is.null(Result$output_pdf)) Pdfs <- c(Pdfs, Result$output_pdf)
    }
    Pdfs <- unique(as.character(Pdfs))
    Pdfs <- Pdfs[!is.na(Pdfs) & nzchar(Pdfs)]
    if(length(Pdfs) == 0L || any(!file.exists(Pdfs))){
      Note <- "Report function did not produce its expected PDF."
      Results[[key]] <<- list(status="failed", result=Result, error=Note)
      RecordStage(analysis, mode, "failed", note=Note)
      return(invisible(NULL))
    }
    Results[[key]] <<- Result
    RecordStage(
      analysis,
      mode,
      "complete",
      output=RelativeOutput(Pdfs)
    )
    invisible(Result)
  }

  MakeReportSubdir <- function(name){
    Path <- file.path(ReportDir, name)
    dir.create(Path, recursive=TRUE, showWarnings=FALSE)
    if(!dir.exists(Path)) stop("Could not create report directory: ", Path)
    normalizePath(Path, winslash="/", mustWork=TRUE)
  }

  if(Alignment %in% c("generic", "malign")){
    PeakDir <- MakeReportSubdir("Peak_Enrichment")
    ElementProfileDir <- MakeReportSubdir("Genomic_Element_Enrichment")
    BoxplotDir <- MakeReportSubdir("Genomic_Element_Boxplots")
    HeatmapDir <- MakeReportSubdir("Genomic_Element_Heatmaps")

    for(StrandMode in StrandModes){
      ModeLabel <- paste(Alignment, StrandMode, sep="/")
      RunStage(
        key=paste0("peak_enrichment_", StrandMode),
        analysis="peak_enrichment",
        mode=ModeLabel,
        ChIP_BrDU_Peak_Enrichment_Plotter(
          SampleDir=SampleDir,
          Assay=Assay,
          Alignment=Alignment,
          StrandMode=StrandMode,
          OutputDir=PeakDir
        )
      )
      RunStage(
        key=paste0("genomic_element_enrichment_", StrandMode),
        analysis="genomic_element_enrichment",
        mode=ModeLabel,
        ChIP_BrDU_Genomic_Element_Enrichment_Plotter(
          SampleDir=SampleDir,
          Assay=Assay,
          Alignment=Alignment,
          StrandMode=StrandMode,
          Elements=ProfileElements,
          OutputDir=ElementProfileDir
        )
      )
    }

    RunStage(
      key="genomic_element_boxplots",
      analysis="genomic_element_boxplots",
      mode=paste(Alignment, "collapsed", sep="/"),
      ChIP_BrDU_Genomic_Element_Boxplotter(
        SampleDir=SampleDir,
        Assay=Assay,
        Alignment=Alignment,
        Elements=Elements,
        OutputDir=BoxplotDir
      )
    )
    RunStage(
      key="genomic_element_heatmaps",
      analysis="genomic_element_heatmaps",
      mode=paste(Alignment, "collapsed", sep="/"),
      ChIP_BrDU_Genomic_Element_Heatmap_Plotter(
        SampleDir=SampleDir,
        Assay=Assay,
        Alignment=Alignment,
        Elements=Elements,
        OutputDir=HeatmapDir
      )
    )

    if(!is.null(Regions)){
      RegionDir <- MakeReportSubdir("Regional_Profiles")
      for(RegionIndex in seq_len(nrow(Regions))){
        Chromosome <- Regions$Chromosome[[RegionIndex]]
        RegionStart <- Regions$RegionStart[[RegionIndex]]
        RegionEnd <- Regions$RegionEnd[[RegionIndex]]
        for(StrandMode in StrandModes){
          RegionLabel <- paste0(
            Chromosome,
            ":",
            format(RegionStart, scientific=FALSE, trim=TRUE),
            "-",
            format(RegionEnd, scientific=FALSE, trim=TRUE)
          )
          RunStage(
            key=paste0("regional_profile_", RegionIndex, "_", StrandMode),
            analysis="regional_profile",
            mode=paste(Alignment, StrandMode, RegionLabel, sep="/"),
            ChIP_BrDU_Region_Plotter(
              SampleDir=SampleDir,
              Chromosome=Chromosome,
              RegionStart=RegionStart,
              RegionEnd=RegionEnd,
              Assay=Assay,
              Alignment=Alignment,
              StrandMode=StrandMode,
              OutputDir=RegionDir
            )
          )
        }
      }
    }
  } else {
    rDNADir <- MakeReportSubdir("rDNA_Profiles")
    for(StrandMode in StrandModes){
      RunStage(
        key=paste0("rdna_profile_", StrandMode),
        analysis="rdna_profile",
        mode=paste("mrdna", StrandMode, sep="/"),
        ChIP_BrDU_rDNA_Plotter(
          SampleDir=SampleDir,
          Assay=Assay,
          StrandMode=StrandMode,
          OutputDir=rDNADir
        )
      )
    }
  }

  CompletedPdfs <- unique(unlist(lapply(
    Results,
    function(result){
      if(!is.list(result) || identical(result$status, "failed")){
        return(character())
      }
      unique(c(result$pdf, result$output_pdf))
    }
  ), use.names=FALSE))
  CompletedPdfs <- as.character(CompletedPdfs)
  CompletedPdfs <- CompletedPdfs[
    !is.na(CompletedPdfs) & nzchar(CompletedPdfs) & file.exists(CompletedPdfs)
  ]
  FailedRows <- Manifest[Manifest$status == "failed", , drop=FALSE]

  message(
    "Complete analysis finished: ",
    length(CompletedPdfs),
    " PDF report(s) in ",
    ReportDir
  )
  if(nrow(FailedRows) > 0L){
    warning(
      nrow(FailedRows),
      " report stage(s) failed; see ",
      ManifestFile,
      call.=FALSE
    )
  }

  invisible(list(
    sample_dir=SampleDir,
    report_dir=ReportDir,
    manifest_file=ManifestFile,
    manifest=Manifest,
    pdfs=CompletedPdfs,
    results=Results,
    complete=nrow(FailedRows) == 0L
  ))
}
