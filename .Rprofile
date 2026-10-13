# Activate renv when available (emma image / local project)
if (file.exists("renv/activate.R")) {
  tryCatch(
    source("renv/activate.R"),
    error = function(e) message("renv activate skipped: ", conditionMessage(e))
  )
}
