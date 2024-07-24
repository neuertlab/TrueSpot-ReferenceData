#Load libraries
library(tidyverse)

#Load raw table
#inputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\expBHStatsDump_230627.tsv"
#inputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\expBHStatsDump_231215.tsv"
#inputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\expBHStatsDump_240214.tsv"
#inputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\expBHStatsDump_240326_simerly.tsv"
#inputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\expBHStatsDump_240327.tsv" 
#inputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\expBHStatsDump_240327_2.tsv" #Presets 2/6 (?)
#inputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\expBHStatsDump_240402_3.tsv" #1: Presets 3/5, 2: Presets 1/7 3: Presets 4 (?)
inputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\expBHStatsDump_240429_1.tsv" 
#inputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\expBHStatsDump_240429_2.tsv" #Simerly
inputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\expBHStatsDump_240528.tsv" #Simerly
expResTable <- read_tsv(inputTablePath)

#Factors
tool_factor_order <- c("NeuertLab", "Big-FISH", "RS-FISH", "DeepBlink")
#group_factor_order <- c("XistE_CY5", "XistI_CY5", "TsixE_TMR", "TsixI_TMR", "CTT1_CY5_Smpl", "STL1_TMR_Smpl", "HeLa_CY5", "HeLa_GFP", "Msb2", "Opy2", "H3K36me3", "H3K4me2", "TsixE_AF594", "Preibisch_celegans")
group_factor_order <- c("XistE_CY5", "XistI_CY5", "TsixE_TMR", "TsixI_TMR", "CTT1_CY5_Smpl", "STL1_TMR_Smpl", "HeLa_CY5", "HeLa_GFP", "Msb2", "Opy2", "H3K36me3", "H3K4me2", "simerly_HiBkg_ARH_Mc3r_AF488", "simerly_LoBkg_Mc3r_AF488", "TsixE_AF594", "Preibisch_celegans", "simerly_40x_Mc3r_AF488", "simerly_40x_Oxtr_AF647", "simerly_40x_Slc32a1_AF647", "simerly_40x_Glp1r_AF647", "simerly_40x_Esr1_tdTom", "simerly_40x_Slc17a6_tdTom", "simerly_40x_Th_tdTom", "simerly_HiBkg_BST_Mc3r_AF488", "simerly_HiBkg_BST_Prkcd_AF647", "simerly_HiBkg_BST_Crh_tdTom", "simerly_HiBkg_ARH_Kiss1_AF647", "simerly_HiBkg_ARH_Kiss1_CY5", "simerly_HiBkg_ARH_Agrp_tdTom", "simerly_HiBkg_ARH_Agrp_AF568", "simerly_LoBkg_Oxtr_AF647", "simerly_LoBkg_Slc32a1_AF647", "simerly_LoBkg_Sst_tdTom", "simerly_LoBkg_Th_tdTom")
metric_factor_order <- c("MAX_RECALL", "PR_AUC", "F_SCORE")

#subgroup <- filter(expResTable, GROUP_A == "XistE_CY5")
expResTable <- filter(expResTable, startsWith(GROUP_B, "Tsix"))
expResTable <- filter(expResTable, startsWith(GROUP_B, "H3"))
expResTable <- filter(expResTable, !startsWith(GROUP_A, "simerly_"))

filterTable <- filter(expResTable, GROUP_A == "simerly_LoBkg_Th_tdTom")

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

#https://stackoverflow.com/questions/1330989/rotating-and-spacing-axis-labels-in-ggplot2
ggplot(expResPlotTable, aes(GROUP_A, PR_AUC)) +
	geom_boxplot(aes(colour = TOOL), outlier.alpha = 0) +
	geom_point(aes(colour = TOOL), alpha = 0.5) +
	theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1)) +
	scale_colour_manual(values = alpha(c("red", "blue", "green", "yellow"), .3))
	
ggplot(expResPlotTable, aes(GROUP_A, MAX_RECALL)) +
	geom_boxplot(aes(colour = TOOL), outlier.alpha = 0) +
	geom_point(aes(colour = TOOL), alpha = 0.5) +
	theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1)) +
	scale_colour_manual(values = alpha(c("red", "blue", "green", "yellow"), .3))
	
