# File: 01_EDA_metabolomics.R
# Auth: umar.niazi@kcl.ac.uk
# Date: 25/7/2022
# Desc: EDA for the treat metabolite matrix

#### rerun of the old EDA (see scratch project directory) with new changes 
## load the data
dfData = read.csv(file.choose(), header=T, stringsAsFactors = F)

## create matrix of covariates
x = strsplit(dfData$Sample, ' ')
fTreatment = rep(NA, times=nrow(dfData))
fSubjectID = rep(NA, times=nrow(dfData))
fTime = rep(NA, times=nrow(dfData))

for (i in 1:length(x)){
  if (length(x[[i]]) > 2){
    fTreatment[i] = 'HC'
    fSubjectID[i] = x[[i]][2]
    fTime[i] = x[[i]][3]
  } else {
    fTreatment[i] = 'Tr'
    fSubjectID[i] = x[[i]][1]
    fTime[i] = x[[i]][2]
  }
}

## to avoid confusion shorten the names for subject IDs
fSubjectID = gsub('TREAT', 'TR', fSubjectID)

dfSample = data.frame(Code=dfData$Code, Sample=dfData$Sample, 
                      fSubjectID=factor(fSubjectID), 
                      fTreatment=factor(fTreatment), 
                      fTime=factor(fTime, levels = c('BL', '12W', '36W', '60W')))

mData = as.matrix(dfData[,-c(1,2)])
rownames(mData) = dfSample$Code

lData.train = list(data=mData, sample=dfSample)
# lData.train$sample$fTime = relevel(lData.train$sample$fTime, ref = 'BL')
iTime = rep(1, times=nrow(lData.train$sample))
iTime[lData.train$sample$fTime == '12W'] = 12
iTime[lData.train$sample$fTime == '36W'] = 36
iTime[lData.train$sample$fTime == '60W'] = 60
lData.train$sample$iTime = iTime
rm(dfData)
rm(mData)
rm(dfSample)
#################################################################
### diagnostics on the data
library(downloader)
url = 'https://raw.githubusercontent.com/uhkniazi/CDiagnosticPlots/experimental/CDiagnosticPlots.R'
download(url, 'CDiagnosticPlots.R')

# load the required packages
source('CDiagnosticPlots.R')
# delete the file after source
unlink('CDiagnosticPlots.R')

table(lData.train$data == 0)

# how many zeros per metabolite
z = apply(lData.train$data, 2, function(x) sum(x == 0))
z[z > 0]
hist(z[z > 0])
z[z > 10]

# how many zeros per sample
z = apply(lData.train$data, 1, function(x) sum(x == 0))
z[z > 0]
hist(z[z > 0])
z[z > 5]
iZeros = z
## do not impute on this analysis 
# # impute the average for missing zeros
# mData = lData.train$data
# mData = apply(mData, 2, function(x){
#   i = which(x == 0)
#   if (length(i) > 0){
#     x[i] = mean(x)
#   }
#   return(x)
# })
mData = log(lData.train$data+1)
oDiag = CDiagnosticPlots(t(mData), 'log data')

fBatch = lData.train$sample$fTreatment
# fBatch = rep('Z', times=nrow(lData.train$sample))
fBatch = cut(iZeros, breaks = c(0, 1, 2, 4, max(iZeros)), include.lowest = T)
fBatch = lData.train$sample$fTime
# fBatch[iZeros <= 3] = 'NZ'
# fBatch = factor(fBatch)
levels(fBatch)
table(fBatch)
boxplot.median.summary(oDiag, fBatch, axis.label.cex = 0.1)
plot.mean.summary(oDiag, fBatch, axis.label.cex = 0.1)
plot.sigma.summary(oDiag, fBatch, axis.label.cex = 0.1)
plot.missing.summary(oDiag, fBatch, axis.label.cex = 0.1, cex.main=1)
plot.PCA(oDiag, fBatch, cex.main=1, csLabels = '')
plot.dendogram(oDiag, fBatch, labels_cex = 0.8, cex.main=0.7)
## change parameters 
l = CDiagnosticPlotsGetParameters(oDiag)
l$PCA.jitter = F
l$HC.jitter = F
oDiag = CDiagnosticPlotsSetParameters(oDiag, l)
plot.PCA(oDiag, fBatch, legend.pos = 'bottomright', csLabels = lData.train$sample$fSubjectID, labels.cex = 0.8)
plot.dendogram(oDiag, fBatch, labels_cex = 0.7)
plot.heatmap(oDiag)
plot.PCA(oDiag, fBatch, legend.pos = 'bottomright', 
         csLabels = lData.train$sample$fTreatment:lData.train$sample$fTime, labels.cex = 0.8)


