# Apply USL model to scalability measurements
# See http://www.perfdynamics.com/Manifesto/USLscalability.html
# Created by Neil Gunther on Tue May 19 2009

# Read in the raw data from the file
fname<-"USLcalc-data.txt" 	# Example data filename
dir<-"data"				# Your dir path here
fullname<-paste(dir, fname, sep = "/")
if(is.character(fullname) != TRUE) { print("Bad file name") }
input <- read.table(fullname, header=TRUE)

# Take a look at raw data
print("Raw input data")
print(input)
plot(input$N, input$X_N, type="b",main="Raw data")

# Normalize them datas ...
input$Norm <- input$X_N/input$X_N[1]
# Take a gander at it ...
print("Normalized data")
print(input)

#*****************************************
# Added by NJG on Thu Aug 20 09:30:14 2009
# Check for efficiencies > 100%
input$Effic <- input$Norm/input$N
if(any(input$Effic > 1)) { 
  print(input)
  print("Over achievers: Some efficiencies > 100%")
  stop()
}
#*****************************************


# Standard non-linear least squares (NLS) fit using USL model
usl <- nls(Norm ~ N/(1 + alpha * (N-1) + beta * N * (N-1)), input, start=c(alpha=0.1, beta=0.01))

# Look at the fitted USL parameters (alpha,beta)
coef(usl)

# Check statistical parameters
summary(usl)

# Get alpha & beta parameters for use in plot legend
x.coef <- coef(usl)

# Determine sum-of-squares for R-squared coeff from NLS fit
sse <- sum((input$Norm - predict(usl))^2)
sst <- sum((input$Norm - mean(input$Norm))^2)

# Calculate Nmax and X(Nmax)
Nmax<-sqrt((1-x.coef['alpha'])/x.coef['beta'])
Xmax<-input$X_N[1]* Nmax/(1 + x.coef['alpha'] * (Nmax-1) + x.coef['beta'] * Nmax * (Nmax-1))

# Plot all the results
plot(x<-c(0:max(input$N)), input$X_N[1] * x/(1 + x.coef['alpha'] * (x-1) + x.coef['beta'] * x * (x-1)), type="l",lty="dashed",lwd=1, ylab="Throughput X(N)", xlab="Virtual Users (N)")
title("USL Scalability")
points(input$N, input$X_N)
legend("bottom", legend=eval(parse(text=sprintf(
  "expression(alpha == %.4f, beta == %.6f, R^2 == %.4f, Nmax==%.2f, Xmax==%.2f,Xroof==%.2f,Z(sec)==%.2f,TS==%15s)",
  x.coef['alpha'], x.coef['beta'], 1-sse/sst, Nmax, Xmax, input$X_N[1]/x.coef['alpha'], 0.0, 
  format(Sys.time(),"%d%m%y%H%M") ))), ncol=2)