ggplot(expResPlotTable, aes(GROUP_A, FSCORE)) +
	geom_boxplot(aes(colour = TOOL), outlier.alpha = 0) +
	geom_point(aes(colour = TOOL), alpha = 0.5) +
	theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1)) + 
	ylim(0, 1) +
	scale_colour_manual(values = alpha(c("blue", "yellow", "red", "green"), .3))
	
#scProtein and Histone subgroups
subgroups <- filter(expResPlotTable, GROUP_B == "H3K4me2" | GROUP_B == "H3K36me3" | GROUP_B == "Msb2" | GROUP_B == "Opy2")
ggplot(subgroups, aes(GROUP_B, FSCORE)) +
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
	if (nrow(group_records) >= 1){
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
}

exp_stats$GROUP_A <- factor(exp_stats$GROUP_A, levels = group_factor_order)
outputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\expBHStats_CompareStats_240508.tsv"
write_tsv(exp_stats, outputTablePath)

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
	
	if (nrow(group_records) >= 1){
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
}

outputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\expBHStats_GroupStats_240508.tsv"
write_tsv(exp_basic_stats, outputTablePath)

# --- Tool count comparisons
#inputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\exp_percell_counts_231215.csv"
inputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\exp_percell_counts_240502.csv"
expResTable <- data.frame(read_csv(inputTablePath))

group_name <- "mescHistD0_H3K4me2_AF488"
group_only <- data.frame(filter(expResTable, GROUP == group_name))

spearman_res <- cor.test(group_only[,"COUNT_BF"], group_only[,"COUNT_HB"], method = "spearman", na.rm = TRUE)
pearson_res <- cor.test(group_only[,"COUNT_BF"], group_only[,"COUNT_HB"], method = "pearson", na.rm = TRUE)
lrmdl <- lm(COUNT_HB ~ COUNT_BF, data = group_only)

#Scatterplot
ggplot(group_only, aes(COUNT_BF, COUNT_HB)) +
	geom_point(aes(colour = IMGNAME)) + 
	geom_abline(slope = 1, intercept = 0) + 
	ggtitle(group_name) + 
	xlim(0, 1500) + 
	ylim(0, 1500)
	
#Heatmap
ggplot(group_only, aes(COUNT_BF, COUNT_HB)) +
	geom_density_2d_filled(bins = 50)
	
pearson_res$estimate
pearson_res$p.value
pearson_res$conf.int
spearman_res$estimate
spearman_res$p.value
lrmdl$coefficients

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
	mutate(TIMEPOINT = (as.integer(str_remove((str_split_i(GROUP, "_", 3)), "min")))) %>%
	mutate(EXPERIMENT = (as.integer(substr(str_split_i(GROUP, "_", 2), 2, 2)))) %>%
	mutate(REPLICATE = (as.integer(substr(str_split_i(GROUP, "_", 2), 4, 4)))) %>%
	mutate(CHANNEL = (as.integer(substr(str_split_i(GROUP, "_", 2), 6, 6))))
	
sctc_only$REPLICATE <- factor(sctc_only$REPLICATE, levels = c(1,2,3))
	
group_stem <- "sctc_E2R3C2"
group_only <- data.frame(filter(sctc_only, startsWith(GROUP, group_stem)))

ggplot(group_only, aes(COUNT_BF, COUNT_HB)) +
	geom_point() + 
	geom_abline(slope = 1, intercept = 0) + 
	facet_wrap(ncol = 2, vars(TIMEPOINT)) +
	ggtitle(group_stem)

ggplot(group_only, aes(COUNT_BF, COUNT_HB)) +
	geom_point() + 
	ylim(0, 150) +
	xlim(0, 150) +
	geom_abline(slope = 1, intercept = 0) + 
	facet_wrap(ncol = 2, vars(TIMEPOINT)) +
	ggtitle(group_stem)

ggplot(group_only, aes(COUNT_BF, COUNT_HB)) +
	geom_density_2d_filled(bins = 50) +
	ylim(0, 150) +
	xlim(0, 150) +
	theme(legend.position = "none") +
	facet_wrap(vars(TIMEPOINT)) +
	ggtitle(group_stem)
	
#--- Replicates together
ee <- 2
cc <- 2
exp_only <- data.frame(filter(sctc_only, EXPERIMENT == ee))
exp_only <- filter(exp_only, CHANNEL == cc)

