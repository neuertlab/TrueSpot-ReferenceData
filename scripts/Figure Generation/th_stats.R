#Load libraries
library(tidyverse)

#Read table
inputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\thstatsdump_240503.tsv"
thTable <- read_tsv(inputTablePath)

#Remove small and non-experimental groups
thTable <- filter(thTable, GROUP_A != "TsixE_AF594")
thTable <- filter(thTable, GROUP_A != "STL1_TMR_Smpl")
thTable <- filter(thTable, GROUP_A != "CTT1_CY5_Smpl")
thTable <- filter(thTable, GROUP_A != "SimBig")
thTable <- filter(thTable, GROUP_A != "SimVar")
thTable <- filter(thTable, GROUP_A != "SimVar1000")
thTable <- filter(thTable, GROUP_A != "Preibisch_sim")
thTable <- filter(thTable, GROUP_A != "Preibisch_celegans")
thTable <- filter(thTable, GROUP_A != "SimNeg")

#Allocate columns for group means and standard deviations
thTable$HB_GROUPA_MEAN <- rep(NaN, nrow(thTable))
thTable$HB_GROUPB_MEAN <- rep(NaN, nrow(thTable))
thTable$BF_GROUPA_MEAN <- rep(NaN, nrow(thTable))
thTable$BF_GROUPB_MEAN <- rep(NaN, nrow(thTable))
thTable$HB_GROUPA_STD <- rep(NaN, nrow(thTable))
thTable$HB_GROUPB_STD <- rep(NaN, nrow(thTable))
thTable$BF_GROUPA_STD <- rep(NaN, nrow(thTable))
thTable$BF_GROUPB_STD <- rep(NaN, nrow(thTable))

#Get groups
groupAOrder <- c("XistE_CY5", "XistI_CY5", "TsixE_TMR", "TsixI_TMR", "CTT1_CY5", "STL1_TMR", "HeLa_CY5", "HeLa_GFP", "Msb2", "Opy2", "H3K36me3", "H3K4me2", "SimCY5L", "SimTMRL")
thTable$GROUP_A <- factor(thTable$GROUP_A, levels=groupAOrder)
groupASet <- unique(thTable$GROUP_A)
groupBSet <- unique(thTable$GROUP_B)
groupBOrder <- sort(groupBSet)
groupBOrder <- groupBOrder[which(startsWith(groupBOrder, "STL1") | startsWith(groupBOrder, "CTT1"))]

#Calculate group stats
groupACount <- length(groupASet)
for (i in 1:groupACount) {
  gidxs <- which(thTable$GROUP_A == groupASet[i] & !is.nan(thTable$THVAL_HB))
  ga_mean <- mean(thTable$THVAL_HB[gidxs])
  ga_std <- sd(thTable$THVAL_HB[gidxs])
  thTable$HB_GROUPA_MEAN[gidxs] <- ga_mean
  thTable$HB_GROUPA_STD[gidxs] <- ga_std
  
  gidxs <- which(thTable$GROUP_A == groupASet[i] & !is.nan(thTable$THVAL_BF))
  ga_mean <- mean(thTable$THVAL_BF[gidxs])
  ga_std <- sd(thTable$THVAL_BF[gidxs])
  thTable$BF_GROUPA_MEAN[gidxs] <- ga_mean
  thTable$BF_GROUPA_STD[gidxs] <- ga_std
}

groupBCount <- length(groupBSet)
for (i in 1:groupBCount) {
  gidxs <- which(thTable$GROUP_B == groupBSet[i] & !is.nan(thTable$THVAL_HB))
  gb_mean <- mean(thTable$THVAL_HB[gidxs])
  gb_std <- sd(thTable$THVAL_HB[gidxs])
  thTable$HB_GROUPB_MEAN[gidxs] <- gb_mean
  thTable$HB_GROUPB_STD[gidxs] <- gb_std
  
  gidxs <- which(thTable$GROUP_B == groupBSet[i] & !is.nan(thTable$THVAL_BF))
  gb_mean <- mean(thTable$THVAL_BF[gidxs])
  gb_std <- sd(thTable$THVAL_BF[gidxs])
  thTable$BF_GROUPB_MEAN[gidxs] <- gb_mean
  thTable$BF_GROUPB_STD[gidxs] <- gb_std
}

