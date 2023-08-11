#Load libraries
library(tidyverse)

theme_notforants <- theme(axis.text.x=element_blank(), axis.ticks.x=element_blank(), 
		axis.text=element_text(size=12), axis.title.y=element_text(size=14), 
		plot.title=element_text(size=18), legend.text=element_text(size=12),
		legend.title=element_text(size=14), strip.text=element_text(size=12))

#Load Data
inputTablePath <- "D:\\usr\\bghos\\labdat\\sim_results.csv"
inputTable <- read.csv(inputTablePath)

plabSims <- filter(inputTable, startsWith(IMGNAME, "rsfish_"))
sfSims <- filter(inputTable, !startsWith(IMGNAME, "rsfish_"))

plabSims <- filter(plabSims, FILT_PROP_ZERO < 0.7)
sfSims <- filter(sfSims, FILT_PROP_ZERO < 0.7)

# ----------------> Prepare initial table

makePlottableTable3 <- function(table_in){
	inputRows <- nrow(table_in)
	newTable <- data.frame(
		ImageName = rep(table_in[,"IMGNAME"], 6),
		ActualSpots = rep(table_in[,"SPOTS_ACTUAL"], 6),
		SpotsBox = rep(table_in[,"ACTUAL_SPOTS_PER_VOXBOX"], 6),
		SNR = rep(table_in[,"ALVL_TO_BKGVAR_SNR"], 6),
		SNR_DIFF = rep(table_in[,"SNR_SUBBKG_STDBKG"], 6),
		ZVP = rep(table_in[,"FILT_PROP_ZERO"], 6),
		AmpVar = rep(table_in[,"AMP_VAR"], 6),
		PRAUC = c(table_in[,"PRAUC_HB"], table_in[,"PRAUC_HBTr"], table_in[,"PRAUC_BF"], table_in[,"PRAUC_RS"], table_in[,"PRAUC_DB"], table_in[,"PRAUC_DBALT"]),
		MaxRecall = c(table_in[,"HB_MAXREC"], table_in[,"HBTr_MAXREC"], table_in[,"BF_MAXREC"], table_in[,"RS_MAXREC"], table_in[,"DB_MAXREC"], table_in[,"DBALT_MAXREC"]),
		FScore = c(table_in[,"HB_FSCORE"], table_in[,"HBTr_FSCORE"], table_in[,"BF_FSCORE"], rep(NaN, 3*inputRows)),
		Tool = as.factor(c(rep("NeuertLabUntrimmed", inputRows), rep("NeuertLab", inputRows), rep("Big-FISH", inputRows), rep("RS-FISH", inputRows), rep("DeepBlink", inputRows), rep("DeepBlinkAlt", inputRows)))
	)
	newTable$Tool <- factor(newTable$Tool, levels=c("NeuertLabUntrimmed", "NeuertLab", "Big-FISH", "RS-FISH", "DeepBlink", "DeepBlinkAlt"))
	return(newTable)
}

plotTable <- makePlottableTable3(inputTable)
plabPlotTable <- makePlottableTable3(plabSims)
sfPlotTable <- makePlottableTable3(sfSims)

# ----------------> PR-AUC, Recall, and F-Score Violin Plots

ggplot(sfPlotTable, aes(x = Tool, y = PRAUC, fill = Tool)) + 
	geom_violin(scale = "count", draw_quantiles = c(0.25, 0.5, 0.75), trim = FALSE) + 
	ylim(0,1) +
	xlab("") +
	ylab("PR-AUC") +
	theme_notforants +
	ggtitle("SimFISH Sim Set - PR-AUC") +
	scale_fill_manual(values = alpha(c("magenta", "red", "blue", "green", "yellow", "orange"), .3))
	
ggplot(plabPlotTable, aes(x = Tool, y = PRAUC, fill = Tool)) + 
	geom_violin(scale = "count", draw_quantiles = c(0.25, 0.5, 0.75), trim = FALSE) + 
	ylim(0,1) +
	xlab("") +
	ylab("PR-AUC") +
	theme_notforants +
	ggtitle("Preibisch Lab Sim Set - PR-AUC") +
	scale_fill_manual(values = alpha(c("magenta", "red", "blue", "green", "yellow", "orange"), .3))
	
test_set <- filter(plabPlotTable, Tool == "DeepBlinkAlt")
quantiles_auc <- quantile(test_set$PRAUC, probs = c(0.25, 0.5, 0.75), na.rm = TRUE)
mean_auc <- mean(test_set$PRAUC, na.rm = TRUE)
std_auc <- sd(test_set$PRAUC, na.rm = TRUE)
	