group_stem <- sprintf("E%dC%d", ee, cc)
ggplot(exp_only, aes(COUNT_BF, COUNT_HB)) +
	geom_point(aes(colour = REPLICATE)) + 
	ylim(0, 150) +
	xlim(0, 150) +
	geom_abline(slope = 1, intercept = 0) + 
	facet_wrap(ncol = 2, vars(TIMEPOINT)) +
	ggtitle(group_stem)
	
ggplot(exp_only, aes(COUNT_BF, COUNT_HB)) +
	geom_density_2d_filled(bins = 50) +
	ylim(0, 150) +
	xlim(0, 150) +
	theme(legend.position = "none") +
	facet_wrap(vars(TIMEPOINT)) +
	ggtitle(group_stem)

#--- Stats table
all_groups <- unique(expResTable$GROUP)
all_groups <- unique(sctc_only$GROUP)
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
	LR_SLOPE = rep(NaN, group_count),
	LR_YINTR = rep(NaN, group_count),
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
	#group_records <- filter(sctc_only, GROUP == this_group)
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
	
	#Linear regression
	lrmdl <- lm(COUNT_HB ~ COUNT_BF, data = group_records)
	exp_cell_spots_stats$LR_SLOPE[g] <- lrmdl$coefficients["COUNT_BF"]
	exp_cell_spots_stats$LR_YINTR[g] <- lrmdl$coefficients["(Intercept)"]
	
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
	rm(lrmdl)
}
rm(g)

statsSavePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\exp_percell_counts_stats.tsv"
#statsSavePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\exp_sctc_percell_counts_stats.tsv"
write.table(exp_cell_spots_stats, file=statsSavePath, quote=FALSE, sep='\t')

#-------- Threshold presets

inputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\thPresetCompare_240428.tsv" 
thPresetResTable <- read_tsv(inputTablePath)

imgCount <- nrow(thPresetResTable)
thPresetResPlotTable <- data.frame(IMGNAME = rep(thPresetResTable$IMAGE, 12),
	TH_VAL = rep(NaN, imgCount * 12),
	SPOT_COUNT = rep(0, imgCount * 12),
	F_SCORE = rep(NaN, imgCount * 12),
	PRESET = rep(0, imgCount * 12)
	)

colPos <- 2
rowPos <- 1
for (pp in 0:11) {
	rowEd <- rowPos + imgCount - 1
	thPresetResPlotTable[rowPos:rowEd, "PRESET"] <- rep(pp, imgCount)
	
	if (pp < 1){
		colNameTh <- "FPEAK_THVAL"
		colNameSpots <- "FPEAK_SPOTCOUNT"
		colNameFScore <- "FPEAK_FSCORE"
	}
	else if (pp < 10){
		colNameTh <- paste("P0", pp, "_THVAL", sep="")
		colNameSpots <- paste("P0", pp, "_SPOTCOUNT", sep="")
		colNameFScore <- paste("P0", pp, "_FSCORE", sep="")
	}
	else {
		colNameTh <- paste("P", pp, "_THVAL", sep="")
		colNameSpots <- paste("P", pp, "_SPOTCOUNT", sep="")
		colNameFScore <- paste("P", pp, "_FSCORE", sep="")
	}
	
	thPresetResPlotTable[rowPos:rowEd, "TH_VAL"] <- thPresetResTable[, colPos]
	thPresetResPlotTable[rowPos:rowEd, "SPOT_COUNT"] <- thPresetResTable[, colPos+1]
	thPresetResPlotTable[rowPos:rowEd, "F_SCORE"] <- thPresetResTable[, colPos+2]
	
	colPos <- colPos + 3
	rowPos <- rowEd + 1
}

preset_factor_order <- c(0:11)
thPresetResPlotTable$PRESET <- factor(thPresetResPlotTable$PRESET, levels = preset_factor_order)

theme_notforants <- theme(axis.text.x=element_blank(), axis.ticks.x=element_blank(), 
		axis.text=element_text(size=12), axis.title.y=element_text(size=14), 
		plot.title=element_text(size=18), legend.text=element_text(size=12),
		legend.title=element_text(size=14), strip.text=element_text(size=12))

ggplot(thPresetResPlotTable, aes(x = PRESET, y = TH_VAL, fill = PRESET)) + 
	geom_violin(scale = "count", draw_quantiles = c(0.25, 0.5, 0.75), trim = FALSE) + 
	xlab("PRESET") +
	ylab("THRESHOLD VALUE") +
	ylim(0, 1500) +
	theme_notforants +
	ggtitle("Threshold Preset Comparisons")
	
