getwd()
setwd("C:/Users/ilyas/PycharmProjects/kai_stuff/ComfortGPT")# keep them in a same folder

# Source the R script that contains the ComfortGPT function
source("Updated function - 2 version of function.R") # Adjust this to match the exact filename

df_sample <- read.csv("case2.csv") # call it sample
df_new <- data.frame(Tout = df_sample$Tout, MixedSetPoints = df_sample$MixedSetPoints)#Just setpoint

results <- ComfortGPT(
  df = df_new,
) #setpointint

results <- ComfortGPT(
  df = df_new,
  Input_OT = 21
)


#TETS
latest_optimal_cooling <- results$latest_optimal_cooling
latest_optimal_heating <- results$latest_optimal_heating

latest_optimal_cooling$Slope*21+latest_optimal_cooling$Intercept