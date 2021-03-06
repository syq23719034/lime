#' @describeIn lime Method for explaining tabular data
#' @param bin_continuous Should continuous variables be binned when making the explanation
#' @param n_bins The number of bins for continuous variables if `bin_continuous = TRUE`
#' @param quantile_bins Should the bins be based on `n_bins` quantiles or spread evenly over the range of the training data
#' @param kernel_width The width of the kernel used for converting the distances to permutations into weights
#' @importFrom dplyr bind_rows
#' @importFrom stats predict sd quantile
#' @export
#'
#' @examples
#' # Explaining a model based on tabular data
#' if (requireNamespace("caret", quietly = TRUE)) {
#'   library(caret)
#'   iris_test <- iris[1, 1:4]
#'   iris_train <- iris[-1, 1:4]
#'   iris_lab <- iris[[5]][-1]
#'
#'   # Create Random Forest model on iris data
#'   model <- train(iris_train, iris_lab, method = 'rf')
#'
#'   # Create explanation function
#'   expl <- lime(iris_train, model)
#'   expl(iris_test, n_labels = 1, n_features = 2)
#' }
lime.data.frame <- function(x, model, bin_continuous = TRUE, n_bins = 4, quantile_bins = TRUE, kernel_width = NULL, ...) {
  feature_type <- setNames(sapply(x, function(f) {
    if (is.numeric(f)) {
      'numeric'
    } else if (is.character(f)) {
      'character'
    } else if (is.factor(f)) {
      'factor'
    } else {
      stop('Unknown feature type', call. = FALSE)
    }
  }), names(x))
  bin_cuts <- setNames(lapply(seq_along(x), function(i) {
    if (feature_type[i] == 'numeric') {
      if (quantile_bins) {
        quantile(x[[i]], seq(0, 1, length.out = n_bins + 1))
      } else {
        d_range <- range(x[[i]])
        seq(d_range[1], d_range[2], length.out = n_bins + 1)
      }
    }
  }), names(x))
  feature_distribution <- setNames(lapply(seq_along(x), function(i) {
    switch(
      feature_type[i],
      numeric = if (bin_continuous) {
        table(cut(x[[i]], unique(bin_cuts[[i]]), labels = FALSE, include.lowest = TRUE))/nrow(x)
      } else {
        c(mean = mean(x[[i]], na.rm = TRUE), sd = sd(x[[i]], na.rm = TRUE))
      },
      character = ,
      factor = table(x[[i]])/nrow(x)
    )
  }), names(x))
  if (is.null(kernel_width)) {
    kernel_width <- sqrt(ncol(x)) * 0.75
  }
  kernel <- exp_kernel(kernel_width)
  function(cases, labels, n_labels = NULL, n_features, n_permutations = 5000, dist_fun = 'euclidean', feature_select = 'auto') {
    case_perm <- permute_cases(cases, n_permutations, feature_distribution, bin_continuous, bin_cuts)
    case_res <- predict(model, case_perm, type = 'prob')
    case_ind <- split(seq_len(nrow(case_perm)), rep(seq_len(nrow(cases)), each = n_permutations))
    res <- lapply(seq_along(case_ind), function(ind) {
      i <- case_ind[[ind]]
      perms <- numerify(case_perm[i, ], feature_type, bin_continuous, bin_cuts)
      dist <- c(0, dist(feature_scale(perms, feature_distribution, feature_type, bin_continuous),
                        method = dist_fun)[seq_len(n_permutations-1)])
      res <- model_permutations(as.matrix(perms), case_res[i, ], kernel(dist), labels, n_labels, n_features, feature_select)
      res$feature_value <- unlist(case_perm[i[1], res$feature])
      res$feature_desc <- describe_feature(res$feature, case_perm[i[1], ], feature_type, bin_continuous, bin_cuts)
      guess <- which.max(abs(case_res[i[1], ]))
      res$case <- rownames(cases)[ind]
      res$label_prob <- unname(as.matrix(case_res[i[1], ]))[match(res$label, names(case_res))]
      res$data <- list(as.list(case_perm[i[1], ]))
      res$prediction <- list(as.list(case_res[i[1], ]))
      res
    })
    res <- bind_rows(res)
    res[, c('case', 'label', 'label_prob', 'model_r2', 'model_intercept', 'feature', 'feature_value', 'feature_weight', 'feature_desc', 'data', 'prediction')]
  }
}
#' @importFrom stats setNames
numerify <- function(x, type, bin_continuous, bin_cuts) {
  setNames(as.data.frame(lapply(seq_along(x), function(i) {
    if (type[i] %in% c('character', 'factor')) {
      as.numeric(x[[i]] == x[[i]][1])
    } else {
      if (bin_continuous) {
        cuts <- bin_cuts[[i]]
        cuts[1] <- -Inf
        cuts[length(cuts)] <- Inf
        xi <- cut(x[[i]], unique(cuts), include.lowest = T)
        as.numeric(xi == xi[1])
      } else {
        x[[i]]
      }
    }
  }), stringsAsFactors = FALSE), names(x))
}
#' @importFrom stats setNames
feature_scale <- function(x, distribution, type, bin_continuous) {
  setNames(as.data.frame(lapply(seq_along(x), function(i) {
    if (type[i] == 'numeric' && !bin_continuous) {
      scale(x[, i], distribution[[i]]['mean'], distribution[[i]]['sd'])
    } else {
      x[, i]
    }
  }), stringsAsFactors = FALSE), names(x))
}
describe_feature <- function(feature, case, type, bin_continuous, bin_cuts) {
  sapply(feature, function(f) {
    if (type[[f]] %in% c('character', 'factor')) {
      paste0(f, ' = ', as.character(case[[f]]))
    } else if (bin_continuous) {
      cuts <- bin_cuts[[f]]
      cuts[1] <- -Inf
      cuts[length(cuts)] <- Inf
      bin <- cut(case[[f]], unique(cuts), labels = FALSE, include.lowest = TRUE)
      cuts <- trimws(format(cuts, digits = 3))
      if (bin == 1) {
        paste0(f, ' <= ', cuts[bin + 1])
      } else if (bin == length(cuts) - 1) {
        paste0(cuts[bin], ' < ', f)
      } else {
        paste0(cuts[bin], ' < ', f, ' <= ', cuts[bin + 1])
      }
    } else {
      f
    }
  })
}