ggplot(thPresetResPlotTable, aes(x = PRESET, y = SPOT_COUNT, fill = PRESET)) + 
	geom_violin(scale = "count", draw_quantiles = c(0.25, 0.5, 0.75), trim = FALSE) + 
	xlab("PRESET") +
	ylab("Spot Count") +
	theme_notforants +
	ggtitle("Threshold Preset Comparisons") +
	scale_y_log10()
	
ggplot(thPresetResPlotTable, aes(x = PRESET, y = SPOT_COUNT, fill = PRESET)) + 
	geom_violin(scale = "count", draw_quantiles = c(0.25, 0.5, 0.75), trim = FALSE) + 
	xlab("PRESET") +
	ylab("Spot Count") +
	theme_notforants +
	ylim(0, 10000) +
	ggtitle("Threshold Preset Comparisons")
	
#-------- Max projection

#inputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\maxprojResults_240430.tsv" 
#inputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\maxprojResults_240507.tsv" 
inputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\maxprojResults_240510.tsv" 
maxprojResTable <- read_tsv(inputTablePath)

#Rearrange for plotting
imgCount <- nrow(maxprojResTable)
maxprojResPlotTable <- data.frame(IMGNAME = rep(maxprojResTable$IMGNAME, 8),
	CELLNO = rep(maxprojResTable$CELLNO, 8),
	TARGET = rep(maxprojResTable$TARGET, 8),
	CH = rep(maxprojResTable$CH, 8),
	EXP = rep(maxprojResTable$EXP, 8),
	REP = rep(maxprojResTable$REP, 8),
	MIN = rep(maxprojResTable$MIN, 8),
	COUNT_3D = c(maxprojResTable$COUNT_3DF_HBV, maxprojResTable$COUNT_3DT_HBV, maxprojResTable$COUNT_3DF_HBF, maxprojResTable$COUNT_3DT_HBF, maxprojResTable$COUNT_3DF_BFV, maxprojResTable$COUNT_3DT_BFV, maxprojResTable$COUNT_3DF_BFF, maxprojResTable$COUNT_3DT_BFF),
	COUNT_2D = c(maxprojResTable$COUNT_2DF_HBV, maxprojResTable$COUNT_2DT_HBV, maxprojResTable$COUNT_2DF_HBF, maxprojResTable$COUNT_2DT_HBF, maxprojResTable$COUNT_2DF_BFV, maxprojResTable$COUNT_2DT_BFV, maxprojResTable$COUNT_2DF_BFF, maxprojResTable$COUNT_2DT_BFF),
	TOOL = c(rep("NeuertLab", imgCount * 4), rep("Big-FISH", imgCount * 4)),
	THTYPE = rep(c(rep("Variable", imgCount * 2), rep("Fixed", imgCount * 2)), 2),
	TRIMMED = rep(c(rep(FALSE, imgCount), rep(TRUE, imgCount)), 4)
	)

tool_factor_order <- c("NeuertLab", "Big-FISH")
thtype_factor_order <- c("Variable", "Fixed")
timePoints <- c(0,1,2,4,6,8,10,15,20,25,30,35,40,45,50,55,60)

maxprojResPlotTable$TOOL = factor(maxprojResPlotTable$TOOL, levels = tool_factor_order);
maxprojResPlotTable$THTYPE = factor(maxprojResPlotTable$THTYPE, levels = thtype_factor_order);

#Split histone and yeast for easier time
maxProjHistonesPlot <- filter(maxprojResPlotTable, startsWith(IMGNAME, "histonesc_"))
maxProjYeastPlot <- filter(maxprojResPlotTable, startsWith(IMGNAME, "sctc_"))
rm(maxprojResPlotTable)

maxProjYeastPlot$EXP = factor(maxProjYeastPlot$EXP, levels = c(1,2))
maxProjYeastPlot$REP = factor(maxProjYeastPlot$REP, levels = c(1,2,3))
maxProjYeastPlot$MIN = factor(maxProjYeastPlot$MIN, levels = timePoints)

#Basic 2D versus 3D
trimState <- TRUE
useThType <- "Fixed"
useChannel <- 1
useExp <- 2
useTool <- "NeuertLab"