#Calculate normalized thresholds and coefficient of variance
thTable <- thTable %>%
	mutate(NORM_THVAL_HB_A = THVAL_HB / HB_GROUPA_MEAN) %>%
	mutate(NORM_THVAL_HB_B = THVAL_HB / HB_GROUPB_MEAN) %>%
	mutate(NORM_THVAL_BF_A = THVAL_BF / BF_GROUPA_MEAN) %>%
	mutate(NORM_THVAL_BF_B = THVAL_BF / BF_GROUPB_MEAN) %>%
	mutate(COV_A_HB = HB_GROUPA_STD / HB_GROUPA_MEAN) %>%
	mutate(COV_B_HB = HB_GROUPB_STD / HB_GROUPB_MEAN) %>%
	mutate(COV_A_BF = BF_GROUPA_STD / BF_GROUPA_MEAN) %>%
	mutate(COV_B_BF = BF_GROUPB_STD / BF_GROUPB_MEAN)

#Rearrange table to make it easier to plot	
thPlotTable <- data.frame(IMGNAME = rep(thTable$IMGNAME, 2),
	GROUP_A = rep(thTable$GROUP_A, 2),
	GROUP_B = rep(thTable$GROUP_B, 2),
	THVAL = c(thTable$THVAL_HB, thTable$THVAL_BF),
	THVAL_NORM_A = c(thTable$NORM_THVAL_HB_A, thTable$NORM_THVAL_BF_A),
	THVAL_NORM_B = c(thTable$NORM_THVAL_HB_B, thTable$NORM_THVAL_BF_B),
	COV_A = c(thTable$COV_A_HB, thTable$COV_A_BF),
	COV_B = c(thTable$COV_B_HB, thTable$COV_B_BF),
	TOOL = as.factor(c(
		rep("NeuertLab", nrow(thTable)), 
		rep("Big-FISH", nrow(thTable))))
	)
thPlotTable$TOOL <- factor(thPlotTable$TOOL, levels=c("NeuertLab", "Big-FISH"))

#Exp group thnorm plot
expOnly <- filter(thPlotTable, (GROUP_A != "SimCY5L") & (GROUP_A != "SimTMRL"))
simOnly <- filter(thPlotTable, (GROUP_A == "SimCY5L") | (GROUP_A == "SimTMRL"))
ggplot(expOnly, aes(GROUP_A, THVAL_NORM_A)) +
	geom_boxplot(aes(colour = TOOL), outlier.alpha = 0.25) +
	geom_point(aes(colour = TOOL), width = 0.3, alpha = 0.5)

#CoV plot
ggplot(expOnly, aes(GROUP_A, COV_A)) + 
	geom_col(aes(fill = TOOL), position = "dodge")
	
	
#----------- sctc Th groups by timepoint
#inputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\sctcdump_main_230613.tsv"
inputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\sctcdump_main_240429.tsv"
sctcThTable <- read_tsv(inputTablePath)

sctcThTable$ER_MEAN_HB <- rep(NaN, nrow(sctcThTable))
sctcThTable$ER_MEAN_BF <- rep(NaN, nrow(sctcThTable))
sctcThTable$E_MEAN_HB <- rep(NaN, nrow(sctcThTable))
sctcThTable$E_MEAN_BF <- rep(NaN, nrow(sctcThTable))
sctcThTable$ER_STD_HB <- rep(NaN, nrow(sctcThTable))
sctcThTable$ER_STD_BF <- rep(NaN, nrow(sctcThTable))
sctcThTable$E_STD_HB <- rep(NaN, nrow(sctcThTable))
sctcThTable$E_STD_BF <- rep(NaN, nrow(sctcThTable))

timePoints <- sort(unique(sctcThTable$TIME))
timePointCount <- length(timePoints)

