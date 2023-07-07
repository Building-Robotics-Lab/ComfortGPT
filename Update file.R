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
#Input 250 clusters
df_c <- read.csv("C:\\Users\\10306\\Desktop\\Slected_800_c-250.csv")
df_h <- read.csv("C:\\Users\\10306\\Desktop\\Slected_800_h-250.csv")
#model settings
alpha <- 0.8
threshold <- 5
decision <- 16

#Input user data
df <- read.csv("C:\\Users\\10306\\Desktop\\case2.csv")

#Heating/Cooling scenario categorization
Cooling_scenario <- list()
Heating_scenario <- list()
for (i in 1:nrow(df)) {
  if (df$Tout[i] > decision){
    Cooling_scenario <- rbind(Cooling_scenario, df[i,])
    OutdoorT_c <- Cooling_scenario$Tout
    Input_setpoint_c <- Cooling_scenario$MixedSetPoints
  } else {#heating
    Heating_scenario <- rbind(Heating_scenario, df[i,])
    OutdoorT_h <- Heating_scenario$Tout
    Input_setpoint_h <- Heating_scenario$MixedSetPoints
  }
}
#ComfortGPT modeling - comfort proflie selection - cooling scenario

OutdoorT_c <- list()
Predict_250_c <- list()
Error_250_c <- list()
Error_250_c_list <- list()
Optimal_slo_inter_cooling <- list()
Outdoor_Tc_weight_list <- list()
Predict_cooling_True <- list()
true.erro_cooling <-list()

for (j in 1:nrow(Cooling_scenario)){
  if(j == 1){
    Predict_250_c <- as.data.frame(Cooling_scenario$Tout[[j]]*df_c$Slope_cool + df_c$Intercept_cool)
    setpoint_list <- rep(Input_setpoint_c[j], 250)
    Error_250_c <- as.data.frame(Predict_250_c - setpoint_list)^2
    Error_250_c_list <- c(Error_250_c_list,Error_250_c)
    matrix_from_nested_list <- do.call(cbind, lapply(Error_250_c_list, unlist))
    minindex_cooling=as.numeric(which.min(sqrt(rowSums(Error_250_c))))
    Data_combine_cooling=cbind.data.frame(Slope=df_c$Slope_cool[minindex_cooling],
                                          Intercept=df_c$Intercept_cool[minindex_cooling], Related_Tout=Cooling_scenario$Tout[[j]], Related_input_setpoint=Input_setpoint_c[j])
    Optimal_slo_inter_cooling=rbind.data.frame(Optimal_slo_inter_cooling,Data_combine_cooling)
    Outdoor_Tc_weight_list <- Cooling_scenario$Tout[[j]]
    Predict_cooling_True[[j]] <- 0
    
  } else{
    Predicted_c= as.data.frame(Cooling_scenario$Tout[[j]]*df_c$Slope_cool[minindex_cooling]+df_c$Intercept_cool[minindex_cooling])
    Predict_cooling_True[[j]] <- Predicted_c
    true.erro_cooling=c(true.erro_cooling,as.numeric(abs(Predicted_c-Input_setpoint_c[j])))
    Predict_250_c <- as.data.frame(Cooling_scenario$Tout[[j]]*df_c$Slope_cool + df_c$Intercept_cool)
    setpoint_list <- rep(Input_setpoint_c[j], 250)
    Error_250_c <- as.data.frame(Predict_250_c - setpoint_list)^2
    Error_250_c_list <- c(Error_250_c_list,Error_250_c)
    matrix_from_nested_list <- do.call(cbind, lapply(Error_250_c_list, unlist))
    #minindex_cooling=as.numeric(which.min(sqrt(rowSums(matrix_from_nested_list))))
    colnames(matrix_from_nested_list) <- nrow(Cooling_scenario$Tout)
    DF_nested_list <- as.data.frame(matrix_from_nested_list)
    weights <- alpha^(rev(0:(length(DF_nested_list)-1)))
    Outdoor_Tc_weight_list <- c(Outdoor_Tc_weight_list, Cooling_scenario$Tout[[j]])
    
    if (j != nrow(Cooling_scenario)) {
      Differences <- abs(Outdoor_Tc_weight_list - Cooling_scenario$Tout[[j+1]])
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
                                          Intercept=df_c$Intercept_cool[minindex_cooling],Related_Tout=Cooling_scenario$Tout[[j]], Related_input_setpoint=Input_setpoint_c[j])
    Optimal_slo_inter_cooling=rbind.data.frame(Optimal_slo_inter_cooling,Data_combine_cooling)
    
  } 
}