trimStr <- "Trimmed"
if (!trimState){
	trimStr <- "Full"
}

myPlottable <- filter(maxProjYeastPlot, TRIMMED == trimState)
myPlottable <- filter(myPlottable, THTYPE == useThType)
myPlottable <- filter(myPlottable, CH == useChannel)
myPlottable <- filter(myPlottable, EXP == useExp)
myPlottable <- filter(myPlottable, TOOL == useTool)

ggplot(myPlottable, aes(COUNT_3D, COUNT_2D)) +
	geom_point(aes(colour = REP)) + 
	geom_abline(slope = 1, intercept = 0) + 
	facet_wrap(ncol = 4, vars(MIN)) +
	xlim(0,150) + 
	ylim(0,150) +
	ggtitle(paste(trimStr, " Stack - E", useExp, "C", useChannel, " [", useThType, " Threshold, ", useTool, "]", sep=""))
	
#Fixed vs. Variable
useChannel <- 2
useExp <- 2
trimState <- FALSE
useTool <- "NeuertLab"

trimStr <- "Trimmed"
if (!trimState){
	trimStr <- "Full"
}

myPlottable <- filter(maxprojResTable, EXP == useExp)
myPlottable <- filter(myPlottable, CH == useChannel)

myPlottable$EXP = factor(myPlottable$EXP, levels = c(1,2))
myPlottable$REP = factor(myPlottable$REP, levels = c(1,2,3))
myPlottable$MIN = factor(myPlottable$MIN, levels = timePoints)

ggplot(myPlottable, aes(COUNT_3DF_HBF, COUNT_3DF_HBV)) +
	geom_point(aes(colour = REP)) + 
	geom_abline(slope = 1, intercept = 0) + 
	facet_wrap(ncol = 4, vars(MIN)) +
	xlim(0,150) + 
	ylim(0,150) +
	ggtitle(paste(trimStr, " Stack - E", useExp, "C", useChannel, " [3D - ", useTool, "]", sep=""))
	
useMark <- "H3K36me3"
myPlottable <- filter(maxprojResTable, TARGET == useMark)
ggplot(myPlottable, aes(COUNT_2DF_BFF, COUNT_2DF_BFV)) +
	geom_point() +
	geom_abline(slope = 1, intercept = 0) + 
	ggtitle(paste(trimStr, " Stack - ", useMark, " [2D - ", useTool, "]", sep=""))

#Trimmed vs. full stack
useChannel <- 2
useExp <- 2
useThType <- "Variable"
useTool <- "NeuertLab"

myPlottable <- filter(maxprojResTable, EXP == useExp)
myPlottable <- filter(myPlottable, CH == useChannel)

myPlottable$EXP = factor(myPlottable$EXP, levels = c(1,2))
myPlottable$REP = factor(myPlottable$REP, levels = c(1,2,3))
myPlottable$MIN = factor(myPlottable$MIN, levels = timePoints)

ggplot(myPlottable, aes(COUNT_2DF_HBV, COUNT_2DT_HBV)) +
	geom_point(aes(colour = REP)) + 
	geom_abline(slope = 1, intercept = 0) + 
	facet_wrap(ncol = 4, vars(MIN)) +
	xlim(0,150) + 
	ylim(0,150) +
	ggtitle(paste(useThType, " Threshold - E", useExp, "C", useChannel, " [2D - ", useTool, "]", sep=""))
	
#Histone 2D vs. 3D
trimState <- TRUE
useThType <- "Fixed"
useChannel <- 4
useMark <- "H3K4me2"

trimStr <- "Trimmed"
if (!trimState){
	trimStr <- "Full"
}

myPlottable <- filter(maxProjHistonesPlot, grepl(useMark, IMGNAME, fixed = TRUE))
myPlottable <- filter(myPlottable, TRIMMED == trimState)
myPlottable <- filter(myPlottable, THTYPE == useThType)
myPlottable <- filter(myPlottable, CH == useChannel)

ggplot(myPlottable, aes(COUNT_3D, COUNT_2D)) +
	geom_point() + 
	geom_abline(slope = 1, intercept = 0) + 
	facet_wrap(ncol = 2, vars(TOOL)) +
	ggtitle(paste(trimStr, " Stack - ", useMark, " [", useThType, " Threshold]", sep = ""))