plot(oDiag@lData$PCA$sdev)
####### some random plots
library(lattice)
df = data.frame(oDiag@lData$PCA$x[,1:2])
df = stack(df)
df = cbind(df, lData.train$sample)

xyplot(values ~ iTime | fSubjectID, data=df, groups=ind, auto.key = T, 
       type=(c('g', 'p', 'l')))


bwplot(values ~ fTime | fTreatment, data=df, groups=ind, auto.key = T,
       panel = panel.violin, type='b')
       
xyplot(values ~ fTime | fTreatment, data=df, groups=ind, auto.key = T,
       type='p')


dotplot(values ~ fTime | fTreatment, data=df, groups=df$ind,
        panel=function(x, y, ...) panel.bwplot(x, y, pch='|',...), type='b',
        par.strip.text=list(cex=0.7), scales=list(relation='free', x=list(cex=0.7), y=list(cex=0.7)))


# ## make ~12 at a time
# # impute the average for missing zeros
# mData = lData.train$data
# mData = apply(mData, 2, function(x){
#   i = which(x == 0)
#   if (length(i) > 0){
#     x[i] = mean(x)
#   }
#   return(x)
# })
# 
# iCut = cut(1:117, breaks = 10, include.lowest = T, labels = 1:10)
# dfCut = data.frame(iCut, x=1:117)
# tapply(dfCut$x, dfCut$iCut, function(x){
#   df = stack(data.frame(log(mData[,x])))
#   df = cbind(df, lData.train$sample)
#   print(xyplot(values ~ iTime | ind, groups=fTreatment, data=df, type=(c('g', 'p', 'r')),
#                scales=list(relation='free'), auto.key = list(columns=2), pch=20, cex=0.5)
#   )
# })
# 
# ## time as categorical
# tapply(dfCut$x, dfCut$iCut, function(x){
#   df = stack(data.frame(log(mData[,x])))
#   df = cbind(df, lData.train$sample)
#   print(xyplot(values ~ fTime | ind, groups=fTreatment, data=df, type=(c('g', 'p', 'r')),
#                scales=list(relation='free'), auto.key = list(columns=2), pch=20, cex=0.5)
#   )
# })

######################################
###### merge the replicated samples i.e. technical replicates
mData = lData.train$data
dfSample = lData.train$sample
fRep = dfSample$fSubjectID:dfSample$fTime
nlevels(fRep)
table(fRep)

# combine the technical replicates
i = seq_along(1:nrow(mData))
m = tapply(i, fRep, function(x) {
  return(x)
})

m[sapply(m, is.null)] = NULL

mData = sapply(m, function(x){
  if (length(x) == 1) return(mData[x,])
  return(colMeans(mData[x,]))
})

mData = t(mData)
dim(mData)
dfSample$fReplicates = droplevels(fRep)
# get a shorter version of dfSample after adding technical replicates
dfSample.2 = dfSample[sapply(m, function(x) return(x[1])), ]
dim(dfSample.2)
identical(rownames(mData), as.character(dfSample.2$fReplicates))
dfSample.2 = droplevels.data.frame(dfSample.2)
rownames(mData) = as.character(dfSample.2$Code)
rownames(dfSample.2) = as.character(dfSample.2$Code)
identical(rownames(mData), rownames(dfSample.2))

lData.train.sub = list(data=mData, sample=dfSample.2)

rm(dfSample); rm(dfSample.2); rm(mData)

######### repeat the analysis done previously
table(lData.train.sub$data == 0)

# how many zeros per metabolite
z = apply(lData.train.sub$data, 2, function(x) sum(x == 0))
z[z > 0]
hist(z[z > 0])
z[z > 3]

# how many zeros per sample
z = apply(lData.train.sub$data, 1, function(x) sum(x == 0))
z[z > 0]
hist(z[z > 0])
z[z > 5]
iZeros = z

