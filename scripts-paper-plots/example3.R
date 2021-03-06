###################################################################################
###################################################################################
#
# Makes plots from the run of the files 
# scripts-paper/example3-gposmc.py and scripts-paper/example3-gpoabc.py
# The plots are of the volatility estimate and the correlation of the filtered
# residuals. The Value-At-Risk of the corresponding portfolio is also computed.
#
#
# For more details, see https://github.com/compops/gpo-abc2015
#
# (c) 2016 Johan Dahlin
# liu (at) johandahlin.com
#
###################################################################################
###################################################################################


library("stabledist")
library("copula")
library("RColorBrewer")
plotColors <- brewer.pal(8, "Dark2")

# Change the working directory to be correct on your system
# setwd("C:/home/src/gpo-abc2015/scripts-paper-plots")


###################################################################################
# Get the data and compute the probability transformed residuals
###################################################################################

# Load Value-at-Risk estimates
VaRABC <- read.table("../results-paper/example3/example3-gpoabc-var.csv", header = TRUE, 
                     sep = ",", stringsAsFactors = FALSE)
VaRSMC <- read.table("../results-paper/example3/example3-gposmc-var.csv", header = TRUE, 
                     sep = ",", stringsAsFactors = FALSE)

# Load state (log-volatility) estimates
xhat <- read.table("../results-paper/example3/example3-gpoabc-volatility.csv", header = TRUE, sep = ",")
xhat2 <- read.table("../results-paper/example3/example3-gposmc-volatility.csv", header = TRUE, sep = ",")

# Load log-returns
y <- read.table("../results-paper/example3/example3-gpoabc-returns.csv", header = TRUE, sep = ",")

# Load estimates of model parameters
m <- read.table("../results-paper/example3/example3-gpoabc-model.csv", header = TRUE, sep = ",")
m2 <- read.table("../results-paper/example3/example3-gposmc-model.csv", header = TRUE, sep = ",")

T <- dim(y)[1]
nAssets <- dim(y)[2] - 1

# Compute filtered returns and their probability transformation
yfilt <- matrix(0, nrow = T, ncol = nAssets)
yprob <- matrix(0, nrow = T, ncol = nAssets)

for (ii in 1:nAssets)
{
  yfilt[, ii] <- y[, ii + 1] * exp(-0.5 * xhat[, ii + 1])
  yprob[, ii] <- pobs(yfilt[, ii])
}


###################################################################################
# Compute approximate 95% confidence intervals for log-returns using
# simulation The stability parameters are inferred in the GPO-step
###################################################################################

CI <- array(0, dim = c(nAssets, T, 2))
alpha <- as.numeric(m[4, -1])

for (ii in 1:nAssets)
{
  for (tt in 1:T)
  {
    CI[ii, tt, ] <- qstable(c(0.025, 0.975), alpha[ii], 0, exp(0.5 * 
                                                                 xhat[tt, ii + 1]), 0)
  }
}


###################################################################################
# Make the plots for the copula model
###################################################################################

asset_names <- c("brent", "dubai", "maya")

log_ret_label <- matrix("", nrow = nAssets)
par_name <- matrix("", nrow = nAssets * (nAssets - 1)/2, ncol = 2)
comp_idx <- matrix(0, nrow = nAssets * (nAssets - 1)/2, ncol = 2)

kk <- 1
for (ii in 1:nAssets)
{
  log_ret_label[ii] <- paste(paste("log-returns (", asset_names[ii], 
                                   ")", sep = ""))
  
  for (jj in (ii + 1):nAssets)
  {
    if (ii < nAssets)
    {
      comp_idx[kk, ] <- c(ii, jj)
      par_name[kk, ] <- c(asset_names[ii], asset_names[jj])
      kk <- kk + 1
    }
  }
}

cairo_pdf("example3-copula.pdf", height = 10, width = 8)

grid <- as.Date(y$Date, "%Y-%m-%d")

layout(matrix(c(1, 1, 2, 3, 3, 4, 5, 5, 6), 3, 3, byrow = TRUE))
par(mar = c(4, 4, 1, 4.5))

for (ii in 1:nAssets)
{
  
  plot(grid, as.numeric(y[,ii+1]), col = plotColors[ii], type = "l", main = "", 
       bty = "n", xlab = "date", ylab = log_ret_label[ii], ylim = c(-25, 25), 
       cex.lab = 0.75, cex.axis = 0.75, lwd = 0.75)
  
  polygon(c(grid, rev(grid)), c(CI[ii, , 1], rev(CI[ii, , 2])), border = NA, 
          col = rgb(t(col2rgb(plotColors[ii]))/256, alpha = 0.15))
  
  par(new = TRUE)
  plot(grid, xhat[, ii + 1], lwd = 1, col = "grey30", type = "l", xaxt = "n", 
       yaxt = "n", xlab = "", ylab = "", bty = "n", ylim = c(0, 7))
  
  axis(4, cex.axis = 0.75)
  mtext("smoothed log-volatility", side = 4, line = 3, cex = 0.5)
  
  plot(yprob[, comp_idx[ii, 1]], yprob[, comp_idx[ii, 2]], pch = 19, 
       cex = 0.5, xlab = par_name[ii, 1], ylab = par_name[ii, 2], bty = "n", 
       col = "darkgrey", cex.lab = 0.75, cex.axis = 0.75)
  
}

dev.off()


################################################################################### 
# Make the plot for the Value-at-Risk estimate
###################################################################################

cairo_pdf("example3-portfolio.pdf", height = 3, width = 8)

layout(matrix(1, 1, 1, byrow = TRUE))
par(mar = c(4, 4, 0, 0))

plot(grid, rowMeans(y[, -1]), pch = 19, col = "darkgrey", bty = "n", ylab = "log-returns", 
     xlab = "time", cex = 0.5, ylim = c(-20, 50), xaxt = "n", cex.lab = 0.75, 
     cex.axis = 0.75)

atVector1 <- seq(grid[1], grid[T], by = "1 years")
axis.Date(1, grid, atVector1, labels = NA, cex.lab = 0.75, cex.axis = 0.75)

atVector2 <- seq(grid[1], grid[T], by = "3 years")
axis.Date(1, grid, atVector2, format = "%Y", cex.lab = 0.75, cex.axis = 0.75)

lines(grid[seq(10, T)], -rowMeans(VaRABC[, -1])[10:T], col = plotColors[4], 
      lwd = 1.5)

lines(grid[seq(10, T)], -rowMeans(VaRSMC[, -1])[10:T], col = plotColors[5], 
      lwd = 1.5)

abline(v = grid[round(2 * T/3)], lty = "dashed")

dev.off()

# Get the number of violations
Test <- round(2 * T/3)
sum(rowMeans(VaRSMC[, -1])[Test:T] > rowMeans(y[Test:T, -1]))
sum(rowMeans(VaRABC[, -1])[Test:T] > rowMeans(y[Test:T, -1]))


###################################################################################
###################################################################################
# End of file
###################################################################################
###################################################################################
