import pandas as pd
from comfortGPT import ComfortGPT

# This is the call function part
df_sample = pd.read_csv('../example.csv', header=0)  # Input your sample data file
df_new = df_sample[['Tout', 'Setpoint']].copy()

results_without_InputOT = ComfortGPT(df=df_new)

results_with_InputOT = ComfortGPT(df=df_new, Input_OT=21)