print(Optimal_slo_inter_cooling)


#ComfortGPT modeling - comfort proflie selection - heating scenario
OutdoorT_h <- list()
Predict_250_h <- list()
Error_250_h <- list()
Error_250_h_list <- list()
Optimal_slo_inter_heating <- list()
Outdoor_Th_weight_list <- list()
Predict_heating_True <- list()
true.erro_heating <-list()

for (j in 1:nrow(Heating_scenario)){
  if(j == 1){
    Predict_250_h <- as.data.frame(Heating_scenario$Tout[[j]]*df_h$Slope_heat + df_h$Intercept_heat)
    setpoint_list_h <- rep(Input_setpoint_h[j], 250)
    Error_250_h <- as.data.frame(Predict_250_h - setpoint_list_h)^2
    Error_250_h_list <- c(Error_250_h_list,Error_250_h)
    matrix_from_nested_list_h <- do.call(cbind, lapply(Error_250_h_list, unlist))
    minindex_heating=as.numeric(which.min(sqrt(rowSums(Error_250_h))))
    Data_combine_heating=cbind.data.frame(Slope=df_h$Slope_heat[minindex_heating],
                                          Intercept=df_h$Intercept_heat[minindex_heating], Related_Tout=Heating_scenario$Tout[[j]], Related_input_setpoint=Input_setpoint_h[j])
    Optimal_slo_inter_heating=rbind.data.frame(Optimal_slo_inter_heating,Data_combine_heating)
    Outdoor_Th_weight_list <- Heating_scenario$Tout[[j]]
    Predict_heating_True[[j]] <- 0
    
  } else{
    Predicted_h= as.data.frame(Heating_scenario$Tout[[j]]*df_h$Slope_heat[minindex_heating]+df_h$Intercept_heat[minindex_heating])
    Predict_heating_True[[j]] <- Predicted_h
    true.erro_heating=c(true.erro_heating,as.numeric(abs(Predicted_h-Input_setpoint_h[j])))
    Predict_250_h <- as.data.frame(Heating_scenario$Tout[[j]]*df_h$Slope_heat + df_h$Intercept_heat)
    setpoint_list_h <- rep(Input_setpoint_h[j], 250)
    Error_250_h <- as.data.frame(Predict_250_h - setpoint_list_h)^2
    Error_250_h_list <- c(Error_250_h_list,Error_250_h)
    matrix_from_nested_list_h <- do.call(cbind, lapply(Error_250_h_list, unlist))
    #minindex_cooling=as.numeric(which.min(sqrt(rowSums(matrix_from_nested_list))))
    colnames(matrix_from_nested_list_h) <- nrow(Heating_scenario$Tout)
    DF_nested_list_h <- as.data.frame(matrix_from_nested_list_h)
    weights_h <- alpha^(rev(0:(length(DF_nested_list_h)-1)))
    Outdoor_Th_weight_list <- c(Outdoor_Th_weight_list, Heating_scenario$Tout[[j]])
    
    if (j != nrow(Heating_scenario)) {
      Differences_h <- abs(Outdoor_Th_weight_list - Heating_scenario$Tout[[j+1]])
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
                                          Intercept=df_h$Intercept_heat[minindex_heating], Related_Tout=Heating_scenario$Tout[[j]], Related_input_setpoint=Input_setpoint_h[j])
    Optimal_slo_inter_heating=rbind.data.frame(Optimal_slo_inter_heating,Data_combine_heating)
    
  } 
}

#print(Optimal_slo_inter_heating)

# Heating figure visualization 
vertical_line <- data.frame(x = 16, y = 0)
Heating_scenario1 <- Heating_scenario[-1, ]
Predict_heating_True_h <-  as.list(unlist(Predict_heating_True))
Outdoor_Th_weight_list <- as.list(unlist(Outdoor_Th_weight_list))
heating <- as.data.frame(t(rbind.data.frame(Outdoor_Th_weight_list, Predict_heating_True_h)))
colnames(heating)[1] <- "Outdoor_T"
colnames(heating)[2] <- "Predicted_T"
rownames(heating) <- 1:nrow(heating)
heating <- as.data.frame(heating)
heating <- heating[-1, ]

