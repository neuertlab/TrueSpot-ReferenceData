#Load libraries
library(tidyverse)

#--- RNA Counts
inputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\sctcdump_cell_230613.tsv"
refTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\LiNeuert_sctc.csv"
sctcCountTable <- read_tsv(inputTablePath)
refCountTable <- read_csv(refTablePath)

SPOTS_ON_CH1 <- 8
SPOTS_ON_CH2 <- 2

#--- Functions
getCountStats <- function(myTable, use_rows, colname_rna_count, on_rna_min){
	outlist <- list(NaN, NaN, NaN, NaN, NaN, NaN, NaN)
	names(outlist) <- c("ON_PROP_ALL", "ON_PROP_TR_AVG", "ON_PROP_TR_STD", "AVG_PER_ON", "STD_PER_ON", "AVG_PER", "STD_PER")
	
	if(length(use_rows) > 0){
		myTable <- myTable[use_rows,]
	
		#Overall average
		outlist$AVG_PER <- mean(myTable[,colname_rna_count])
		outlist$STD_PER <- sd(myTable[,colname_rna_count])
	
		total_cells <- nrow(myTable)
		on_idxs <- which(myTable[,colname_rna_count] >= on_rna_min)
		on_count <- length(on_idxs)
	
		if (on_count > 0){
			outlist$ON_PROP_ALL <- on_count / total_cells
			outlist$AVG_PER_ON <- mean(myTable[on_idxs,colname_rna_count])
			outlist$STD_PER_ON <- sd(myTable[on_idxs,colname_rna_count])
			
			tech_reps <- unique(sort(myTable$I_NUM))
			tr_count <- length(tech_reps)
			if(tr_count > 0){
				tr_onprops <- rep(NaN, tr_count)
				for (tri in 1:tr_count){
					tidxs <- which(myTable$I_NUM == tech_reps[tri])
					tr_total <- length(tidxs)
					if (tr_total > 0){
						t_on_count <- length(which(myTable[tidxs,colname_rna_count] >= on_rna_min))
						tr_onprops[tri] <- t_on_count / tr_total
					}
					else{
						tr_onprops[tri] <- 0.0
					}
				}
				outlist$ON_PROP_TR_AVG <- mean(tr_onprops)
				outlist$ON_PROP_TR_STD <- sd(tr_onprops)
			}
			else{
				outlist$ON_PROP_TR_AVG <- outlist$ON_PROP_ALL
				outlist$ON_PROP_TR_STD <- 0.0
			}
		}
		else{
			outlist$ON_PROP_ALL <- 0.0
			outlist$ON_PROP_TR_AVG <- 0.0
			outlist$ON_PROP_TR_STD <- 0.0
			outlist$AVG_PER_ON <- 0.0
			outlist$STD_PER_ON <- 0.0
		}
	}
	
	return(outlist)
}

copyCalcOutputToTable <- function(inlist, outtable, row_index){
	outtable$ON_PROP_ALL[row_index] <- inlist$ON_PROP_ALL
	outtable$ON_PROP_TR_AVG[row_index] <- inlist$ON_PROP_TR_AVG
	outtable$ON_PROP_TR_STD[row_index] <- inlist$ON_PROP_TR_STD
	outtable$AVG_PER_ON[row_index] <- inlist$AVG_PER_ON
	outtable$STD_PER_ON[row_index] <- inlist$STD_PER_ON
	outtable$AVG_PER[row_index] <- inlist$AVG_PER
	outtable$STD_PER[row_index] <- inlist$STD_PER
	return(outtable)
}

#--- Arrange everything into a table

sctcRnaTable <- data.frame(EXP = integer(),
	REP = integer(),
	CH = integer(),
	TIME = integer(),
	TOOL = character(),
	TH_TYPE = character(),
	ON_PROP_ALL = double(),
	ON_PROP_TR_AVG = double(),
	ON_PROP_TR_STD = double(),
	AVG_PER_ON = double(),
	STD_PER_ON = double(),
	AVG_PER = double(),
	STD_PER = double()
)

