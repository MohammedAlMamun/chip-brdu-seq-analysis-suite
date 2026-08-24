# Contributing and support

This release candidate is primarily maintained for laboratory analysis and collaborative testing.

## Bug reports

Before opening an Issue:

1. Confirm the problem occurs with the current release candidate.
2. Confirm the complete matching support bundle is installed.
3. Reduce the report to one function call where possible.
4. Remove confidential sample names and filesystem details.

Include the exact function call, full error message, operating-system and R versions, assay/alignment/strand settings, and relevant result filenames. For complete analysis, attach the concise manifest if it contains no sensitive information.

## Proposed changes

Open an Issue before a substantial pull request so the scientific behavior, output compatibility and public function interface can be agreed first. Changes should preserve:

- saved ratio-table semantics;
- baseline interpretation;
- script-relative support paths;
- separation of analysis from graphical smoothing; and
- backward compatibility of established public arguments where practical.

Do not commit FASTQs, BAMs, sample results, generated reference indexes or other large experimental files.