mData = log(lData.train.sub$data+1)
rownames(mData) = paste0(as.character(lData.train.sub$sample$fSubjectID), ':', 
                         as.character(lData.train.sub$sample$fTime))
# ## impute the missing data
# mData = apply(mData, 2, function(x){
#   i = which(x == 0)
#   if (length(i) > 0){
#     x[i] = mean(x)
#   }
#   return(x)
# })
# 
# rownames(mData) = as.character(lData.train.sub$sample$Sample)
oDiag.2 = CDiagnosticPlots(t(mData), 'log data merged')
l = CDiagnosticPlotsGetParameters(oDiag.2)
l$PCA.jitter = F
l$HC.jitter = F
oDiag.2 = CDiagnosticPlotsSetParameters(oDiag.2, l)

fBatch = lData.train.sub$sample$fTreatment

fBatch = cut(iZeros, breaks = c(0, 1, 4, max(iZeros)), include.lowest = T)
fBatch = lData.train$sample$fTime
levels(fBatch)
table(fBatch)

boxplot.median.summary(oDiag.2, fBatch, axis.label.cex = 0.5)
plot.mean.summary(oDiag.2, fBatch, axis.label.cex = 0.5)
plot.sigma.summary(oDiag.2, fBatch, axis.label.cex = 0.5)
plot.missing.summary(oDiag.2, fBatch)
## plotting characters 
p = (lData.train.sub$sample$fTime)
pc = c(1, 2, 3, 4)[as.numeric(p)]
plot.PCA(oDiag.2, fBatch, pch = pc, pch.cex = 1, legend.pos = 'topleft', csLabels = lData.train.sub$sample$fSubjectID, labels.cex = 0.7)
legend('top', legend = levels(p), pch = 1:4)
plot.dendogram(oDiag.2, fBatch, labels_cex = 0.85)
plot.heatmap(oDiag.2)

plot(oDiag.2@lData$PCA$sdev)
####### xyplots of averages and individual metabolites
library(lattice)
df = data.frame(x = oDiag.2@lData$PCA$x[,1], 
                lData.train.sub$sample)

xyplot(x ~ iTime | fSubjectID, data=df, type=(c('g', 'p', 'smooth')))
xyplot(x ~ iTime | fSubjectID, data=df, type=(c('g', 'p', 'l')))
xyplot(x ~ iTime | fTreatment, groups=fSubjectID, data=df, type=(c('g', 'p', 'l')))
xyplot(x ~ iTime | fTreatment, data=df, type=(c('g', 'p', 'r')))

#### redraw the diagnostic plots after removing variables
#### with zeros to see effects on PCA
# how many zeros per metabolite
z = apply(lData.train.sub$data, 2, function(x) sum(x == 0))
summary(z)
z[z > 0]
hist(z[z > 0])
z[z > 2]

mData = log(lData.train.sub$data+1)
mData = mData[, z <= 2]
dim(mData)
rownames(mData) = paste0(as.character(lData.train.sub$sample$fSubjectID), ':', 
                         as.character(lData.train.sub$sample$fTime))

oDiag.3 = CDiagnosticPlots(t(mData), 'zeros dropped')
l = CDiagnosticPlotsGetParameters(oDiag.3)
l$PCA.jitter = F
l$HC.jitter = F
oDiag.3 = CDiagnosticPlotsSetParameters(oDiag.3, l)

fBatch = cut(iZeros, breaks = c(0, 1, 4, max(iZeros)), include.lowest = T)
levels(fBatch)
table(fBatch)
p.old = par(mfrow=c(1,2))
boxplot.median.summary(oDiag.2, fBatch, axis.label.cex = 0.4)
boxplot.median.summary(oDiag.3, fBatch, axis.label.cex = 0.4)

plot.mean.summary(oDiag.2, fBatch, axis.label.cex = 0.4)
plot.mean.summary(oDiag.3, fBatch, axis.label.cex = 0.4)

plot.sigma.summary(oDiag.2, fBatch, axis.label.cex = 0.4)
plot.sigma.summary(oDiag.3, fBatch, axis.label.cex = 0.4)

plot.missing.summary(oDiag.2, fBatch)
plot.missing.summary(oDiag.3, fBatch)