# Time course counts
SPOTS_ON_CH1 <- 8
SPOTS_ON_CH2 <- 2

yeastMIP_c1 <- filter(maxProjYeastPlot, CH == 1)
yeastMIP_c2 <- filter(maxProjYeastPlot, CH == 2)

timePointCount <- length(timePoints)
entriesPerTimePoint <- 2 * 2 * 2 * 2 #2 dim types, 2 th type, 2 trimstates, 2 tools
entriesPerBioRep <- entriesPerTimePoint * timePointCount
entriesPerCh <- 5 * entriesPerBioRep #5 exp/rep
ytcMIPPlotTable <- data.frame(CHANNEL = c(rep(1, entriesPerCh), rep(2, entriesPerCh)),
	EXP = rep(c(rep(1, entriesPerBioRep*2), rep(2, entriesPerBioRep*3)), 2),
	REP = rep(c(rep(c(rep(1, entriesPerBioRep), rep(2, entriesPerBioRep)), 2), rep(3, entriesPerBioRep)), 2),
	MIN = rep(timePoints, entriesPerTimePoint * 10),
	THTYPE = rep(c(rep("Fixed", timePointCount*8), rep("Variable", timePointCount*8)), 10),
	TRIMMED = rep(c(rep(FALSE, timePointCount*4), rep(TRUE, timePointCount*4)), 20),
	TOOL = rep(c(rep("NeuertLab", timePointCount*2), rep("Big-FISH", timePointCount*2)), 40),
	DIMTYPE = rep(c(rep("3D", timePointCount), rep("2D", timePointCount)), 80),
	TECHREPS = rep(0, entriesPerCh*2),
	TOTALCELLS = rep(0, entriesPerCh*2),
	ON_PROP_AVG = rep(NaN, entriesPerCh*2),
	ON_PROP_STD = rep(NaN, entriesPerCh*2),
	PER_ON_AVG = rep(NaN, entriesPerCh*2),
	PER_ON_STD = rep(NaN, entriesPerCh*2)
	)

ytcMIPPlotTable$TOOL = factor(ytcMIPPlotTable$TOOL, levels = tool_factor_order)
ytcMIPPlotTable$THTYPE = factor(ytcMIPPlotTable$THTYPE, levels = thtype_factor_order)
ytcMIPPlotTable$EXP = factor(ytcMIPPlotTable$EXP, levels = c(1,2))
ytcMIPPlotTable$REP = factor(ytcMIPPlotTable$REP, levels = c(1,2,3))
ytcMIPPlotTable$MIN = factor(ytcMIPPlotTable$MIN, levels = timePoints)
ytcMIPPlotTable$DIMTYPE = factor(ytcMIPPlotTable$DIMTYPE, levels = c("3D", "2D"))

totalEntries <- nrow(ytcMIPPlotTable)
for (e in 1:totalEntries){
	#Get subtable.
	groupTable <- filter(maxProjYeastPlot, CH == ytcMIPPlotTable$CHANNEL[e])
	groupTable <- filter(groupTable, MIN == ytcMIPPlotTable$MIN[e])
	groupTable <- filter(groupTable, EXP == ytcMIPPlotTable$EXP[e])
	groupTable <- filter(groupTable, REP == ytcMIPPlotTable$REP[e])
	groupTable <- filter(groupTable, TOOL == ytcMIPPlotTable$TOOL[e])
	groupTable <- filter(groupTable, THTYPE == ytcMIPPlotTable$THTYPE[e])
	groupTable <- filter(groupTable, TRIMMED == ytcMIPPlotTable$TRIMMED[e])
	
	totalCells <- nrow(groupTable)
	ytcMIPPlotTable$TOTALCELLS[e] <- totalCells
	
	onAmt <- SPOTS_ON_CH1
	if (ytcMIPPlotTable$CHANNEL[e] == 2){
		onAmt <- SPOTS_ON_CH2
	}
	
	if (ytcMIPPlotTable$DIMTYPE[e] == "3D"){
		groupTable <- groupTable %>%
			mutate(IS_ON = COUNT_3D >= onAmt)
		okayRows <- filter(groupTable, IS_ON)
		ytcMIPPlotTable$PER_ON_AVG[e] <- mean(okayRows$COUNT_3D)
		ytcMIPPlotTable$PER_ON_STD[e] <- sd(okayRows$COUNT_3D)
	}
	else{
		groupTable <- groupTable %>%
				mutate(IS_ON = COUNT_2D >= onAmt)
		okayRows <- filter(groupTable, IS_ON)
		ytcMIPPlotTable$PER_ON_AVG[e] <- mean(okayRows$COUNT_2D)
		ytcMIPPlotTable$PER_ON_STD[e] <- sd(okayRows$COUNT_2D)
	}

	#Go by tech rep...
	groupINames <- unique(groupTable$IMGNAME)
	trCount <- length(groupINames)
	ytcMIPPlotTable$TECHREPS[e] <- trCount
	
	tr_on <- rep(NaN, trCount)
	for (tr in 1:trCount){
		trGroup <- filter(groupTable, IMGNAME == groupINames[tr])
		okayRows <- filter(trGroup, IS_ON)
		tr_on[tr] <- nrow(okayRows) / nrow(trGroup)
	}
	
	ytcMIPPlotTable$ON_PROP_AVG[e] <- mean(tr_on)
	ytcMIPPlotTable$ON_PROP_STD[e] <- sd(tr_on)
}
rm(groupTable)
rm(trGroup)
rm(onAmt)
rm(okayRows)
rm(tr_on)
rm(totalCells)
rm(e)
rm(tr)
rm(trCount)
rm(groupINames)


