#Load libraries
library(tidyverse)

#Load raw table
#inputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\expBHStatsDump_230627.tsv"
inputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\expBHStatsDump_231215.tsv"
expResTable <- read_tsv(inputTablePath)

#Factors
tool_factor_order <- c("NeuertLab", "Big-FISH", "RS-FISH", "DeepBlink")
group_factor_order <- c("XistE_CY5", "XistI_CY5", "TsixE_TMR", "TsixI_TMR", "CTT1_CY5_Smpl", "STL1_TMR_Smpl", "HeLa_CY5", "HeLa_GFP", "scprotein", "Histone_AF488", "TsixE_AF594", "Preibisch_celegans")
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

# --- Tool count comparisons
inputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\exp_percell_counts_231205.csv"
expResTable <- data.frame(read_csv(inputTablePath))

group_name <- "mescHistD2_H3K36me3_AF488"
group_only <- data.frame(filter(expResTable, GROUP == group_name))

spearman_res <- cor.test(group_only[,"COUNT_BF"], group_only[,"COUNT_HB"], method = "spearman", na.rm = TRUE)
pearson_res <- cor.test(group_only[,"COUNT_BF"], group_only[,"COUNT_HB"], method = "pearson", na.rm = TRUE)

#Scatterplot
ggplot(group_only, aes(COUNT_BF, COUNT_HB)) +
	geom_point(aes(colour = IMGNAME)) + 
	geom_abline(slope = 1, intercept = 0) + 
	ggtitle(group_name)
	
#Heatmap
ggplot(group_only, aes(COUNT_BF, COUNT_HB)) +
	geom_density_2d_filled(bins = 50)

#Remove outliers....
#Standard box/whiskers method...
all_counts <- c(group_only$COUNT_HB, group_only$COUNT_BF)
group_q <- quantile(all_counts, probs=c(0.25, 0.75), na.rm = TRUE)
iqr <- IQR(all_counts, na.rm = TRUE)
min_ok <- group_q[1] - (1.5 * iqr)
max_ok <- group_q[2] + (1.5 * iqr)


ggplot(group_only, aes(COUNT_BF, COUNT_HB)) +
	geom_density_2d_filled(bins = 50) +
	ylim(0, 2000) +
	xlim(0, 2000) +
	theme(legend.position = "none") +
	ggtitle(group_name)
	
ggplot(group_only, aes(COUNT_BF, COUNT_HB)) +
	geom_density_2d_filled(bins = 50) +
	theme(legend.position = "none") +
	ggtitle(group_name)
	
#--- sctc correlation plots
sctc_only <- data.frame(filter(expResTable, startsWith(GROUP, "sctc_")))
sctc_only <- sctc_only %>%
	mutate(TIMEPOINT = (as.integer(str_remove((str_split_i(GROUP, "_", 3)), "min"))))
	
group_stem <- "sctc_E2R3C2"
group_only <- data.frame(filter(sctc_only, startsWith(GROUP, group_stem)))

ggplot(group_only, aes(COUNT_BF, COUNT_HB)) +
	geom_point() + 
	geom_abline(slope = 1, intercept = 0) + 
	facet_wrap(vars(TIMEPOINT)) +
	ggtitle(group_stem)

ggplot(group_only, aes(COUNT_BF, COUNT_HB)) +
	geom_point() + 
	ylim(0, 150) +
	xlim(0, 150) +
	geom_abline(slope = 1, intercept = 0) + 
	facet_wrap(vars(TIMEPOINT)) +
	ggtitle(group_stem)

ggplot(sctc_only, aes(COUNT_BF, COUNT_HB)) +
	geom_density_2d_filled(bins = 50) +
	ylim(0, 150) +
	xlim(0, 150) +
	theme(legend.position = "none") +
	facet_wrap(vars(TIMEPOINT)) +
	ggtitle(group_stem)

#--- Stats table
all_groups <- unique(expResTable$GROUP)
group_count <- length(all_groups)

exp_cell_spots_stats <- data.frame(
	GROUP = all_groups,
	N = rep(0, group_count),
	SPEARMAN_EST = rep(NaN, group_count),
	SPEARMAN_P = rep(NaN, group_count),
	PEARSON_EST = rep(NaN, group_count),
	PEARSON_CI95_LO = rep(NaN, group_count),
	PEARSON_CI95_HI = rep(NaN, group_count),
	PEARSON_P = rep(NaN, group_count),
	PERC_25_HB = rep(NaN, group_count),
	PERC_50_HB = rep(NaN, group_count),
	PERC_75_HB = rep(NaN, group_count),
	MEAN_HB = rep(NaN, group_count),
	STD_HB = rep(NaN, group_count),
	WHISK_LO_HB = rep(NaN, group_count),
	WHISK_HI_HB = rep(NaN, group_count),
	PERC_25_BF = rep(NaN, group_count),
	PERC_50_BF = rep(NaN, group_count),
	PERC_75_BF = rep(NaN, group_count),
	MEAN_BF = rep(NaN, group_count),
	STD_BF = rep(NaN, group_count),
	WHISK_LO_BF = rep(NaN, group_count),
	WHISK_HI_BF = rep(NaN, group_count),
	PERC_25_DB = rep(NaN, group_count),
	PERC_50_DB = rep(NaN, group_count),
	PERC_75_DB = rep(NaN, group_count),
	MEAN_DB = rep(NaN, group_count),
	STD_DB = rep(NaN, group_count),
	WHISK_LO_DB = rep(NaN, group_count),
	WHISK_HI_DB = rep(NaN, group_count)
)