## plotting characters 
p = (lData.train.sub$sample$fTime)
pc = c(1, 2, 3, 4)[as.numeric(p)]
plot.PCA(oDiag.2, fBatch, pch = pc, pch.cex = 0.8, legend.pos = 'topleft', csLabels = lData.train.sub$sample$fSubjectID, labels.cex = 0.5)
legend('top', legend = levels(p), pch = 1:4)
plot.PCA(oDiag.3, fBatch, pch = pc, pch.cex = 0.8, legend.pos = 'topleft', csLabels = lData.train.sub$sample$fSubjectID, labels.cex = 0.5)
legend('bottomleft', legend = levels(p), pch = 1:4)

plot.dendogram(oDiag.2, fBatch, labels_cex = 0.7)
plot.dendogram(oDiag.3, fBatch, labels_cex = 0.7)

plot.heatmap(oDiag.3)

plot(oDiag.3@lData$PCA$sdev)

## make ~12 at a time
# # impute the average for missing zeros
# mData = lData.train.sub$data
# mData = apply(mData, 2, function(x){
#   i = which(x == 0)
#   if (length(i) > 0){
#     x[i] = mean(x)
#   }
#   return(x)
# })

mData = log(lData.train.sub$data+1)
dim(mData)
plot(density(mData))
iCut = cut(1:117, breaks = 10, include.lowest = T, labels = 1:10)
dfCut = data.frame(iCut, x=1:117)
tapply(dfCut$x, dfCut$iCut, function(x){
  df = stack(data.frame(mData[,x]))
  df = cbind(df, lData.train.sub$sample)
  print(xyplot(values ~ iTime | ind, groups=fTreatment, data=df, type=(c('g', 'p', 'r')),
               scales=list(relation='free'), auto.key = list(columns=2), pch=20, cex=0.5)
  )
})

## add smoothing
tapply(dfCut$x, dfCut$iCut, function(x){
  df = stack(data.frame(mData[,x]))
  df = cbind(df, lData.train.sub$sample)
  print(xyplot(values ~ iTime | ind, groups=fTreatment, data=df, type=(c('g', 'p', 'smooth')),
               scales=list(relation='free'), auto.key = list(columns=2), pch=20, cex=0.5)
  )
})

## box plots
iCut = cut(1:117, breaks = 60, include.lowest = T, labels = 1:60)
dfCut = data.frame(iCut, x=1:117)
tapply(dfCut$x, dfCut$iCut, function(x){
  df = stack(data.frame(mData[,x]))
  df = cbind(df, lData.train.sub$sample)
  print(dotplot(values ~ fTime | fTreatment*ind, data=df, groups=df$ind,
                panel=function(x, y, ...) panel.bwplot(x, y, pch='|',...), type='b',
                par.strip.text=list(cex=0.7), scales=list(relation='free', x=list(cex=0.5), y=list(cex=0.7)))
  )
})

################ model checks and simulations for PCA
par(mfrow=c(1,1))
plot(oDiag.2@lData$PCA$sdev)
fBatch = lData.train.sub$sample$fTreatment
plot.PCA(oDiag.2, fBatch, labels.cex = 0.3)
mPC = oDiag.2@lData$PCA$x[,1:2]
mPC = scale(mPC)
## try a linear mixed effect model to account for varince
library(lme4)
dfData = data.frame(mPC)
dfData = stack(dfData)
str(dfData)

library(lattice)
densityplot(~ values, data=dfData)
densityplot(~ values | ind, data=dfData, scales=list(relation='free'))

dfSample.2 = lData.train.sub$sample
str(dfSample.2)
dfData$fTreatment = dfSample.2$fTreatment
dfData$fSubjectID = dfSample.2$fSubjectID
dfData$fTime = dfSample.2$fTime
dfData$fTrTime = dfSample.2$fTreatment:dfSample.2$fTime
dfData$fZeros = cut(iZeros, breaks = c(0, 1, 4, max(iZeros)), include.lowest = T)

densityplot(~ values | ind, groups=fTreatment, data=dfData, auto.key = list(columns=3), scales=list(relation='free'))
densityplot(~ values | ind, groups=fTime, data=dfData, auto.key = list(columns=3), scales=list(relation='free'))
densityplot(~ values | ind, groups=fTrTime, data=dfData, auto.key = list(columns=3), scales=list(relation='free'))
densityplot(~ values | ind, groups=fZeros, data=dfData, auto.key = list(columns=3), scales=list(relation='free'))