#Filter to desired subset to plot.
useExp <- 1
useRep <- 2
useCh <- 2
useTool <- "Big-FISH"
useTrim <- FALSE
useThType <- "Fixed"

trimStr <- "Trimmed"
if (!useTrim){
	trimStr <- "Full"
}

plottableTable <- filter(ytcMIPPlotTable, EXP == useExp & REP == useRep & CHANNEL == useCh & TOOL == useTool & TRIMMED == useTrim & THTYPE == useThType)
plottableTable$MIN <- as.integer(plottableTable$MIN)
plottableTable$MIN <- timePoints[plottableTable$MIN]

ggplot(plottableTable, aes(MIN)) + 
	geom_ribbon(aes(ymin = ON_PROP_AVG - ON_PROP_STD, ymax = ON_PROP_AVG + ON_PROP_STD), fill = "grey70") +
	geom_line(aes(y = ON_PROP_AVG)) +
	ylim(0.0, 1.0) + 
	xlim(0,55) +
	facet_wrap(ncol = 1, vars(DIMTYPE)) +
	ggtitle(paste(trimStr, " Stack - E", useExp, "R", useRep, "C", useCh, " [", useThType, " Threshold, ", useTool, "]", sep=""))
	
ggplot(plottableTable, aes(MIN)) + 
	geom_ribbon(aes(ymin = PER_ON_AVG - PER_ON_STD, ymax = PER_ON_AVG + PER_ON_STD), fill = "grey70") +
	geom_line(aes(y = PER_ON_AVG)) +
	xlim(0,55) +
	ylim(0,150) +
	facet_wrap(ncol = 1, vars(DIMTYPE)) +
	ggtitle(paste(trimStr, " Stack - E", useExp, "R", useRep, "C", useCh, " [", useThType, " Threshold, ", useTool, "]", sep=""))
	
# Stats...

mipStats <- data.frame(GROUP = character(),
	TARGET = character(),
	SALT_CONC = double(),
	BIO_REPL = integer(),
	TIMEPOINT = integer(),
	CELL_COUNT = integer(),
	TOOL = factor(),
	TH_TYPE = factor(),
	STACK_TRIMMED = logical(),
	LR_SLOPE = double(),
	LR_ICEPT = double(),
	PEARSON_EST = double(),
	PEARSON_P = double(),
	PEARSON_CI95_LO = double(),
	PEARSON_CI95_HI = double(),
	SPEARMAN_EST = double(),
	SPEARMAN_P = double()
	)
	

tool_factor_order <- c("NeuertLab", "Big-FISH")
allTargets <- unique(maxprojResPlotTable$TARGET)
targetCount <- length(allTargets)
comboCount <- length(tool_factor_order) * length(thtype_factor_order) * 2

