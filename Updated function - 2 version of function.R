library(dplyr)
library(readr)
library(stringr)
library(tidyverse)
library(cowplot)
library(ggplot2)
library(zoo)
library(Metrics)
library(purrr)
library(cluster)

# ComfortGPT <- function(df, Input_OT, alpha = 0.8, threshold = 5, cutoff = 16){
getwd()
setwd("C:/Users/Admin/PycharmProjects/comfortGPT")# keep them in a same folder

df_sample <- read.csv("case2.csv") # call it sample
df <- data.frame(Tout = df_sample$Tout, MixedSetPoints = df_sample$MixedSetPoints)#Just setpoint

Input_OT <- 21
alpha <- 0.8
threshold <- 5
cutoff <- 16

df_c_filename = "Slected_800_c-250.csv"
df_h_filename = "Slected_800_h-250.csv"

df_c_path <- file.path(getwd(), df_c_filename)
df_h_path <- file.path(getwd(), df_h_filename)

df_c <- read.csv(df_c_path)
df_h <- read.csv(df_h_path)

Predict_250_h <- list()
Error_250_h <- list()
Error_250_h_list <- list()
Optimal_slo_inter_heating <- list()
Outdoor_Th_weight_list <- list()
Predict_heating_True <- list()
true.erro_heating <-list()

Predict_250_c <- list()
Error_250_c <- list()
Error_250_c_list <- list()
Optimal_slo_inter_cooling <- list()
Outdoor_Tc_weight_list <- list()
Predict_cooling_True <- list()
true.erro_cooling <-list()

Optimal_slo_inter_cooling <- list()
for (j in 1:nrow(df)){
  if(j == 1){
    Predict_250_c <- as.data.frame(df$Tout[[j]]*df_c$Slope_cool + df_c$Intercept_cool)
    setpoint_list <- rep(df$MixedSetPoints[j], 250)

    Error_250_c <- as.data.frame(Predict_250_c - setpoint_list)^2
    Error_250_c_list <- c(Error_250_c_list,Error_250_c)
    matrix_from_nested_list <- do.call(cbind, lapply(Error_250_c_list, unlist))
    minindex_cooling=as.numeric(which.min(sqrt(rowSums(Error_250_c))))
    Data_combine_cooling=cbind.data.frame(Slope=df_c$Slope_cool[minindex_cooling],
                                          Intercept=df_c$Intercept_cool[minindex_cooling], Related_Tout=df$Tout[[j]], Related_input_setpoint=df$MixedSetPoints[j])
    Optimal_slo_inter_cooling=rbind.data.frame(Optimal_slo_inter_cooling,Data_combine_cooling)
    Outdoor_Tc_weight_list <- df$Tout[[j]]
    Predict_cooling_True[[j]] <- 0

  } else{
    Predicted_c= as.data.frame(df$Tout[[j]]*df_c$Slope_cool[minindex_cooling]+df_c$Intercept_cool[minindex_cooling])
    Predict_cooling_True[[j]] <- Predicted_c
    true.erro_cooling=c(true.erro_cooling,as.numeric(abs(Predicted_c-df$MixedSetPoints[j])))
    Predict_250_c <- as.data.frame(df$Tout[[j]]*df_c$Slope_cool + df_c$Intercept_cool)
    setpoint_list <- rep(df$MixedSetPoints[j], 250)
    Error_250_c <- as.data.frame(Predict_250_c - setpoint_list)^2
    Error_250_c_list <- c(Error_250_c_list,Error_250_c)
    matrix_from_nested_list <- do.call(cbind, lapply(Error_250_c_list, unlist))

    #minindex_cooling=as.numeric(which.min(sqrt(rowSums(matrix_from_nested_list))))
    colnames(matrix_from_nested_list) <- nrow(df$Tout)
    DF_nested_list <- as.data.frame(matrix_from_nested_list)
    weights <- alpha^(rev(0:(length(DF_nested_list)-1)))
    Outdoor_Tc_weight_list <- c(Outdoor_Tc_weight_list, df$Tout[[j]])

    if (j != nrow(df)) {
      Differences <- abs(Outdoor_Tc_weight_list - df$Tout[[j+1]])
      indices <- which(Differences < threshold)
      if (length(indices) > 0) {
        new_weights <- alpha^(rev(0:(length(indices) - 1)))
        weights[indices] <- pmax(weights[indices], new_weights)
        temperature_weight_list <- weights
        temperature_weight_list <- unlist(temperature_weight_list)
        result_weight <- t(apply(DF_nested_list, 1, function(row) row*temperature_weight_list))
      }else{
        result_weight <- t(apply(DF_nested_list, 1, function(row) row*weights))
      }
    } else {
      result_weight <- t(apply(DF_nested_list, 1, function(row) row*weights))
    }
    minindex_cooling=as.numeric(which.min(sqrt(rowSums(result_weight))))
    Data_combine_cooling=cbind.data.frame(Slope=df_c$Slope_cool[minindex_cooling],
                                          Intercept=df_c$Intercept_cool[minindex_cooling],Related_Tout=df$Tout[[j]], Related_input_setpoint=df$MixedSetPoints[j])
    Optimal_slo_inter_cooling=rbind.data.frame(Optimal_slo_inter_cooling,Data_combine_cooling)

  }

}