# format data for modelling
dfData$Coef.1 = factor(dfData$fTreatment:dfData$ind)
dfData$Coef.2 = factor(dfData$fTime:dfData$ind)
dfData$Coef.3 = factor(dfData$fSubjectID:dfData$ind)
dfData$Coef.4 = factor(dfData$fTrTime:dfData$ind)
dfData$Coef.5 = factor(dfData$fZeros:dfData$ind)
str(dfData)

fit.lme1 = lmer(values ~ 1  + (1 | Coef.1), data=dfData)
fit.lme2 = lmer(values ~ 1  + (1 | Coef.1) + (1 | Coef.2) + (1 | Coef.4), data=dfData)
fit.lme3 = lmer(values ~ 1  + (1 | Coef.1) + (1 | Coef.2) + (1 | Coef.4) + (1 | Coef.5), data=dfData)
fit.lme4 = lmer(values ~ 1  + (1 | Coef.4) + (1 | Coef.5), data=dfData)
fit.lme5 = lmer(values ~ 1  + (1 | Coef.4) + (1 | Coef.5) + (1 | fSubjectID), data=dfData)
fit.lme6 = lmer(values ~ 1  + (1 | Coef.1) + (1 | Coef.2) + (1 | Coef.4) + (1 | Coef.5) + (1 | fSubjectID), data=dfData)

anova(fit.lme1, fit.lme2, fit.lme3, fit.lme4, fit.lme5)
summary(fit.lme5)
## fit model with stan with various model sizes
library(rstan)
rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())
library(rethinking)

stanDso = rstan::stan_model(file='tResponsePartialPooling.stan')

######## models of various sizes using stan
## 3 coefficients with one interaction (4) + zeros
str(dfData)
m1 = model.matrix(values ~ Coef.1 - 1, data=dfData)
m2 = model.matrix(values ~ Coef.2 - 1, data=dfData)
m3 = model.matrix(values ~ Coef.3 - 1, data=dfData)
m4 = model.matrix(values ~ Coef.4 - 1, data=dfData)
m5 = model.matrix(values ~ Coef.5 - 1, data=dfData)

m = cbind(m1, m2, m3, m4, m5)

lStanData = list(Ntotal=nrow(dfData), Ncol=ncol(m), X=m,
                 NscaleBatches=5, NBatchMap=c(rep(1, times=nlevels(dfData$Coef.1)),
                                              rep(2, times=nlevels(dfData$Coef.2)),
                                              rep(3, times=nlevels(dfData$Coef.3)),
                                              rep(4, times=nlevels(dfData$Coef.4)),
                                              rep(5, times=nlevels(dfData$Coef.5))
                 ),
                 y=dfData$values)

fit.stan.5 = sampling(stanDso, data=lStanData, iter=5000, chains=2, pars=c('betas', 'populationMean', 'sigmaPop', 'sigmaRan',
                                                                           'nu', 'mu', 'log_lik'),
                      cores=2, control=list(adapt_delta=0.99, max_treedepth = 12))
print(fit.stan.5, c('populationMean', 'sigmaPop', 'sigmaRan', 'nu'), digits=3)

traceplot(fit.stan.5, 'populationMean')
traceplot(fit.stan.5, 'sigmaPop')
traceplot(fit.stan.5, 'sigmaRan')

## similar model formulated differently
m = cbind(m3, m4, m5)

lStanData = list(Ntotal=nrow(dfData), Ncol=ncol(m), X=m,
                 NscaleBatches=3, NBatchMap=c(rep(1, times=nlevels(dfData$Coef.3)),
                                              rep(2, times=nlevels(dfData$Coef.4)),
                                              rep(3, times=nlevels(dfData$Coef.5))
                 ),
                 y=dfData$values)

fit.stan.5b = sampling(stanDso, data=lStanData, iter=2000, chains=2, pars=c('betas', 'populationMean', 'sigmaPop', 'sigmaRan',
                                                                            'nu', 'mu', 'log_lik'),
                       cores=2, control=list(adapt_delta=0.99, max_treedepth = 12))
