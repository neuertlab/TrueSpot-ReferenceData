#Load libraries
library(tidyverse)

#Load raw table
inputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\expBHStatsDump_230627.tsv"
expResTable <- read_tsv(inputTablePath)

#Factors
tool_factor_order <- c("NeuertLab", "Big-FISH", "RS-FISH", "DeepBlink")
group_factor_order <- c("Xist_CY5", "Tsix_TMR", "CTT1_CY5_Smpl", "STL1_TMR_Smpl", "HeLa_CY5", "HeLa_GFP", "scprotein", "Histone_AF488", "Tsix_AF594", "Preibisch_celegans")
metric_factor_order <- c("MAX_RECALL", "PR_AUC", "F_SCORE")

#Rearrange table to something more plot input friendly
expResPlotTable <- data.frame(IMGNAME = rep(expResTable$IMGNAME, 4),
	GROUP_A = rep(expResTable$GROUP_A, 4),
	GROUP_B = rep(expResTable$GROUP_B, 4),
	MAX_RECALL = c(expResTable$HB_MAXREC, expResTable$BF_MAXREC, expResTable$RS_MAXREC, expResTable$DB_MAXREC),
	PR_AUC = c(expResTable$HB_AUC, expResTable$BF_AUC, expResTable$RS_AUC, expResTable$DB_AUC),
	FSCORE = c(expResTable$HB_FSCORE, expResTable$BF_FSCORE, rep(NaN, nrow(expResTable) * 2)),
	TOOL = as.factor(c(
		rep("NeuertLab", nrow(expResTable)), 
		rep("Big-FISH", nrow(expResTable)),
		rep("RS-FISH", nrow(expResTable)),
		rep("DeepBlink", nrow(expResTable))))
	)
expResPlotTable$TOOL <- factor(expResPlotTable$TOOL, levels = tool_factor_order)
expResPlotTable$GROUP_A <- factor(expResPlotTable$GROUP_A, levels = group_factor_order)

ggplot(expResPlotTable, aes(GROUP_A, PR_AUC)) +
	geom_boxplot(aes(colour = TOOL), outlier.alpha = 0) +
	geom_point(aes(colour = TOOL), alpha = 0.5) +
	
ggplot(expResPlotTable, aes(GROUP_A, MAX_RECALL)) +
	geom_boxplot(aes(colour = TOOL), outlier.alpha = 0) +
	geom_point(aes(colour = TOOL), alpha = 0.5)
	
ggplot(expResPlotTable, aes(GROUP_A, FSCORE)) +
	geom_boxplot(aes(colour = TOOL), outlier.alpha = 0) +
	geom_point(aes(colour = TOOL), alpha = 0.5)
	
#Stats
tools_cycle_a <- c(rep("NeuertLab", 3), rep("Big-FISH", 2), "RS-FISH")
tools_cycle_b <- c("Big-FISH", "RS-FISH", "DeepBlink", "RS-FISH", "DeepBlink", "DeepBlink")
tools_cycle_a <- factor(tools_cycle_a, levels = tool_factor_order)
tools_cycle_b <- factor(tools_cycle_b, levels = tool_factor_order)

combo_count <- length(tools_cycle_a)
exp_stats <- data.frame(TOOL_A = factor(),
	TOOL_B = factor(),
	METRIC = factor(),
	MANN_WHITNEY = double(),
	MW_p = double(),
	GROUP_A = character()
)

group_count <- length(group_factor_order)
for (g in 1:group_count) {

	this_group <- group_factor_order[g]
	group_records <- filter(expResPlotTable, GROUP_A == this_group)

	exp_stats_group <- data.frame(TOOL_A = rep(tools_cycle_a, 3),
		TOOL_B = rep(tools_cycle_b, 3),
		METRIC = c(rep("MAX_RECALL", combo_count), rep("PR_AUC", combo_count), rep("F_SCORE", combo_count)),
		MANN_WHITNEY = rep(NaN, combo_count * 3),
		MW_p = rep(NaN, combo_count * 3),
		GROUP_A = rep(this_group, combo_count * 3)
		)
	exp_stats_group$METRIC <- factor(exp_stats_group$METRIC, levels = metric_factor_order)	

	#Compute stats here
	for (j in 1:combo_count){
		data_a <- filter(group_records, TOOL == tools_cycle_a[j])
		data_b <- filter(group_records, TOOL == tools_cycle_b[j])
		
		test_res <- wilcox.test(data_a$MAX_RECALL, data_b$MAX_RECALL)
		exp_stats_group$MANN_WHITNEY[j] = test_res$statistic
		exp_stats_group$MW_p[j] = test_res$p.value
		
		test_res <- wilcox.test(data_a$PR_AUC, data_b$PR_AUC)
		exp_stats_group$MANN_WHITNEY[j+combo_count] = test_res$statistic
		exp_stats_group$MW_p[j+combo_count] = test_res$p.value
		
		if (tools_cycle_a[j] == "NeuertLab" && tools_cycle_b[j] == "Big-FISH"){
			test_res <- wilcox.test(data_a$FSCORE, data_b$FSCORE)
			exp_stats_group$MANN_WHITNEY[j+(combo_count*2)] = test_res$statistic
			exp_stats_group$MW_p[j+(combo_count*2)] = test_res$p.value
		}
	}

	exp_stats <- rbind(exp_stats, exp_stats_group)
	rm(exp_stats_group)
}

