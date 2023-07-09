# ComfortGPT

# Dependencies
Make sure to have the following packages installed using the command
- `pip install pandas`

# Inputs
The ComfortGPT function takes the following arguments:
- **df**: A dataframe that contains columns Tout (outdoor temperature) and Setpoint.
- **Input_OT**: An optional input which is the outdoor temperature. If provided, the function will return a setpoint prediction. If not, the function will print the latest comfort profiles.
- **Alpha**: Decay factor. Default is 0.8.
- **Threshold**: Temperature threshold. Default is 5.
- **Cutoff**: A cutoff temperature to switch between heating and cooling days. Default is 16.
- **Note**: Two csv files named "Slected_800_c-250.csv" and "Slected_800_h-250.csv" are necessary in the current directory for the function to run correctly. These files should contain the cooling and heating pre-trained models (i.e, Related intercept and slope)

# Outputs
The ComfortGPT function returns a list containing the following:
- **Optimal_slo_inter_cooling**: A dataframe that includes the optimal slope and intercept for the cooling days.
- **Optimal_slo_inter_heating**: A dataframe that includes the optimal slope and intercept for the heating scenario.
- **latest_optimal_cooling**: The most current intercept and slope for cooling days.
- **latest_optimal_heating**: The most current intercept and slope for heating days.

# Usage
- Clone the repository using `git clone 