for (g in 1:group_count) {

	this_group <- all_groups[g]
	group_records <- filter(expResTable, GROUP == this_group)
	exp_cell_spots_stats$N[g] = nrow(group_records)

	#BF-HB correlations
	spearman_res <- cor.test(group_records$COUNT_BF, group_records$COUNT_HB, method = "spearman", na.rm = TRUE)
	pearson_res <- cor.test(group_records$COUNT_BF, group_records$COUNT_HB, method = "pearson", na.rm = TRUE)
	
	exp_cell_spots_stats$SPEARMAN_EST[g] = spearman_res$estimate[1]
	exp_cell_spots_stats$SPEARMAN_P[g] = spearman_res$p.value
	exp_cell_spots_stats$PEARSON_EST[g] = pearson_res$estimate[1]
	exp_cell_spots_stats$PEARSON_CI95_LO[g] = pearson_res$conf.int[1]
	exp_cell_spots_stats$PEARSON_CI95_HI[g] = pearson_res$conf.int[2]
	exp_cell_spots_stats$PEARSON_P[g] = pearson_res$p.value
	
	#HB stats
	gq <- quantile(group_records$COUNT_HB, probs=c(0.25, 0.50, 0.75), na.rm = TRUE)
	iqr <- IQR(group_records$COUNT_HB, na.rm = TRUE)
	
	exp_cell_spots_stats$PERC_25_HB[g] <- gq[1]
	exp_cell_spots_stats$PERC_50_HB[g] <- gq[2]
	exp_cell_spots_stats$PERC_75_HB[g] <- gq[3]
	exp_cell_spots_stats$WHISK_LO_HB[g] <- gq[1] - (1.5 * iqr)
	exp_cell_spots_stats$WHISK_HI_HB[g] <- gq[3] + (1.5 * iqr)
	exp_cell_spots_stats$MEAN_HB[g] <- mean(group_records$COUNT_HB, na.rm = TRUE)
	exp_cell_spots_stats$STD_HB[g] <- sd(group_records$COUNT_HB, na.rm = TRUE)
	
	#BF stats
	gq <- quantile(group_records$COUNT_BF, probs=c(0.25, 0.50, 0.75), na.rm = TRUE)
	iqr <- IQR(group_records$COUNT_BF, na.rm = TRUE)
	
	exp_cell_spots_stats$PERC_25_BF[g] <- gq[1]
	exp_cell_spots_stats$PERC_50_BF[g] <- gq[2]
	exp_cell_spots_stats$PERC_75_BF[g] <- gq[3]
	exp_cell_spots_stats$WHISK_LO_BF[g] <- gq[1] - (1.5 * iqr)
	exp_cell_spots_stats$WHISK_HI_BF[g] <- gq[3] + (1.5 * iqr)
	exp_cell_spots_stats$MEAN_BF[g] <- mean(group_records$COUNT_BF, na.rm = TRUE)
	exp_cell_spots_stats$STD_BF[g] <- sd(group_records$COUNT_BF, na.rm = TRUE)
	
	#DB stats
	gq <- quantile(group_records$COUNT_DB, probs=c(0.25, 0.50, 0.75), na.rm = TRUE)
	iqr <- IQR(group_records$COUNT_DB, na.rm = TRUE)
	
	exp_cell_spots_stats$PERC_25_DB[g] <- gq[1]
	exp_cell_spots_stats$PERC_50_DB[g] <- gq[2]
	exp_cell_spots_stats$PERC_75_DB[g] <- gq[3]
	exp_cell_spots_stats$WHISK_LO_DB[g] <- gq[1] - (1.5 * iqr)
	exp_cell_spots_stats$WHISK_HI_DB[g] <- gq[3] + (1.5 * iqr)
	exp_cell_spots_stats$MEAN_DB[g] <- mean(group_records$COUNT_DB, na.rm = TRUE)
	exp_cell_spots_stats$STD_DB[g] <- sd(group_records$COUNT_DB, na.rm = TRUE)

	rm(this_group)
	rm(group_records)
	
	rm(spearman_res)
	rm(pearson_res)
	rm(gq)
	rm(iqr)
}
rm(g)

statsSavePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\exp_percell_counts_stats.tsv"
write.table(exp_cell_spots_stats, file=statsSavePath, quote=FALSE, sep='\t')