print(fit.stan.5b, c('populationMean', 'sigmaPop', 'sigmaRan', 'nu'), digits=3)

traceplot(fit.stan.5b, 'populationMean')
traceplot(fit.stan.5b, 'sigmaPop')
traceplot(fit.stan.5b, 'sigmaRan')

plot(compare(fit.stan.5, fit.stan.5b))

### 2 coefficients without the zeros
m = cbind(m3, m4)

lStanData = list(Ntotal=nrow(dfData), Ncol=ncol(m), X=m,
                 NscaleBatches=2, NBatchMap=c(rep(1, times=nlevels(dfData$Coef.3)),
                                              rep(2, times=nlevels(dfData$Coef.4))
                 ),
                 y=dfData$values)

fit.stan.2 = sampling(stanDso, data=lStanData, iter=5000, chains=2, pars=c('betas', 'populationMean', 'sigmaPop', 'sigmaRan',
                                                                           'nu', 'mu', 'log_lik'),
                      cores=2, control=list(adapt_delta=0.99, max_treedepth = 12))
print(fit.stan.2, c('populationMean', 'sigmaPop', 'sigmaRan', 'nu'), digits=3)

plot(compare(fit.stan.5, fit.stan.5b, fit.stan.2))

traceplot(fit.stan.3, 'populationMean')
traceplot(fit.stan.3, 'sigmaPop')
traceplot(fit.stan.3, 'sigmaRan')

### model without the subject id
m = cbind(m4)

lStanData = list(Ntotal=nrow(dfData), Ncol=ncol(m), X=m,
                 NscaleBatches=1, NBatchMap=c(rep(1, times=nlevels(dfData$Coef.4))
                 ),
                 y=dfData$values)

fit.stan.1 = sampling(stanDso, data=lStanData, iter=2000, chains=2, pars=c('betas', 'populationMean', 'sigmaPop', 'sigmaRan',
                                                                           'nu', 'mu', 'log_lik'),
                      cores=2, control=list(adapt_delta=0.99, max_treedepth = 12))
print(fit.stan.1, c('populationMean', 'sigmaPop', 'sigmaRan', 'nu'), digits=3)

traceplot(fit.stan.1, 'populationMean')
traceplot(fit.stan.1, 'sigmaPop')
traceplot(fit.stan.1, 'sigmaRan')

## some model scores and comparisons
compare(fit.stan.5, fit.stan.5b, fit.stan.2, fit.stan.1)
#compare(fit.stan.3, fit.stan.2, func = LOO)
plot(compare(fit.stan.5, fit.stan.5b, fit.stan.2, fit.stan.1))

############### new simulated data
###############
### generate some posterior predictive data
## generate random samples from alternative t-distribution parameterization
## see https://grollchristian.wordpress.com/2013/04/30/students-t-location-scale/
rt_ls <- function(n, df, mu, a) rt(n,df)*a + mu
## follow the algorithm in section 14.3 page 363 in Gelman 2013
simulateOne = function(mu, sigma, nu){
  yrep = rt_ls(length(mu), nu, mu,  sigma)
  return(yrep)
}

## sample n values, 300 times
mDraws.sim = matrix(NA, nrow = nrow(dfData), ncol=300)
l = extract(fit.stan.2)
for (i in 1:300){
  p = sample(1:nrow(l$mu), 1)
  mDraws.sim[,i] = simulateOne(l$mu[p,], 
                               l$sigmaPop[p],
                               l$nu[p])
}

dim(mDraws.sim)
plot(density(dfData$values), main='posterior predictive density plots, model 4')
apply(mDraws.sim, 2, function(x) lines(density(x), lwd=0.5, col='lightgrey'))
lines(density(dfData$values))

## plot residuals
plot(dfData$values - colMeans(l$mu) ~ colMeans(l$mu))
lines(lowess(colMeans(l$mu), dfData$values - colMeans(l$mu)))
apply(l$mu[sample(1:nrow(l$mu), 100),], 1, function(x) {
  lines(lowess(x, dfData$values - x), lwd=0.5, col=2)
})

## plot the original PCA and replicated data
plot(dfData$values[dfData$ind == 'PC1'], dfData$values[dfData$ind == 'PC2'], 
     col=c(1,2)[as.numeric(dfData$fTreatment[dfData$ind == 'PC1'])], main='PCA Components - original and simulated',
     xlab='PC1', ylab='PC2')