for (ei in 1:2){
	for(ri in 1:3){
		if ((ei == 1) & (ri == 3)){
			break
		}
		
		repCountTable <- filter(sctcCountTable, EXP == ei & REP == ri)
		timePoints <- sort(unique(repCountTable$TIME))
		timePointCount <- length(timePoints)
		etotal <- (timePointCount * 2 * 2 * 4) + (timePointCount * 2)
		#Timepoint count *  channels * tools * th_types
		#Plus one more timepoint count set for the 2 channels for ref
		
		thTypeItr <- c(rep("I", timePointCount), rep("R", timePointCount), rep("E", timePointCount), rep("C", timePointCount))
		
		repRnaTable <- data.frame(EXP = rep(ei, etotal),
			REP = rep(ri, etotal),
			CH = c(rep(1,etotal/2), rep(2,etotal/2)),
			TIME = rep(timePoints, etotal/timePointCount),
			TOOL = rep(c(rep("NeuertLab", timePointCount * 4), rep("Big-FISH", timePointCount * 4), rep("Reference", timePointCount)),2),
			TH_TYPE = rep(c(thTypeItr, thTypeItr, rep("M", timePointCount)), 2),
			ON_PROP_ALL = rep(NaN, etotal),
			ON_PROP_TR_AVG = rep(NaN, etotal),
			ON_PROP_TR_STD = rep(NaN, etotal),
			AVG_PER_ON = rep(NaN, etotal),
			STD_PER_ON = rep(NaN, etotal),
			AVG_PER = rep(NaN, etotal),
			STD_PER = rep(NaN, etotal)
		)
		
		for (ci in 1:2){
		#Per channel
			CH_ON_MIN <- SPOTS_ON_CH1
			if (ci == 2){
				CH_ON_MIN <- SPOTS_ON_CH2
			}
			c_base_index <- 1 + ((ci - 1) * timePointCount * 9)
			
			for (tpi in 1:timePointCount){
				t_base_index <- c_base_index + tpi - 1
				time_min <- timePoints[tpi]
				timepointTable <- data.frame(filter(repCountTable, CH == ci & TIME == time_min))
				all_rows <- c(1:nrow(timepointTable))
				
				#HB
				outpos <- t_base_index
				repRnaTable <- copyCalcOutputToTable(getCountStats(timepointTable, all_rows, "THI_HB_TOT", CH_ON_MIN), repRnaTable, outpos)
				outpos <- outpos + timePointCount
				repRnaTable <- copyCalcOutputToTable(getCountStats(timepointTable, all_rows, "THR_HB_TOT", CH_ON_MIN), repRnaTable, outpos)
				outpos <- outpos + timePointCount
				repRnaTable <- copyCalcOutputToTable(getCountStats(timepointTable, all_rows, "THE_HB_TOT", CH_ON_MIN), repRnaTable, outpos)
				outpos <- outpos + timePointCount
				repRnaTable <- copyCalcOutputToTable(getCountStats(timepointTable, all_rows, "THC_HB_TOT", CH_ON_MIN), repRnaTable, outpos)
				
				#BF
				outpos <- outpos + timePointCount
				repRnaTable <- copyCalcOutputToTable(getCountStats(timepointTable, all_rows, "THI_BF_TOT", CH_ON_MIN), repRnaTable, outpos)
				outpos <- outpos + timePointCount
				repRnaTable <- copyCalcOutputToTable(getCountStats(timepointTable, all_rows, "THR_BF_TOT", CH_ON_MIN), repRnaTable, outpos)
				outpos <- outpos + timePointCount
				repRnaTable <- copyCalcOutputToTable(getCountStats(timepointTable, all_rows, "THE_BF_TOT", CH_ON_MIN), repRnaTable, outpos)
				outpos <- outpos + timePointCount
				repRnaTable <- copyCalcOutputToTable(getCountStats(timepointTable, all_rows, "THC_BF_TOT", CH_ON_MIN), repRnaTable, outpos)
				
				#REF
				outpos <- outpos + timePointCount
				refSubset <- filter(refCountTable, EXP == ei & REP == ri & CH == ci & TIME == time_min)
				refCells <- nrow(refSubset)
				on_idxs <- which(refSubset$TOTAL >= CH_ON_MIN)
				on_count <- length(on_idxs)
				repRnaTable$ON_PROP_ALL[outpos] <- on_count / refCells
				repRnaTable$ON_PROP_TR_AVG[outpos] <- repRnaTable$ON_PROP_ALL[outpos]
				repRnaTable$ON_PROP_TR_STD[outpos] <- 0.0
				repRnaTable$AVG_PER[outpos] <- mean(refSubset$TOTAL)
				repRnaTable$STD_PER[outpos] <- sd(refSubset$TOTAL)
				
				if(on_count > 0){
					repRnaTable$AVG_PER_ON[outpos] <- mean(refSubset$TOTAL[on_idxs])
					repRnaTable$STD_PER_ON[outpos] <- sd(refSubset$TOTAL[on_idxs])
				}
				else{
					repRnaTable$AVG_PER_ON[outpos] <- 0.0
					repRnaTable$STD_PER_ON[outpos] <- 0.0
				}
			}
		}
		
		#Append it to the main table...
		sctcRnaTable <- rbind(sctcRnaTable, repRnaTable)
		rm(repRnaTable)
	}
}

