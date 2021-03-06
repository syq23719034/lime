// Generated by using Rcpp::compileAttributes() -> do not edit by hand
// Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

#include "lime_types.h"
#include <RcppEigen.h>
#include <Rcpp.h>

using namespace Rcpp;

// rowSumsSq
NumericVector rowSumsSq(MSpMat sparse_matrix);
RcppExport SEXP lime_rowSumsSq(SEXP sparse_matrixSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< MSpMat >::type sparse_matrix(sparse_matrixSEXP);
    rcpp_result_gen = Rcpp::wrap(rowSumsSq(sparse_matrix));
    return rcpp_result_gen;
END_RCPP
}
// get_index_permutations
List get_index_permutations(IntegerVector original_document, int number_permutations);
RcppExport SEXP lime_get_index_permutations(SEXP original_documentSEXP, SEXP number_permutationsSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< IntegerVector >::type original_document(original_documentSEXP);
    Rcpp::traits::input_parameter< int >::type number_permutations(number_permutationsSEXP);
    rcpp_result_gen = Rcpp::wrap(get_index_permutations(original_document, number_permutations));
    return rcpp_result_gen;
END_RCPP
}