points(rowMeans(mDraws.sim)[dfData$ind == 'PC1'], rowMeans(mDraws.sim)[dfData$ind == 'PC2'],
       col=c(1,2)[as.numeric(dfData$fTreatment[dfData$ind == 'PC1'])], pch='1')

plot(dfData$values[dfData$ind == 'PC1'], dfData$values[dfData$ind == 'PC2'], 
     col=c(1,2)[as.numeric(dfData$fTreatment[dfData$ind == 'PC1'])], main='PCA Components - original and model 3',
     xlab='PC1', ylab='PC2', xlim=c(-5, 3), ylim=c(-3, 3))

apply(mDraws.sim, 2, function(x) {
  points(x[dfData$ind == 'PC1'], x[dfData$ind == 'PC2'],
         col=c(1,2)[as.numeric(dfData$fTreatment[dfData$ind == 'PC1'])], pch=20)
})


# ##########################################
m = cbind(extract(fit.stan.5)$sigmaRan, extract(fit.stan.5)$sigmaPop) 
dim(m)
m = log(m[,-6])
colnames(m) = c('Treatment', 'Time', 'SubjectID', 'Tr:Time', 'Zeros')
pairs(m, pch=20, cex=0.5, col='grey')

dim(m)
m = m[,-5]
df = stack(data.frame(m))
histogram(~ values | ind, data=df, xlab='Log SD', scales=list(relation='free'))

## 4b
m = cbind(extract(fit.stan.4b)$sigmaRan, extract(fit.stan.4b)$sigmaPop) 
dim(m)
#m = log(m)
colnames(m) = c('Subject', 'Tr:Time', 'Residual')
pairs(m, pch=20, cex=0.5, col='grey')

df = stack(data.frame(m))
histogram(~ values | ind, data=df, xlab='Log SD', scales=list(relation='free'))

######################### correlations of metabolites
mData = lData.train.sub$data

# ## impute the missing data
# mData = apply(mData, 2, function(x){
#   i = which(x == 0)
#   if (length(i) > 0){
#     x[i] = mean(x)
#   }
#   return(x)
# })

mCor = cor(log(mData+1))
image(mCor)
aheatmap(mCor, scale = 'none', cexRow = 20, fontsize = 6)
aheatmap(abs(mCor), scale = 'none', cexRow = 20, fontsize = 5)

hc = hclust(dist(abs(mCor)))
plot(hc, main='HC of Dist Mat for abs(Cor)', sub='', cex=0.4)
aheatmap(abs(mCor), scale = 'none', Rowv = hc, 
         Colv = hc, cexRow = 20, fontsize = 6,
         col=c('white', brewer.pal(5, 'YlOrRd')), breaks=0.5)
c = cutree(hc, k = 4)
table(c)

oDiag.3 = CDiagnosticPlots(abs(mCor), 'abs Cor Metab')
fBatch = factor(c)
l = CDiagnosticPlotsGetParameters(oDiag.3)
l = lapply(l, function(x) return(F))
oDiag.3 = CDiagnosticPlotsSetParameters(oDiag.3, l)
plot.PCA(oDiag.3, fBatch, legend.pos = 'bottomright', labels.cex = 0.5)
plot(oDiag.3@lData$PCA$sdev)
m = oDiag.3@lData$PCA$x[,1:3]
pairs(m, col=rainbow(4)[as.numeric(factor(c))], pch=20)

oDiag.4 = CDiagnosticPlots(log(mData+1), 'metabolites')
l = CDiagnosticPlotsGetParameters(oDiag.4)
l = lapply(l, function(x) return(F))
oDiag.4 = CDiagnosticPlotsSetParameters(oDiag.4, l)
plot.PCA(oDiag.4, fBatch, csLabels = '')
# 
# m = scale(t(scale(log((lData.train.sub$data+1)))))
# colnames(m) = as.character(lData.train.sub$sample$fTreatment)
# hc = hclust(dist(m))
# plot(hc)
# c = cutree(hc, h=14)
# 
# p = prcomp(abs(mCor), scale=F)
# biplot(p)
# plot(p$x[,1:2], pch=20)
# text(p$x[,1:2], labels = rownames(m), pos = 1, cex=0.6)