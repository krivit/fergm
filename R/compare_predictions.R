#' Compare predictions of ERGM to FERGM.
#'
#' This function allows you to assess the importance of the frailty term in prediction by comparing the predictive accuracy of an ERGM to an FERGM.
#' @param ergm.fit A model object returned by the \code{ergm} function.  Must be specified.
#' @param fergm.fit A model object returned by the \code{fergm} function.  Must be specified.
#' @param net This is the network object that the ERGM and FERGM were fit on.  This network object must be in the global environment.  Must be specified.
#' @param seed An integer that sets the seed for the random number generator to assist in replication.  Defaults to a null value for no seed setting.
#' @param replications The number of networks to be simulated to assess predictions. Defaults to 500.
#' @keywords Fit GOF Prediction.
#' @references Box-Steffensmeier, Janet M., Dino P. Christenson, and Jason W. Morgan. 2018. ``Modeling Unobserved Heterogeneity in Social Networks with the Frailty Exponential Random Graph Model." \emph{Political Analysis}. (26)1:3-19.
#' @references Stan Development Team (2016). RStan: the R interface to Stan. R package version 2.14.1. \url{http://mc-stan.org/}.
#' @return The compare_predictions function returns a matrix reflecting the number of correctly predicted ties for the ERGM and FERGM for each network simulated.
#' @examples
#' # load example data
#' data("ergm.fit")
#' data("fergm.fit")
#' data("mesa")
#'
#' # Use built in compare_predictions function to compare predictions of ERGM and FERGM,
#' # few replications due to example
#' predict_out <- compare_predictions(ergm.fit = ergm.fit, fergm.fit = fergm.fit,
#'                                    net = mesa, replications = 10, seed=12345)
#'
#' # Use the built in compare_predictions_plot function to examine the densities of
#' #  correctly predicted ties from the compare_predictions simulations
#' compare_predictions_plot(predict_out)
#'
#' # We can also conduct a KS test to determine if the FERGM fit
#'      # it statistically disginguishable from the ERGM fit
#' compare_predictions_test(predict_out)
#' @export

compare_predictions <- function(ergm.fit = NULL, fergm.fit = NULL, net = NULL, seed = NULL, replications = 500){

  if(!is.null(seed)){
    set.seed(seed)
  } else {
    warning("Note: This function relies upon network simulation to compare ERGM and FERGM predictions.  Consider specifying a seed to set to ensure replicability.")
  }

  lt <- function(m) { m[lower.tri(m)] }
  n_dyads <- choose(ergm.fit$network$gal$n, 2)

  new_formula <- stats::update.formula(ergm.fit$formula, net ~ .)
  ergm_coefs <- ergm.fit$coef

  ergm.pred <- function()
  {
    flo.truth <- lt(as.matrix(ergm.fit$network))
    sim.pred <- lt(as.matrix(simulate(ergm.fit)))
    sum(flo.truth == sim.pred) / n_dyads
  }


  pct_correct_ergm <- replicate(replications, ergm.pred())

  stan.dta <- fergm.fit$stan.dta
  stan.fit <- fergm.fit$stan.fit

  truth <- stan.dta$y
  predictions <- extract(stan.fit, "predictions")$predictions

  pct_correct_fergm <- sapply(1:nrow(predictions),
                              function(r) sum(truth == predictions[r,]) / n_dyads)


  correct_mat <- cbind(pct_correct_ergm, pct_correct_fergm)

  improvement <- round(((mean(pct_correct_fergm)-mean(pct_correct_ergm))/mean(pct_correct_ergm))*100, 2)

  cat(paste0("The FERGM fit reflects a ", improvement, "% improvement in tie prediction relative to the ERGM across ", replications, " simulations"))

  return(correct_mat)
}