for (tpi in 1:timePointCount) {
	tp = timePoints[tpi]
	for (ex in 1:2) {
		for (r in 1:3) {
			for (ch in 1:2){
				gidxs <- which((sctcThTable$EXP == ex) & (sctcThTable$TIME == tp) & (sctcThTable$REP == r) & (sctcThTable$CH == ch) & (!is.nan(sctcThTable$THVAL_HB)))
				if (length(gidxs) > 0){
					g_mean <- mean(sctcThTable$THVAL_HB[gidxs])
					g_std <- sd(sctcThTable$THVAL_HB[gidxs])
					sctcThTable$ER_MEAN_HB[gidxs] <- g_mean
					sctcThTable$ER_STD_HB[gidxs] <- g_std
				}
			
				gidxs <- which((sctcThTable$EXP == ex) & (sctcThTable$TIME == tp) & (sctcThTable$REP == r) & (sctcThTable$CH == ch) & (!is.nan(sctcThTable$THVAL_BF)))
				if (length(gidxs) > 0){
					g_mean <- mean(sctcThTable$THVAL_BF[gidxs])
					g_std <- sd(sctcThTable$THVAL_BF[gidxs])
					sctcThTable$ER_MEAN_BF[gidxs] <- g_mean
					sctcThTable$ER_STD_BF[gidxs] <- g_std
				}
			}
		}
		
		for (ch in 1:2){
			gidxs <- which((sctcThTable$EXP == ex) & (sctcThTable$TIME == tp) & (sctcThTable$CH == ch) & (!is.nan(sctcThTable$THVAL_HB)))
			if (length(gidxs) > 0){
				g_mean <- mean(sctcThTable$THVAL_HB[gidxs])
				g_std <- sd(sctcThTable$THVAL_HB[gidxs])
				sctcThTable$E_MEAN_HB[gidxs] <- g_mean
				sctcThTable$E_STD_HB[gidxs] <- g_std
			}
		
			gidxs <- which((sctcThTable$EXP == ex) & (sctcThTable$TIME == tp) & (sctcThTable$CH == ch) & (!is.nan(sctcThTable$THVAL_BF)))
			if (length(gidxs) > 0){
				g_mean <- mean(sctcThTable$THVAL_BF[gidxs])
				g_std <- sd(sctcThTable$THVAL_BF[gidxs])
				sctcThTable$E_MEAN_BF[gidxs] <- g_mean
				sctcThTable$E_STD_BF[gidxs] <- g_std
			}
		}
	}
}

sctcThTable <- sctcThTable %>%
	mutate(NORM_THVAL_HB_E = THVAL_HB / E_MEAN_HB) %>%
	mutate(NORM_THVAL_HB_ER = THVAL_HB / ER_MEAN_HB) %>%
	mutate(NORM_THVAL_BF_E = THVAL_BF / E_MEAN_BF) %>%
	mutate(NORM_THVAL_BF_ER = THVAL_BF / ER_MEAN_BF) %>%
	mutate(COV_E_HB = E_STD_HB / E_MEAN_HB) %>%
	mutate(COV_ER_HB = ER_STD_HB / ER_MEAN_HB) %>%
	mutate(COV_E_BF = E_STD_BF / E_MEAN_BF) %>%
	mutate(COV_ER_BF = ER_STD_BF / ER_MEAN_BF)
	
#Reformat for plotting...
sctcThTablePlot <- data.frame(
	EXP = rep(sctcThTable$EXP, 2),
	REP = rep(sctcThTable$REP, 2),
	TIME = rep(sctcThTable$TIME, 2),
	CH = rep(sctcThTable$CH, 2),
	THVAL = c(sctcThTable$THVAL_HB, sctcThTable$THVAL_BF),
	THVAL_NORM_E = c(sctcThTable$NORM_THVAL_HB_E, sctcThTable$NORM_THVAL_BF_E),
	THVAL_NORM_ER = c(sctcThTable$NORM_THVAL_HB_ER, sctcThTable$NORM_THVAL_BF_ER),
	COV_E = c(sctcThTable$COV_E_HB, sctcThTable$COV_E_BF),
	COV_ER = c(sctcThTable$COV_ER_HB, sctcThTable$COV_ER_BF),
	TOOL = as.factor(c(
		rep("NeuertLab", nrow(sctcThTable)), 
		rep("Big-FISH", nrow(sctcThTable))))
	)
sctcThTablePlot$TIME <- factor(sctcThTablePlot$TIME, levels=timePoints)
sctcThTablePlot$TOOL <- factor(sctcThTablePlot$TOOL, levels=c("NeuertLab", "Big-FISH"))
	
#sctcSub <- filter(sctcThTablePlot, EXP == 2 & REP == 3 & CH == 2)
sctcSub <- filter(sctcThTablePlot, EXP == 2 & CH == 2)

ggplot(sctcSub, aes(TIME, THVAL_NORM_E)) +
	geom_boxplot(aes(colour = TOOL), outlier.alpha = 0.25) +
	geom_point(aes(colour = TOOL), width = 0.3, alpha = 0.5)
	