rm(i)
for (tt in 1:targetCount){
	justTargetRecords <- filter(maxprojResPlotTable, TARGET == allTargets[tt])
	
	#Per exp/rep/tp
	allExp <- unique(justTargetRecords$EXP)
	allRep <- unique(justTargetRecords$REP)
	allTimes <- unique(justTargetRecords$MIN)
	for (ee in 1:length(allExp)){
		egroup <- filter(justTargetRecords, EXP == allExp[ee])
		for (rr in 1:length(allRep)){
			rgroup <- filter(egroup, REP == allRep[rr])
			for (tpi in 1:length(allTimes)){
				mygroup <- filter(rgroup, MIN == allTimes[tpi])
				if(nrow(mygroup) > 0){
					subtable <- data.frame(GROUP = rep(allTargets[tt], comboCount),
						TARGET = rep(allTargets[tt], comboCount),
						SALT_CONC = rep(0.0, comboCount),
						BIO_REPL = rep(allRep[rr], comboCount),
						TIMEPOINT = rep(allTimes[tpi], comboCount),
						CELL_COUNT = rep(0, comboCount),
						TOOL = factor(c(rep("NeuertLab", comboCount/2), rep("Big-FISH", comboCount/2)), levels = tool_factor_order),
						TH_TYPE = factor(rep(c(rep("Fixed", comboCount/4), rep("Variable", comboCount/4)), 2), levels = thtype_factor_order),
						STACK_TRIMMED = rep(c(rep(FALSE, comboCount/8), rep(TRUE, comboCount/8)), 4),
						LR_SLOPE = rep(NaN, comboCount),
						LR_ICEPT = rep(NaN, comboCount),
						PEARSON_EST = rep(NaN, comboCount),
						PEARSON_P = rep(NaN, comboCount),
						PEARSON_CI95_LO = rep(NaN, comboCount),
						PEARSON_CI95_HI = rep(NaN, comboCount),
						SPEARMAN_EST = rep(NaN, comboCount),
						SPEARMAN_P = rep(NaN, comboCount)
					)
					
					if (allExp[ee] == 1){
						subtable$SALT_CONC <- rep(0.2, comboCount)
					}
					if (allExp[ee] == 2){
						subtable$SALT_CONC <- rep(0.4, comboCount)
					}
					
					for(cc in 1:comboCount){
						myComboGroup <- filter(mygroup, TOOL == subtable$TOOL[cc])
						myComboGroup <- filter(myComboGroup, THTYPE == subtable$TH_TYPE[cc])
						myComboGroup <- filter(myComboGroup, TRIMMED == subtable$STACK_TRIMMED[cc])
						
						subtable$CELL_COUNT[cc] <- nrow(myComboGroup)
						
						spearman_res <- cor.test(myComboGroup$COUNT_3D, myComboGroup$COUNT_2D, method = "spearman", na.rm = TRUE)
						pearson_res <- cor.test(myComboGroup$COUNT_3D, myComboGroup$COUNT_2D, method = "pearson", na.rm = TRUE)
	
						subtable$SPEARMAN_EST[cc] = spearman_res$estimate[1]
						subtable$SPEARMAN_P[cc] = spearman_res$p.value
						subtable$PEARSON_EST[cc] = pearson_res$estimate[1]
						subtable$PEARSON_CI95_LO[cc] = pearson_res$conf.int[1]
						subtable$PEARSON_CI95_HI[cc] = pearson_res$conf.int[2]
						subtable$PEARSON_P[cc] = pearson_res$p.value
	
						#Linear regression
						lrmdl <- lm(COUNT_2D ~ COUNT_3D, data = myComboGroup)
						subtable$LR_SLOPE[cc] <- lrmdl$coefficients["COUNT_3D"]
						subtable$LR_ICEPT[cc] <- lrmdl$coefficients["(Intercept)"]
					}
					
					mipStats <- rbind(mipStats, subtable)
				}
			}
		}
	}
}

rm(spearman_res)
rm(pearson_res)
rm(lrmdl)
rm(egroup)
rm(rgroup)
rm(mygroup)
rm(subtable)
rm(myComboGroup)
rm(cc)
rm(tt)
rm(ee)
rm(rr)
rm(tpi)
rm(justTargetRecords)
rm(allExp)
rm(allRep)
rm(allTimes)

statsSavePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\mip_percell_counts_stats.tsv"
write.table(mipStats, file=statsSavePath, quote=FALSE, sep='\t')