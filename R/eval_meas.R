###################################################################################
#' Category level prediction
#'
#' Predicts category levels from an MCA based biplot using the distances between coordinates
#'
#' @param CLPs Category level point coordinates
#' @param Zs Sample coordinates
#' @param p Number of variables
#' @param n Number of samples
#' @param lvls Names of category levels
#' @param datIN Input data from which `CLPs` and `Zs` are obtained
#'
#' @return
#' \item{predCL}{Final predicted categorical data set}
#' 
#' @export
#'
CLPpred <- function (CLPs=CLPs, Zs=Zs, p=p, n=n, lvls=lvls, datIN = datIN)
{
  X.pred <- as.data.frame(matrix(0,n,p))
  X.pred <- df2fact(X.pred)
  
  vec.lvl <- vector("numeric",p)
  for (j in 1:p)
  {
    vec.lvl[j] <- length(levels(delCL(datIN)[,j]))
  }
  cumlvl <- cumsum(vec.lvl)
  
  for (i in 1:n)
  {
    d <- as.matrix(as.matrix(stats::dist(rbind(Zs[i,],CLPs)))[1,-1]) #distance matrix between first row of Z.list[[i]][1,] and all rows of CLP.list[[i]] (distances for first sample over all variables)
    pluggin <- matrix(0,p,1)
    inds <- matrix(0,p,1)
    for(j in 1:p)
    {
      if(j==1)
      {
        if(length(j:cumlvl[j])==1)
        {inds[j] <- 1
        } else
        {
          pluggin[j] <- min(d[j:cumlvl[j]])
          inds[j] <- which(d[j:cumlvl[j]]==min(d[j:cumlvl[j]]),arr.ind=TRUE)
        }
      }else
      {
        if(length((cumlvl[j-1]+1):cumlvl[j])==1)
        {inds[j] <- 1
        }else
        {pluggin[j] <- min(d[(cumlvl[j-1]+1):cumlvl[j]])
        inds[j] <- which(d[(cumlvl[j-1]+1):cumlvl[j]]==min(d[(cumlvl[j-1]+1):cumlvl[j]]),arr.ind=TRUE)
        }
      }
      levels(X.pred[,j]) <- levels(delCL(datIN)[,j])
      place <- inds[j]
      X.pred[i,j] <- levels(X.pred[,j])[place]
    }
  }
  inds.NNA <- which(!is.na(datIN), arr.ind=T)
  X.pred[inds.NNA] <- datIN[inds.NNA]#replaces non missing with original categories
  #X.pred <- FormatDimNam(X.pred)
  
  return(predCL = X.pred)
  
}
###################################################################################
#' Evaluation measures when complete data is available
#'
#' Calculates measures of comparison based on distances between two configurations
#' 
#' @param missbp An object of class \code{missbp} obtained from preceding function \code{missmi()}.
#' @param compdat Complete data matrix representing the input data of \code{missmi()}
#' @param dim Compare the configurations in 2D or the maximum available ("All") dimensions, default is `2D`.
#'
#' @return
#' \item{eval}{Returns a data table with five evaluation measures: Procrustes Statistic (PS), Similarity Proportion (SP), Response Profile Recovery (RPR), Absolute Mean Bias (AMB), Root Mean Squared Bias (RMSB)}
#' 
#' @export
#'
#' @examples
#' \donttest{
#' data(compdat)
#' data(implist)
#' missbp <- missmi(implist) |> DRT() |> GPAbin() |> evalMeas(compdat=compdat, dim="2D")}
#'
evalMeas <- function (missbp, compdat=NULL, dim=c("All", "2D"))
{
  if(is.null(compdat)) stop("No complete data set available for comparison. \nThis function is only applicable for simulated data.")

  p <- missbp$p
  n <- missbp$n
  
  tempcomp <- OPA(missbp, compdat)
  PS <- tempcomp[[1]]
  RMSB <- tempcomp[[2]]
  AMB <- tempcomp[[3]]
  
  compPred <- CLPpred(CLPs=tempcomp$compCLP, Zs=tempcomp$compZ, p=ncol(compdat), n=nrow(compdat), lvls=tempcomp$complvls, datIN = compdat)
  if(is.data.frame(missbp$X)) 
    {
    datIN <- df2fact(missbp$X)
    } else 
    {
      datIN <- df2fact(missbp$X[[1]])
      }
  GPAPred <-  CLPpred(CLPs=missbp$CLP.GPAbin,Zs=missbp$Z.GPAbin, p=missbp$p, n=missbp$n, lvls=missbp$lvlv[[1]], datIN=datIN)
  
  match.count <- sum(mapply(as.character,compPred)==mapply(as.character,GPAPred))
  
  SP <- match.count/(p*n)

  comp_flat <- apply(compPred,1,stringr::str_flatten)
  imp_flat <- apply(GPAPred,1,stringr::str_flatten)
  
  RPR <- sum(comp_flat == imp_flat)/nrow(compPred)

  EVALtable <- data.frame(c(PS, SP, RPR, AMB, RMSB))
  colnames(EVALtable)<- c("Evaluation measures")
  rownames(EVALtable)<- c("PS","SP","RPR", "AMB", "RMSB")
  
  missbp$eval <- round(EVALtable,4)
  missbp$GPApred <-GPAPred
  missbp$compPred <- compPred
  
  missbp
}