#Coefficients of variation...
ggplot(sctcSub, aes(TIME, COV_E)) + 
	geom_col(aes(fill = TOOL), position = "dodge")
	
#----------- Some basic stats for each group...
th_stats_table <- data.frame(
	GROUP = groupASet,
	n = rep(0, groupACount),
	MEAN_TS = rep(NaN, groupACount),
	MEAN_BF = rep(NaN, groupACount),
	STD_TS = rep(NaN, groupACount),
	STD_BF = rep(NaN, groupACount),
	COV_TS = rep(NaN, groupACount),
	COV_BF = rep(NaN, groupACount)
)

#First, the big exp groups...
for (i in 1:groupACount) {
	gidxs <- which(thTable$GROUP_A == groupASet[i] & !is.nan(thTable$THVAL_HB))
	th_stats_table$MEAN_TS[i] <- mean(thTable$THVAL_HB[gidxs])
	th_stats_table$STD_TS[i] <- sd(thTable$THVAL_HB[gidxs])
	th_stats_table$COV_TS[i] <- th_stats_table$STD_TS[i] / th_stats_table$MEAN_TS[i]
  
	gidxs <- which(thTable$GROUP_A == groupASet[i] & !is.nan(thTable$THVAL_BF))
	th_stats_table$MEAN_BF[i] <- mean(thTable$THVAL_BF[gidxs])
	th_stats_table$STD_BF[i] <- sd(thTable$THVAL_BF[gidxs])
	th_stats_table$COV_BF[i] <- th_stats_table$STD_BF[i] / th_stats_table$MEAN_BF[i]
  
  #n
	gidxs <- which(thTable$GROUP_A == groupASet[i] & !is.nan(thTable$THVAL_BF) & !is.nan(thTable$THVAL_HB))
	th_stats_table$n[i] <- length(gidxs)
  
  #Mm these are meaningless since normalized is defined around mean...
  #t-test
	#test_res <- t.test(thTable$NORM_THVAL_HB_A[gidxs], thTable$NORM_THVAL_BF_A[gidxs], na.rm = TRUE)
	#th_stats_table$T_EST[i] <- test_res$estimate
	#th_stats_table$T_P[i] <- test_res$p.value
	#th_stats_table$T_CI95_LO[i] <- test_res$conf.int[1]
	#th_stats_table$T_CI95_HI[i] <- test_res$conf.int[2]
  
  #MW test
	#test_res <- wilcox.test(thTable$NORM_THVAL_HB_A[gidxs], thTable$NORM_THVAL_BF_A[gidxs], na.rm = TRUE)
	#th_stats_table$MW_STAT[i] <- test_res$statistic
	#th_stats_table$MW_P[i] <- test_res$p.value
}

#The sctc groups...
th_table_append <- data.frame(
	GROUP = groupBSet,
	n = rep(0, groupBCount),
	MEAN_TS = rep(NaN, groupBCount),
	MEAN_BF = rep(NaN, groupBCount),
	STD_TS = rep(NaN, groupBCount),
	STD_BF = rep(NaN, groupBCount),
	COV_TS = rep(NaN, groupBCount),
	COV_BF = rep(NaN, groupBCount)
)

for (i in 1:groupBCount) {

	gidxs <- which(thTable$GROUP_B == groupBSet[i] & !is.nan(thTable$THVAL_HB))
	th_table_append$MEAN_TS[i] <- mean(thTable$THVAL_HB[gidxs])
	th_table_append$STD_TS[i] <- sd(thTable$THVAL_HB[gidxs])
	th_table_append$COV_TS[i] <- th_table_append$STD_TS[i] / th_table_append$MEAN_TS[i]
  
	gidxs <- which(thTable$GROUP_B == groupBSet[i] & !is.nan(thTable$THVAL_BF))
	th_table_append$MEAN_BF[i] <- mean(thTable$THVAL_BF[gidxs])
	th_table_append$STD_BF[i] <- sd(thTable$THVAL_BF[gidxs])
	th_table_append$COV_BF[i] <- th_table_append$STD_BF[i] / th_table_append$MEAN_BF[i]
  
  #n
	gidxs <- which(thTable$GROUP_B == groupBSet[i] & !is.nan(thTable$THVAL_BF) & !is.nan(thTable$THVAL_HB))
	th_table_append$n[i] <- length(gidxs)
}

outputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\thVar_GroupStats.tsv"
write_tsv(th_stats_table, outputTablePath)
