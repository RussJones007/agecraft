# Source this file for migrate_age_group_presets(), or use Rscript with paths.
# Preview is the default. --write creates .bak backups and applies safe edits.
migrate_age_group_presets <- function(paths, write = FALSE) {
  results <- list()
  for (path in paths) {
    lines <- readLines(path, warn = FALSE)
    parsed <- parse(text = lines, keep.source = TRUE)
    pd <- utils::getParseData(parsed)
    if (is.null(pd)) next
    # A local binding may be unrelated to the package dataset: flag the file.
    has_binding <- function(x) {
      if (missing(x)) return(FALSE)
      if (!is.call(x) && !is.expression(x) && !is.pairlist(x)) return(FALSE)
      if (is.call(x)) {
        op <- as.character(x[[1L]])[1L]
        if (op %in% c("<-", "=", "<<-") && identical(x[[2L]], as.name("age.groups"))) return(TRUE)
        if (op %in% c("->", "->>") && identical(x[[3L]], as.name("age.groups"))) return(TRUE)
        if (op == "for" && identical(x[[2L]], as.name("age.groups"))) return(TRUE)
        if (op == "function" && "age.groups" %in% names(x[[2L]])) return(TRUE)
      }
      any(vapply(as.list(x), has_binding, logical(1)))
    }
    shadowed <- has_binding(parsed)
    hits <- pd[pd$terminal & pd$text %in% c("age.groups", "`age.groups`"), , drop = FALSE]
    edits <- list()
    for (i in seq_len(nrow(hits))) {
      h <- hits[i, ]
      parent <- pd[pd$parent == h$parent & pd$terminal, , drop = FALSE]
      member <- any(parent$token %in% c("'$'", "'@'"))
      namespace <- parent$text[parent$token == "SYMBOL_PACKAGE"]
      qualified <- length(namespace) > 0L
      reason <- if (member) "member name: review manually" else
        if (qualified && !identical(namespace, "agecraft")) "other package namespace: review manually" else
        if (shadowed && !qualified) "local binding: review manually" else
        if (h$token != "SYMBOL") "non-value symbol: review manually" else "replace"
      replacement <- if (startsWith(h$text, "`")) "`age_group_presets`" else "age_group_presets"
      results[[length(results) + 1L]] <- data.frame(path = path, line = h$line1, column = h$col1,
        before = h$text, after = if (reason == "replace") replacement else h$text, action = reason)
      if (reason == "replace") edits[[length(edits) + 1L]] <- list(h = h, text = replacement)
    }
    # String-based lookups need review; ordinary strings and comments are untouched.
    strings <- pd[pd$terminal & pd$token == "STR_CONST" & grepl("age.groups", pd$text, fixed = TRUE), , drop = FALSE]
    for (i in seq_len(nrow(strings))) {
      h <- strings[i, ]
      results[[length(results) + 1L]] <- data.frame(path = path, line = h$line1, column = h$col1,
        before = h$text, after = h$text, action = "string unchanged: review if dynamic lookup")
    }
    if (write && length(edits)) {
      backup <- paste0(path, ".bak")
      if (file.exists(backup)) stop("Backup already exists: ", backup)
      for (e in rev(edits[order(vapply(edits, function(e) e$h$line1 * 1e6 + e$h$col1, numeric(1)))])) {
        h <- e$h
        line <- lines[h$line1]
        lines[h$line1] <- paste0(substr(line, 1L, h$col1 - 1L), e$text, substring(line, h$col2 + 1L))
      }
      parse(text = lines) # Validate before changing the file.
      if (!file.copy(path, backup)) stop("Could not create backup: ", backup)
      # Preserve the original file's final newline convention.
      original <- readBin(path, "raw", n = file.info(path)$size)
      trailing <- length(original) && utils::tail(original, 1L) == as.raw(10L)
      con <- file(path, "wb")
      tryCatch(writeBin(charToRaw(paste0(paste(lines, collapse = "\n"), if (trailing) "\n" else "")), con),
               finally = close(con))
    }
  }
  if (!length(results)) return(data.frame(path = character(), line = integer(), column = integer(),
                                         before = character(), after = character(), action = character()))
  do.call(rbind, results)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  write <- "--write" %in% args
  paths <- args[args != "--write"]
  if (!length(paths)) stop("Usage: Rscript migrate-age-groups.R [--write] file.R ...")
  print(migrate_age_group_presets(paths, write = write), row.names = FALSE)
}