ggplot(sfPlotTable, aes(x = Tool, y = FScore, fill = Tool)) + 
	geom_violin(draw_quantiles = c(0.25, 0.5, 0.75)) +
	ylim(0,1) +
	xlab("") +
	theme_notforants +
	ggtitle("SimFISH Sim Set - F-Scores") +
	scale_fill_manual(values = alpha(c("magenta", "red", "blue", "green", "yellow", "orange"), .3))
	
ggplot(plabPlotTable, aes(x = Tool, y = FScore, fill = Tool)) + 
	geom_violin(draw_quantiles = c(0.25, 0.5, 0.75)) +
	ylim(0,1) +
	xlab("") +
	theme_notforants +
	ggtitle("Preibisch Lab Sim Set - F-Scores") +
	scale_fill_manual(values = alpha(c("magenta", "red", "blue", "green", "yellow", "orange"), .3))
	
test_set <- filter(plabPlotTable, Tool == "NeuertLabUntrimmed")
quantiles_fscore <- quantile(test_set$FScore, probs = c(0.25, 0.5, 0.75), na.rm = TRUE)
mean_fscore <- mean(test_set$FScore, na.rm = TRUE)
std_fscore <- sd(test_set$FScore, na.rm = TRUE)
	
ggplot(sfPlotTable, aes(x = Tool, y = MaxRecall, fill = Tool)) + 
	geom_violin(scale = "count", draw_quantiles = c(0.25, 0.5, 0.75), trim = FALSE) + 
	ylim(0,1) +
	xlab("") +
	ylab("Max Recall") +
	theme_notforants +
	ggtitle("SimFISH Sim Set - Max Recall") +
	scale_fill_manual(values = alpha(c("magenta", "red", "blue", "green", "yellow", "orange"), .3))
	
ggplot(plabPlotTable, aes(x = Tool, y = MaxRecall, fill = Tool)) + 
	geom_violin(scale = "count", draw_quantiles = c(0.25, 0.5, 0.75), trim = FALSE) + 
	ylim(0,1) +
	xlab("") +
	ylab("Max Recall") +
	theme_notforants +
	ggtitle("Preibisch Lab Sim Set - Max Recall") +
	scale_fill_manual(values = alpha(c("magenta", "red", "blue", "green", "yellow", "orange"), .3))
	
test_set <- filter(plabPlotTable, Tool == "DeepBlinkAlt")
quantiles_recall <- quantile(test_set$MaxRecall, probs = c(0.25, 0.5, 0.75), na.rm = TRUE)
mean_recall <- mean(test_set$MaxRecall, na.rm = TRUE)
std_recall <- sd(test_set$MaxRecall, na.rm = TRUE)

# ----------------> Violin plots - stats
tool_factor_order <- c("NeuertLabUntrimmed", "NeuertLab", "Big-FISH", "RS-FISH", "DeepBlink", "DeepBlinkAlt")
metric_factor_order <- c("MAX_RECALL", "PR_AUC", "F_SCORE")

tools_cycle_a <- c(rep(tool_factor_order[1], 5), rep(tool_factor_order[2], 4), rep(tool_factor_order[3], 3), rep(tool_factor_order[4], 2), tool_factor_order[5])
tools_cycle_b <- c(tool_factor_order[2:6], tool_factor_order[3:6], tool_factor_order[4:6], tool_factor_order[5:6], tool_factor_order[6])
tools_cycle_a <- factor(tools_cycle_a, levels = tool_factor_order)
tools_cycle_b <- factor(tools_cycle_b, levels = tool_factor_order)

combo_count <- length(tools_cycle_a)
sim_batch_stats <- data.frame(TOOL_A = factor(),
	TOOL_B = factor(),
	METRIC = factor(),
	MANN_WHITNEY = double(),
	MW_p = double(),
	GROUP = character()
)