rm(repCountTable)
rm(timePoints)
rm(timePointCount)
rm(etotal)
rm(thTypeItr)
rm(refSubset)
rm(refCells)
rm(on_idxs)
rm(on_count)
rm(outpos)
rm(t_base_index)
rm(timepointTable)
rm(all_rows)
rm(c_base_index)
rm(CH_ON_MIN)
rm(time_min)
rm(ei)
rm(ci)
rm(ri)
rm(tpi)

#Convert tool and th type fields into factors...
sctcRnaTable$TOOL <- factor(sctcRnaTable$TOOL, levels=c("NeuertLab", "Big-FISH", "Reference"))
sctcRnaTable$TH_TYPE <- factor(sctcRnaTable$TH_TYPE, levels=c("I", "R", "E", "C", "M"))

allTimePoints <- sort(unique(sctcRnaTable$TIME))
sctcRnaTable$CH <- factor(sctcRnaTable$CH, levels=c(1,2))

#--- Stats

#> Comparing th picks against each other and to ref
#EXP REP CH TOOL TH_TYPE1 TH_TYPE2 ON_PROP_WILCOX ON_PROP_P AVG_PER_WILCOX AVG_PER_P
th_cycle_a <- c("I", "I", "I", "I", "R", "R", "R", "E", "E", "C")
th_cycle_b <- c("R", "E", "C", "M", "E", "C", "M", "C", "M", "M")

th_cycle_a <- factor(th_cycle_a, levels=c("I", "R", "E", "C", "M"))
th_cycle_b <- factor(th_cycle_b, levels=c("I", "R", "E", "C", "M"))
combo_count <- length(th_cycle_a)

th_comp_stats <- data.frame(EXP = integer(),
	REP = integer(),
	CH = integer(),
	TOOL = factor(),
	TH_A = factor(),
	TH_B = factor(),
	ON_PROP_WILCOX = double(),
	ON_PROP_WC_P = double(),
	AVG_PER_WILCOX = double(),
	AVG_PER_WC_P = double(),
	ON_PROP_TPAIR = double(),
	ON_PROP_TPAIR_P = double(),
	ON_PROP_TPAIR_EST = double(),
	ON_PROP_TPAIR_CI95_LO = double(),
	ON_PROP_TPAIR_CI95_HI = double(),
	AVG_PER_TPAIR = double(),
	AVG_PER_TPAIR_P = double(),
	AVG_PER_TPAIR_EST = double(),
	AVG_PER_TPAIR_CI95_LO = double(),
	AVG_PER_TPAIR_CI95_HI = double()
)

