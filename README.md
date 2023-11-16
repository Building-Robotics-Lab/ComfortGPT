# ComfortGPT

# About
ComfortGPT employs generative pre-trained models built on the data from thousands of ECOBEE thermostat users, to directly predict temperature setpoints while minimizing the reliance on occupant interactions.
Check out the interactive ComfortGPT website at [BRL - ComfortGPT](https://building-robotics-lab.github.io/brlab/#/comfortgpt)

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
- *Note: For the best user experience, use PyCharm or Jupyter Notebook IDE*
- Clone the repository using `git clone https://github.com/Building-Robotics-Lab/ComfortGPT.git`
- In the `Call function.py` file, modify the value assigned to the dataframe variable to reflect the location of your CSV file by replacing '../example.csv' with the file path of your CSV file. <br /><br />

- You can call the ComfortGPT function in two different ways in `Call function.py`:
  - Without **Input_OT**: This will return the latest comfort profiles for both cooling and heating scenarios
    - `results_without_InputOT = ComfortGPT(df=df_new)` <br /><br />
  - With **Input_OT**: This will return the setpoint prediction for the given outdoor temperature:
    - `results_with_InputOT = ComfortGPT(df=df_new, Input_OT=21)`
<br /><br />
- Run the `Call function.py` file to get the output from the ComfortGPT function