for (g in 1:2) {
	src_tbl <- sfPlotTable
	groupname <- "Sim-FISH"
	if (g > 1){
		src_tbl <- plabPlotTable
		groupname <- "Preibisch Lab"
	}
	
	sim_batch_stats_group <- data.frame(TOOL_A = rep(tools_cycle_a, 3),
		TOOL_B = rep(tools_cycle_b, 3),
		METRIC = c(rep("MAX_RECALL", combo_count), rep("PR_AUC", combo_count), rep("F_SCORE", combo_count)),
		MANN_WHITNEY = rep(NaN, combo_count * 3),
		MW_p = rep(NaN, combo_count * 3),
		GROUP = rep(groupname, combo_count * 3)
	)
	sim_batch_stats_group$METRIC <- factor(sim_batch_stats_group$METRIC, levels = metric_factor_order)
	
	for (j in 1:combo_count){
		data_a <- filter(src_tbl, Tool == tools_cycle_a[j])
		data_b <- filter(src_tbl, Tool == tools_cycle_b[j])
		
		test_res <- wilcox.test(data_a$MaxRecall, data_b$MaxRecall, na.rm = TRUE)
		sim_batch_stats_group$MANN_WHITNEY[j] = test_res$statistic
		sim_batch_stats_group$MW_p[j] = test_res$p.value
		
		test_res <- wilcox.test(data_a$PRAUC, data_b$PRAUC, na.rm = TRUE)
		sim_batch_stats_group$MANN_WHITNEY[j+combo_count] = test_res$statistic
		sim_batch_stats_group$MW_p[j+combo_count] = test_res$p.value
		
		if ((tools_cycle_a[j] == "NeuertLab" || tools_cycle_a[j] == "NeuertLabUntrimmed") && (tools_cycle_b[j] == "Big-FISH" || tools_cycle_b[j] == "NeuertLab")){
			test_res <- wilcox.test(data_a$FScore, data_b$FScore, na.rm = TRUE)
			sim_batch_stats_group$MANN_WHITNEY[j+(combo_count*2)] = test_res$statistic
			sim_batch_stats_group$MW_p[j+(combo_count*2)] = test_res$p.value
		}
	}
	rm(data_a)
	rm(data_b)
	rm(test_res)

	sim_batch_stats <- rbind(sim_batch_stats, sim_batch_stats_group)
	rm(sim_batch_stats_group)
	
}

# ----------------> Subpixel fits

loadSpotFitTable <- function(tpath){
	inputTable <- read_tsv(tpath)
	inputTable <- filter(inputTable, PASS_TH == 1)
	inputTable <- filter(inputTable, !is.nan(X_FIT))
	
	inputTable <- filter(inputTable, !startsWith(IMGNAME, "rsfish_"))
	
	#Remove unneeded columns
	outTable <- data.frame(XY_DIST = inputTable$XY_DIST, Z_DIST = inputTable$Z_DIST, XYZ_DIST = inputTable$XYZ_DIST, ZFIT_Q = inputTable$ZFIT_Q)
	return(outTable)
}

inputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\spots_sim_hb.tsv"
fits_hb <- loadSpotFitTable(inputTablePath)
#fits_hb <- filter(fits_hb, !is.nan(ZFIT_Q))
#fits_hb <- filter(fits_hb, ZFIT_Q <= 1)

inputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\spots_sim_bf.tsv"
fits_bf <- loadSpotFitTable(inputTablePath)

inputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\spots_sim_rs.tsv"
fits_rs <- loadSpotFitTable(inputTablePath)

inputTablePath <- "D:\\usr\\bghos\\labdat\\imgproc\\tables\\spots_sim_db.tsv"
fits_db <- loadSpotFitTable(inputTablePath)

spotFits <- data.frame(XY_DIST = c(fits_hb$XY_DIST, fits_bf$XY_DIST, fits_rs$XY_DIST, fits_db$XY_DIST),
	Z_DIST = c(fits_hb$Z_DIST, fits_bf$Z_DIST, fits_rs$Z_DIST, fits_db$Z_DIST),
	XYZ_DIST = c(fits_hb$XYZ_DIST, fits_bf$XYZ_DIST, fits_rs$XYZ_DIST, fits_db$XYZ_DIST),
	TOOL = as.factor(c(rep("NeuertLab", nrow(fits_hb)), 
	rep("Big-FISH", nrow(fits_bf)), 
	rep("RS-FISH", nrow(fits_rs)), 
	rep("DeepBlink", nrow(fits_db)))))
spotFits$TOOL <- factor(spotFits$TOOL, levels=c("NeuertLab", "Big-FISH", "RS-FISH", "DeepBlink"))

#Maybe also remove spots too close to the edges of the image?
	
rm(fits_hb)
rm(fits_bf)
rm(fits_rs)
rm(fits_db)