for (ee in 1:2){
	for(rr in 1:3){
		if(ee == 1 && rr == 3){
			break
		}
		
		for (cc in 1:2){
			ref_subset <- filter(sctcRnaTable, TOOL == "Reference", EXP == ee, REP == rr, CH == cc)
		
			for(tt in 1:2){
				tool_name <- "NeuertLab"
				if(tt == 2){
					tool_name <- "Big-FISH"
				}
			
				th_comp_group <- data.frame(EXP = rep(ee, combo_count),
					REP = rep(rr, combo_count),
					CH = rep(cc, combo_count),
					TOOL = as.factor(rep(tool_name, combo_count)),
					TH_A = th_cycle_a,
					TH_B = th_cycle_b,
					ON_PROP_WILCOX = rep(NaN, combo_count),
					ON_PROP_WC_P = rep(NaN, combo_count),
					AVG_PER_WILCOX = rep(NaN, combo_count),
					AVG_PER_WC_P = rep(NaN, combo_count),
					ON_PROP_TPAIR = rep(NaN, combo_count),
					ON_PROP_TPAIR_P = rep(NaN, combo_count),
					ON_PROP_TPAIR_EST = rep(NaN, combo_count),
					ON_PROP_TPAIR_CI95_LO = rep(NaN, combo_count),
					ON_PROP_TPAIR_CI95_HI = rep(NaN, combo_count),
					AVG_PER_TPAIR = rep(NaN, combo_count),
					AVG_PER_TPAIR_P = rep(NaN, combo_count),
					AVG_PER_TPAIR_EST = rep(NaN, combo_count),
					AVG_PER_TPAIR_CI95_LO = rep(NaN, combo_count),
					AVG_PER_TPAIR_CI95_HI = rep(NaN, combo_count))
					
				for(j in 1:combo_count){
					set_a <- filter(sctcRnaTable, TOOL == tool_name, EXP == ee, REP == rr, CH == cc, TH_TYPE == th_cycle_a[j])
					set_b <- filter(sctcRnaTable, TOOL == tool_name, EXP == ee, REP == rr, CH == cc, TH_TYPE == th_cycle_b[j])
					
					if (th_cycle_b[j] == "M"){
						set_b <- ref_subset
					}
					
					wc_res <- wilcox.test(set_a$ON_PROP_TR_AVG,set_b$ON_PROP_TR_AVG,paired=TRUE)
					th_comp_group$ON_PROP_WILCOX[j] <- wc_res$statistic
					th_comp_group$ON_PROP_WC_P[j] <- wc_res$p.value
				
					wc_res <- wilcox.test(set_a$AVG_PER_ON,set_b$AVG_PER_ON,paired=TRUE)
					th_comp_group$AVG_PER_WILCOX[j] <- wc_res$statistic
					th_comp_group$AVG_PER_WC_P[j] <- wc_res$p.value
					
					t_res <- t.test(set_a$ON_PROP_TR_AVG,set_b$ON_PROP_TR_AVG,paired=TRUE)
					th_comp_group$ON_PROP_TPAIR[j] <- t_res$statistic
					th_comp_group$ON_PROP_TPAIR_P[j] <- t_res$p.value
					th_comp_group$ON_PROP_TPAIR_EST[j] <- t_res$estimate
					th_comp_group$ON_PROP_TPAIR_CI95_LO[j] <- t_res$conf.int[1]
					th_comp_group$ON_PROP_TPAIR_CI95_HI[j] <- t_res$conf.int[2]
					
					t_res <- t.test(set_a$AVG_PER_ON,set_b$AVG_PER_ON,paired=TRUE)
					th_comp_group$AVG_PER_TPAIR[j] <- t_res$statistic
					th_comp_group$AVG_PER_TPAIR_P[j] <- t_res$p.value
					th_comp_group$AVG_PER_TPAIR_EST[j] <- t_res$estimate
					th_comp_group$AVG_PER_TPAIR_CI95_LO[j] <- t_res$conf.int[1]
					th_comp_group$AVG_PER_TPAIR_CI95_HI[j] <- t_res$conf.int[2]
					
					rm(wc_res)
					rm(t_res)
					rm(set_a)
					rm(set_b)
				}
				th_comp_stats <- rbind(th_comp_stats, th_comp_group)
				rm(th_comp_group)
			}
		}
	}
}

