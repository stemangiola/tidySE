#' Coerce lists, matrices, and more to data frames
#'
#' @description
#' `r lifecycle::badge("maturing")`
#'
#' `as_tibble()` turns an existing object, such as a data frame or
#' matrix, into a so-called tibble, a data frame with class [`tbl_df`]. This is
#' in contrast with [tibble()], which builds a tibble from individual columns.
#' `as_tibble()` is to [`tibble()`] as [base::as.data.frame()] is to
#' [base::data.frame()].
#'
#' `as_tibble()` is an S3 generic, with methods for:
#' * [`data.frame`][base::data.frame()]: Thin wrapper around the `list` method
#'   that implements tibble's treatment of [rownames].
#' * [`matrix`][methods::matrix-class], [`poly`][stats::poly()],
#'   [`ts`][stats::ts()], [`table`][base::table()]
#' * Default: Other inputs are first coerced with [base::as.data.frame()].
#'
#' @section Row names:
#' The default behavior is to silently remove row names.
#'
#' New code should explicitly convert row names to a new column using the
#' `rownames` argument.
#'
#' For existing code that relies on the retention of row names, call
#' `pkgconfig::set_config("tibble::rownames"=NA)` in your script or in your
#' package's [.onLoad()]  function.
#'
#' @section Life cycle:
#' Using `as_tibble()` for vectors is superseded as of version 3.0.0,
#' prefer the more expressive maturing `as_tibble_row()` and
#' `as_tibble_col()` variants for new code.
#'
#' @seealso [tibble()] constructs a tibble from individual columns. [enframe()]
#'   converts a named vector to a tibble with a column of names and column of
#'   values. Name repair is implemented using [vctrs::vec_as_names()].
#'
#' @param x A data frame, list, matrix, or other object that could reasonably be
#'   coerced to a tibble.
#' @param ... Unused, for extensibility.
#' @param rownames How to treat existing row names of a data frame or matrix:
#'   * `NULL`: remove row names. This is the default.
#'   * `NA`: keep row names.
#'   * A string: the name of a new column. Existing rownames are transferred
#'     into this column and the `row.names` attribute is deleted.
#'  Read more in [rownames].
#' @param .name_repair see tidyr
#'
#'   For compatibility only, do not use for new code.
#' @return A tibble
#'
#' @export
#' @examples
#' tidySE::pbmc_small %>%
#'     tidy() %>%
#'     as_tibble()
as_tibble <- function(x, ...,
    .name_repair=c("check_unique", "unique", "universal", "minimal"),
    rownames=pkgconfig::get_config("tibble::rownames", NULL)) {
    UseMethod("as_tibble")
}

#' @export
as_tibble.default <- function(x, ...,
    .name_repair=c("check_unique", "unique", "universal", "minimal"),
    rownames=pkgconfig::get_config("tibble::rownames", NULL)) {
    tibble::as_tibble(x, ...,
        .name_repair=.name_repair,
        rownames=rownames
    )
}

#' @export
#' @importFrom purrr reduce
#' @importFrom purrr map
#' @importFrom tidyr spread
#' @importFrom tibble enframe
#'
#'
as_tibble.tidySE <- function(x, ...,
    .name_repair=c("check_unique", "unique", "universal", "minimal"),
    rownames=pkgconfig::get_config("tibble::rownames", NULL)) {

    sample_info =
        x@colData %>%
        as.data.frame %>%

        # Convert to tibble
        tibble::as_tibble(rownames="sample")

    # range_info =
    #     x@rowRanges %>%
    #     as.data.frame %>%
    #     tibble::as_tibble(rownames="transcript")

    range_info =
        get_special_datasets(x) %>%
        reduce(left_join, by="transcript")

    gene_info =
        rowData(x) %>%
        as.data.frame %>%

        # Convert to tibble
        tibble::as_tibble(rownames="transcript")

    count_info = get_count_datasets(x)

    sample_info %>%
        left_join(count_info, by="sample") %>%
        left_join(gene_info, by="transcript") %>%
        when(nrow(range_info) > 0 ~ (.) %>% left_join(range_info, by="transcript"), ~ (.))



}