ggplot(spotFits, aes(x = TOOL, y = XYZ_DIST, fill = TOOL)) + 
	geom_violin(scale = "width", draw_quantiles = c(0.25, 0.5, 0.75)) + 
	ylim(0,3) +
	xlab("") +
	ylab("XYZ_DIST") +
	theme_notforants +
	ggtitle("Fit XYZ Distance from Reference") +
	scale_fill_manual(values = alpha(c("red", "blue", "green", "yellow"), .3))
	
ggplot(spotFits, aes(x = TOOL, y = XY_DIST, fill = TOOL)) + 
	geom_violin(scale = "width", draw_quantiles = c(0.25, 0.5, 0.75)) + 
	ylim(0,3) +
	xlab("") +
	ylab("XY_DIST") +
	theme_notforants +
	ggtitle("Fit XY Distance from Reference") +
	scale_fill_manual(values = alpha(c("red", "blue", "green", "yellow"), .3))
	
	
ggplot(spotFits, aes(x = TOOL, y = Z_DIST, fill = TOOL)) + 
	geom_violin(scale = "width", draw_quantiles = c(0.25, 0.5, 0.75)) + 
	ylim(0,3) +
	xlab("") +
	ylab("Z_DIST") +
	theme_notforants +
	ggtitle("Fit Z Distance from Reference") +
	scale_fill_manual(values = alpha(c("red", "blue", "green", "yellow"), .3))

# ----------------> Plots against density and SNR (ZVP stuff too)

snr_safe <- filter(plotTable, is.finite(SNR_DIFF))
snr_safe <- filter(snr_safe, ZVP < 0.7)

ggplot(snr_safe, aes(x = ZVP, y = FScore)) +
	geom_density_2d_filled(bins = 50) + 
	ylim(0.0, 1.0) +
	xlim(0.0, 1.0) +
	facet_wrap(vars(Tool)) + 
	scale_x_log10()

ggplot(snr_safe, aes(x = SNR_DIFF, y = PRAUC)) +
	stat_density_2d(geom = "raster",
		aes(fill = after_stat(density)),
		contour = FALSE) + 
	ylim(0.0, 1.0) +
	scale_fill_viridis_c() +
	facet_wrap(vars(Tool))
	
#TODO ZVP and spot density plots too!

# ----------------> PRAUC & FScore vs SNR at various ZVPs
	
# ----------------> Spearman calculations

cor_test_table <- plotTable
tools_list <- c("NeuertLabUntrimmed", "NeuertLab", "Big-FISH", "RS-FISH", "DeepBlink", "DeepBlinkAlt")
x_list <- c("SNR", "SNR_DIFF", "SNR", "SNR_DIFF", "ZVP", "SpotsBox", "SpotsBox", "SpotsBox", "SNR", "SNR_DIFF", "AmpVar", "AmpVar", "AmpVar")
y_list <- c("PRAUC", "PRAUC", "FScore", "FScore", "FScore", "PRAUC", "FScore", "MaxRecall", "MaxRecall", "MaxRecall", "MaxRecall", "PRAUC", "FScore")

pair_count <- length(x_list)
tool_count <- length(tools_list)

sim_batch_cor <- data.frame(X_METRIC = rep(x_list, each = tool_count),
	Y_METRIC = rep(y_list, each = tool_count),
	TOOL = rep(tools_list, pair_count),
	SPEARMAN_STAT = rep(NaN, pair_count * tool_count),
	SPEARMAN_EST = rep(NaN, pair_count * tool_count),
	SPEARMAN_P = rep(NaN, pair_count * tool_count)
)
sim_batch_cor$TOOL <- factor(sim_batch_cor$TOOL, levels=c("NeuertLabUntrimmed", "NeuertLab", "Big-FISH", "RS-FISH", "DeepBlink", "DeepBlinkAlt"))

check_count = nrow(sim_batch_cor)
for (i in 1:check_count){

	tool_subset <- filter(cor_test_table, Tool == sim_batch_cor$TOOL[i])
	cor_res_s <- cor.test(tool_subset[,sim_batch_cor$X_METRIC[i]], tool_subset[,sim_batch_cor$Y_METRIC[i]], method = "spearman")

	sim_batch_cor$SPEARMAN_STAT[i] <- cor_res_s.statistic
	sim_batch_cor$SPEARMAN_EST[i] <- cor_res_s.estimate
	sim_batch_cor$SPEARMAN_P[i] <- cor_res_s.p.value
}