#--- To plot a single tech rep...
# > Filter to exp, rep, and ch
repCountTable <- filter(sctcCountTable, EXP == 2 & REP == 2 & CH == 1)
timePoints <- sort(unique(repCountTable$TIME))
timePointCount <- length(timePoints)

#TIME ON_PROP_HB AVG_PER_ON_HB ON_PROP_BF AVG_PER_ON_BF
totalsTable <- data.frame(TIME = timePoints,
	ON_PROP_ALL = rep(NaN, timePointCount), #All cells for the bio rep put together
	ON_PROP_TR_AVG = rep(NaN, timePointCount), #Calculate for each tech replicate, then average those.
	ON_PROP_TR_STD = rep(NaN, timePointCount),
	AVG_PER_ON = rep(NaN, timePointCount),
	STD_PER_ON = rep(NaN, timePointCount)
	)
	
for (tpi in 1:timePointCount) {
	tp = timePoints[tpi]
	
	gidxs <- which((repCountTable$TIME == tp))
	cellcount <- length(gidxs)
	if (cellcount > 0){
		#Update this line as needed
		on_cells <- sum(repCountTable$THR_HB_TOT[gidxs] >= SPOTS_ON_CH1)
		totalsTable$ON_PROP_ALL[tpi] <- on_cells / cellcount
		
		all_tr <- sort(unique(repCountTable$I_NUM[gidxs]))
		tr_count <- length(all_tr)
		tr_on <- rep(NaN, tr_count)
		
		for (j in 1:tr_count){
			tidxs <- which((repCountTable$TIME == tp) & (repCountTable$I_NUM == all_tr[j]))
			tr_cell_count <- length(tidxs)
			if (tr_cell_count > 0){
				#Update this line as needed
				on_cells <- sum(repCountTable$THR_HB_TOT[tidxs] >= SPOTS_ON_CH1)
				tr_on[j] <- on_cells / tr_cell_count
			}
			else{
				tr_on[j] <- 0
			}
		}
		
		totalsTable$ON_PROP_TR_AVG[tpi] <- mean(tr_on)
		totalsTable$ON_PROP_TR_STD[tpi] <- sd(tr_on)
		
		on_idx <- which((repCountTable$TIME == tp) & (repCountTable$THR_HB_TOT >= SPOTS_ON_CH1))
		if (length(on_idx) > 0){
			totalsTable$AVG_PER_ON[tpi] <- mean(repCountTable$THR_HB_TOT[on_idx])
			totalsTable$STD_PER_ON[tpi] <- sd(repCountTable$THR_HB_TOT[on_idx])
		}
		else{
			totalsTable$AVG_PER_ON[tpi] <- 0
			totalsTable$STD_PER_ON[tpi] <- 0
		}
	}
	else{
		totalsTable$ON_PROP_ALL[tpi] <- 0
		totalsTable$ON_PROP_TR_AVG[tpi] <- 0
		totalsTable$ON_PROP_TR_STD[tpi] <- 0
		totalsTable$AVG_PER_ON[tpi] <- 0
		totalsTable$STD_PER_ON[tpi] <- 0
	}
}

#--- Sim actual vs. detected Stats
inputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\sctcsim_counts_231013.tsv"
sctcSimCountTable <- read_tsv(inputTablePath)
cy5l_countTable <- filter(sctcSimCountTable, startsWith(IMAGENAME, "simvarmass_CY5L_"))
tmrl_countTable <- filter(sctcSimCountTable, startsWith(IMAGENAME, "simvarmass_TMRL_"))

cor_res_s <- cor.test(tmrl_countTable$ACTUAL_SPOTS_TRIMMED, tmrl_countTable$HBTr_COUNT_FIXED, method = "spearman")
cor_res_p <- cor.test(tmrl_countTable$ACTUAL_SPOTS_TRIMMED, tmrl_countTable$HBTr_COUNT_FIXED, method = "pearson")