Optimal_slo_inter_heating <- list()
for (j in 1:nrow(df)){
  if(j == 1){
    Predict_250_h <- as.data.frame(df$Tout[[j]]*df_h$Slope_heat + df_h$Intercept_heat)
    setpoint_list_h <- rep(df$MixedSetPoints[j], 250)
    Error_250_h <- as.data.frame(Predict_250_h - setpoint_list_h)^2
    Error_250_h_list <- c(Error_250_h_list,Error_250_h)
    matrix_from_nested_list_h <- do.call(cbind, lapply(Error_250_h_list, unlist))
    minindex_heating=as.numeric(which.min(sqrt(rowSums(Error_250_h))))
    Data_combine_heating=cbind.data.frame(Slope=df_h$Slope_heat[minindex_heating],
                                          Intercept=df_h$Intercept_heat[minindex_heating])
    Optimal_slo_inter_heating=rbind.data.frame(Optimal_slo_inter_heating,Data_combine_heating)
    Outdoor_Th_weight_list <- df$Tout[[j]]
    Predict_heating_True[[j]] <- 0

  } else{
    Predicted_h= as.data.frame(df$Tout[[j]]*df_h$Slope_heat[minindex_heating]+df_h$Intercept_heat[minindex_heating])
    Predict_heating_True[[j]] <- Predicted_h
    true.erro_heating=c(true.erro_heating,as.numeric(abs(Predicted_h-df$MixedSetPoints[j])))
    Predict_250_h <- as.data.frame(df$Tout[[j]]*df_h$Slope_heat + df_h$Intercept_heat)
    setpoint_list_h <- rep(df$MixedSetPoints[j], 250)
    Error_250_h <- as.data.frame(Predict_250_h - setpoint_list_h)^2
    Error_250_h_list <- c(Error_250_h_list,Error_250_h)
    matrix_from_nested_list_h <- do.call(cbind, lapply(Error_250_h_list, unlist))
    #minindex_cooling=as.numeric(which.min(sqrt(rowSums(matrix_from_nested_list))))
    colnames(matrix_from_nested_list_h) <- nrow(df$Tout)
    DF_nested_list_h <- as.data.frame(matrix_from_nested_list_h)
    weights_h <- alpha^(rev(0:(length(DF_nested_list_h)-1)))
    Outdoor_Th_weight_list <- c(Outdoor_Th_weight_list, df$Tout[[j]])

    if (j != nrow(df)) {
      Differences_h <- abs(Outdoor_Th_weight_list - df$Tout[[j+1]])
      indices_h <- which(Differences_h < threshold)
      if (length(indices_h) > 0) {
        new_weights_h <- alpha^(rev(0:(length(indices_h) - 1)))
        weights_h[indices_h] <- pmax(weights_h[indices_h], new_weights_h)
        temperature_weight_list_h <- weights_h
        temperature_weight_list_h <- unlist(temperature_weight_list_h)
        result_weight_h <- t(apply(DF_nested_list_h, 1, function(row) row*temperature_weight_list_h))
      }else{
        result_weight_h <- t(apply(DF_nested_list_h, 1, function(row) row*weights_h))
      }
    } else {
      result_weight_h <- t(apply(DF_nested_list_h, 1, function(row) row*weights_h))
    }
    minindex_heating=as.numeric(which.min(sqrt(rowSums(result_weight_h))))
    Data_combine_heating=cbind.data.frame(Slope=df_h$Slope_heat[minindex_heating],
                                          Intercept=df_h$Intercept_heat[minindex_heating])
    Optimal_slo_inter_heating=rbind.data.frame(Optimal_slo_inter_heating,Data_combine_heating)

  }
}
latest_optimal_cooling <- tail(Optimal_slo_inter_cooling, 1)
latest_optimal_heating <- tail(Optimal_slo_inter_heating, 1)

if (!missing(Input_OT)) {
  if (Input_OT > cutoff) {
    # Use cooling scenario for prediction
    prediction <- Input_OT * latest_optimal_cooling$Slope + latest_optimal_cooling$Intercept
    print(paste("Using cooling scenario. The prediction is: ", prediction))
  } else {
    # Use heating scenario for prediction
    prediction <- Input_OT * latest_optimal_heating$Slope + latest_optimal_heating$Intercept
    print(paste("Using heating scenario. The prediction is: ", prediction))
  }
} else{
  print(paste("Lastest comfort profile for cooling season: The slope and intercept is: ", latest_optimal_cooling$Slope, " and ", latest_optimal_cooling$Intercept))
  print(paste("Lastest comfort profile for heating season: The slope and intercept is: ", latest_optimal_heating$Slope, " and ", latest_optimal_heating$Intercept))

}
  
  # # Return the results as a list including the last values
  # return(list(Optimal_slo_inter_cooling = Optimal_slo_inter_cooling,
  #             Optimal_slo_inter_heating = Optimal_slo_inter_heating,
  #             latest_optimal_cooling = latest_optimal_cooling,
  #             latest_optimal_heating = latest_optimal_heating))
  
  #return(list(Optimal_slo_inter_cooling, Optimal_slo_inter_heating))
  
# }


#results <- analyze_model(
#df_path = "C:\\Users\\10306\\Desktop\\case2.csv", 
#df_c_path = "C:\\Users\\10306\\Desktop\\Slected_800_c-250.csv", 
#df_h_path = "C:\\Users\\10306\\Desktop\\Slected_800_h-250.csv",
#Input_OT = 21 # replace with the Outdoor Temperature you want to use
#)

#list(
#Intercept_cooling = tail(Optimal_slo_inter_cooling$Intercept, 1),
#Slope_cooling = tail(Optimal_slo_inter_cooling$Slope, 1),
#Intercept_heating = tail(Optimal_slo_inter_heating$Intercept, 1),
#Slope_heating = tail(Optimal_slo_inter_heating$Slope, 1),
#Predicted_cooling = Input_OT * tail(Optimal_slo_inter_cooling$Slope, 1) + tail(Optimal_slo_inter_cooling$Intercept, 1),
#Predicted_heating = Input_OT * tail(Optimal_slo_inter_heating$Slope, 1) + tail(Optimal_slo_inter_heating$Intercept, 1)
#)