exp_stats$GROUP_A <- factor(exp_stats$GROUP_A, levels = group_factor_order)

# --- General group Stats
tools_cycle_single <- c("NeuertLab", "Big-FISH", "RS-FISH", "DeepBlink")
tools_cycle_single <- factor(tools_cycle_single, levels = tool_factor_order)
tool_count <- length(tools_cycle_single)

rm(exp_basic_stats)
exp_basic_stats <- data.frame(TOOL = factor(),
	GROUP = factor(),
	METRIC = factor(),
	PERC_25 = double(),
	PERC_50 = double(),
	PERC_75 = double(),
	MEAN = double(),
	STDEV = double()
)

group_count <- length(group_factor_order)
for (g in 1:group_count) {

	this_group <- group_factor_order[g]
	group_records <- filter(expResPlotTable, GROUP_A == this_group)

	exp_stats_group <- data.frame(TOOL = rep(tools_cycle_single, 3),
		GROUP = rep(this_group, tool_count * 3),
		METRIC = c(rep("MAX_RECALL", tool_count), rep("PR_AUC", tool_count), rep("F_SCORE", tool_count)),
		PERC_25 = rep(NaN, tool_count * 3),
		PERC_50 = rep(NaN, tool_count * 3),
		PERC_75 = rep(NaN, tool_count * 3),
		MEAN = rep(NaN, tool_count * 3),
		STDEV = rep(NaN, tool_count * 3)
		)
	exp_stats_group$METRIC <- factor(exp_stats_group$METRIC, levels = metric_factor_order)	

	#Compute stats here
	for (j in 1:tool_count){
		data_a <- filter(group_records, TOOL == tools_cycle_single[j])
		
		quantiles_g <- quantile(data_a$MAX_RECALL, probs = c(0.25, 0.5, 0.75), na.rm = TRUE)
		exp_stats_group$MEAN[j] <- mean(data_a$MAX_RECALL, na.rm = TRUE)
		exp_stats_group$STDEV[j] <- sd(data_a$MAX_RECALL, na.rm = TRUE)
		exp_stats_group$PERC_25[j] <- quantiles_g[1]
		exp_stats_group$PERC_50[j] <- quantiles_g[2]
		exp_stats_group$PERC_75[j] <- quantiles_g[3]
		
		quantiles_g <- quantile(data_a$PR_AUC, probs = c(0.25, 0.5, 0.75), na.rm = TRUE)
		exp_stats_group$MEAN[j + tool_count] <- mean(data_a$PR_AUC, na.rm = TRUE)
		exp_stats_group$STDEV[j + tool_count] <- sd(data_a$PR_AUC, na.rm = TRUE)
		exp_stats_group$PERC_25[j + tool_count] <- quantiles_g[1]
		exp_stats_group$PERC_50[j + tool_count] <- quantiles_g[2]
		exp_stats_group$PERC_75[j + tool_count] <- quantiles_g[3]
		
		quantiles_g <- quantile(data_a$FSCORE, probs = c(0.25, 0.5, 0.75), na.rm = TRUE)
		exp_stats_group$MEAN[j + (tool_count*2)] <- mean(data_a$FSCORE, na.rm = TRUE)
		exp_stats_group$STDEV[j + (tool_count*2)] <- sd(data_a$FSCORE, na.rm = TRUE)
		exp_stats_group$PERC_25[j + (tool_count*2)] <- quantiles_g[1]
		exp_stats_group$PERC_50[j + (tool_count*2)] <- quantiles_g[2]
		exp_stats_group$PERC_75[j + (tool_count*2)] <- quantiles_g[3]
		
		rm(quantiles_g)
		rm(data_a)
	}

	exp_basic_stats <- rbind(exp_basic_stats, exp_stats_group)
	rm(exp_stats_group)
}