g1 <- ggplot(Heating_scenario1, aes(x=Heating_scenario1$Tout, y = Heating_scenario1$MixedSetPoints)) +
  geom_point(color = "black", size = 3) +
  labs(x = "Outdoor Temperature", y = "Setpoint Temperature") +
  #theme_minimal() +
  scale_y_continuous(breaks = seq(15, 30, 1))+
  geom_point(aes(x=heating$Outdoor_T, y=heating$Predicted_T), color = "red", size = 3)
#g1



Cooling_scenario1 <- Cooling_scenario[-1, ]
Predict_cooling_True_c <-  as.list(unlist(Predict_cooling_True))
Outdoor_Tc_weight_list <- as.list(unlist(Outdoor_Tc_weight_list))
cooling <- as.data.frame(t(rbind.data.frame(Outdoor_Tc_weight_list, Predict_cooling_True_c)))
colnames(cooling)[1] <- "Outdoor_T"
colnames(cooling)[2] <- "Predicted_T"
rownames(cooling) <- 1:nrow(cooling)
cooling <- as.data.frame(cooling)
cooling <- cooling[-1, ]


#cooling figure visualization 
g2 <- ggplot(Cooling_scenario1, aes(x=Cooling_scenario1$Tout, y = Cooling_scenario1$MixedSetPoints)) +
  geom_point(color = "black", size = 3) +
  labs(x = "Outdoor Temperature", y = "Setpoint Temperature") +
  #theme_minimal() +
  scale_y_continuous(breaks = seq(15, 30, 1))+
  geom_point(aes(x=cooling$Outdoor_T, y=cooling$Predicted_T), color = "blue", size = 3)
#g2

#two figure combine
g3 <- ggplot() +
  geom_point(data = Cooling_scenario1 , aes(x = Tout, y = MixedSetPoints, color = "Actual Setpoint"),alpha = 0.9)+
  geom_point(data = cooling , aes(x=Outdoor_T, y=Predicted_T, color = "ComfortGPT(Cooling)"), alpha = 0.9)+
  geom_point(data = Heating_scenario1 , aes(x= Tout, y = MixedSetPoints, color = "Actual Setpoint"),alpha = 0.9) +
  geom_point(data = heating , aes(x=Outdoor_T, y=Predicted_T, color = "ComfortGPT(Heating)"), alpha = 0.9) +
  geom_vline(data = vertical_line, aes(xintercept = x), color = "red", linetype = "dashed") +
  labs(x = "Outdoor Temperature", y = "Setpoint Temperature", color = "Scenario") + 
  theme(axis.text.x = element_text(size = 17),  
        axis.text.y = element_text(size = 17),  
        axis.title.x = element_text(size = 17),  
        axis.title.y = element_text(size = 17))+
  theme(legend.position = "top") +
  theme(legend.text = element_text(size = 12))

g3 <- g3 +
  scale_color_manual(values = c("Actual Setpoint" = "black", "ComfortGPT(Cooling)" = "blue", "ComfortGPT(Heating)" = "red"))

g3

# c(0.01, 0.98),
      #legend.justification = c(0.01, 0.98))

#----------------
#Setpoint_prediction-write it in function

Input_OT <- 3 #user input outdoor temperature

ComfortGPT_setpoint_prediciton <- function(Input_OT, decision_value = 16) {
  if (Input_OT > decision_value) {
    Comfort_proflie_c <- tail(Optimal_slo_inter_cooling, 1)
    Predicted_setpoint_c <- Input_OT*Comfort_proflie_c$Slope + Comfort_proflie_c$Intercept
    return(Predicted_setpoint_c)
  } else{
    Comfort_proflie_h <- tail(Optimal_slo_inter_heating, 1)
    Predicted_setpoint_h <- Input_OT*Comfort_proflie_h$Slope + Comfort_proflie_h$Intercept
    return(Predicted_setpoint_h)
  } 
}
  
Predicted_setpoint <- ComfortGPT_setpoint_prediciton(Input_OT)
Predicted_setpoint