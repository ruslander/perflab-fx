input <- read.csv(
  text = "TAB_SPEC_NX", 
  header=TRUE, 
  sep=",")

# Take a look at raw data
print("Raw input data")
print(input)
plot(input$N, input$X, type="b",main="Raw data")

# Normalize them datas ...
input$Norm <- input$X/input$X[1]
# Take a gander at it ...
print("Normalized data")
print(input)

#*****************************************
# Added by NJG on Thu Aug 20 09:30:14 2009
# Check for efficiencies > 100%
input$Effic <- input$Norm/input$N
if(any(input$Effic > 1)) { 
  print(input)
  stop("Over achievers: Some efficiencies > 100%")
} else {
  # Standard non-linear least squares (NLS) fit using USL model
  usl <- nls(Norm ~ N/(1 + alpha * (N-1) + beta * N * (N-1)), input, start=c(alpha=0.1, beta=0.01))
  
  # Look at the fitted USL parameters (alpha,beta)
  coef(usl)
  
  # Check statistical parameters
  summary(usl)
  
  # Get alpha & beta parameters for use in plot legend
  x.coef <- coef(usl)

  print("USL coeficients")
  print(x.coef)
  
  # Determine sum-of-squares for R-squared coeff from NLS fit
  sse <- sum((input$Norm - predict(usl))^2)
  sst <- sum((input$Norm - mean(input$Norm))^2)
  
  # Calculate Nmax and X(Nmax)
  Nmax<-sqrt((1-x.coef["alpha"])/abs(x.coef["beta"]))
  Xmax<-input$X[1]* Nmax/(1 + x.coef["alpha"] * (Nmax-1) + x.coef["beta"] * Nmax * (Nmax-1))
  Xroof<-input$X[1]/x.coef["alpha"]
  Nopt <- abs(1 / x.coef["alpha"])

  png(file ="/tmp/rplot-file.jpg", width = 1400, height = 800, units = "px", pointsize = 25)
  
  # Plot all the results
  plot(x<-c(0:max(input$N)), input$X[1] * x/(1 + x.coef["alpha"] * (x-1) + x.coef["beta"] * x * (x-1)), 
       type="l",lty="dashed",lwd=3, ylab="Throughput X(N)", xlab="Virtual Users (N)", col="red")

  abline(v=Nopt, col="gray")
  #abline(h=Xroof, col="gray")
  abline(a=0, b=Xroof/Nopt, col="gray")
  abline(v=Nmax, col="red")
  abline(h=Xmax, col="red")

  if(x.coef["alpha"] > 0 && x.coef["beta"] > 0){
    title("Negative returns from incoherency")
  }

  if(x.coef["alpha"] > 0 && x.coef["beta"] == 0){
    title("Cost of sharing resources, diminishing returns from contention")
  }

  if(x.coef["alpha"] == 0 && x.coef["beta"] == 0){
    title("Equal bang for the buck")
  }

  points(input$N, input$X)
  legend("bottom", legend=eval(parse(text=sprintf(
    "expression(alpha == %.4f, beta == %.6f, R^2 == %.4f, Nmax==%.2f, Xmax==%.2f,Xroof==%.2f,Z(sec)==%.2f,TS==%15s)",
    x.coef["alpha"], x.coef["beta"], 1-sse/sst, Nmax, Xmax, Xroof, 0.0, 
    format(Sys.time(),"%d%m%y%H%M") ))), ncol=2)
  
  dev.off()  
}

print("Done")