import os
import pandas as pd
import numpy as np

# This is the call function part
df_sample = pd.read_csv('Case2.csv', header=0)
df_new = df_sample[['Tout', 'MixedSetPoints']].copy()
Input_OT = 21


def ComfortGPT(df, Input_OT, alpha=0.8, threshold=5, cutoff=16):

    df_c_filename = "Slected_800_c-250.csv"
    df_h_filename = "Slected_800_h-250.csv"

    df_c_path = os.path.join(os.path.dirname(__file__), df_c_filename)
    df_h_path = os.path.join(os.path.dirname(__file__), df_h_filename)

    df_c = pd.read_csv(df_c_path, header=0)
    df_h = pd.read_csv(df_h_path, header=0)

    Error_250_c_list = []

    Outdoor_Tc_weight_list = []
    Predict_cooling_True = []
    true_error_cooling = []

    Optimal_slo_inter_cooling = pd.DataFrame()
    for j in range(0, len(df)):
        if j == 0:
            Predict_250_c = df['Tout'][j] * df_c['Slope_cool'] + df_c['Intercept_cool']
            setpoint_list = np.repeat(df['MixedSetPoints'][j], 250)

            Error_250_c = (Predict_250_c - setpoint_list) ** 2
            Error_250_c_list.append(Error_250_c.tolist())
            matrix_from_nested_list = np.matrix(Error_250_c_list).T
            minindex_cooling = np.argmin(np.sqrt(np.array(Error_250_c)))
            Data_combine_cooling = pd.DataFrame({
                'Slope': df_c.loc[minindex_cooling, 'Slope_cool'],
                'Intercept': df_c.loc[minindex_cooling, 'Intercept_cool'],
                'Related_Tout': df.loc[j, 'Tout'],
                'Related_input_setpoint': df.loc[j, 'MixedSetPoints']
            }, index=[0])  # or replace 0 with a specific index if needed
            Optimal_slo_inter_cooling = pd.concat([Optimal_slo_inter_cooling, Data_combine_cooling], ignore_index=True)
            Outdoor_Tc_weight_list.append(df['Tout'][j])
            Predict_cooling_True.append(0)
        else:
            Predicted_c = df['Tout'][j] * df_c['Slope_cool'][minindex_cooling] + df_c['Intercept_cool'][minindex_cooling]
            Predict_cooling_True.append(Predicted_c)
            true_error_cooling.append(abs(Predicted_c - df['MixedSetPoints'][j]))
            Predict_250_c = df['Tout'][j] * df_c['Slope_cool'] + df_c['Intercept_cool']
            setpoint_list = np.repeat(df['MixedSetPoints'][j], 250)
            Error_250_c = (Predict_250_c - setpoint_list) ** 2
            Error_250_c_list.append(Error_250_c.tolist())
            matrix_from_nested_list = np.matrix(Error_250_c_list).T

            matrix_from_nested_list.columns = [f'X{i+1}' for i in range(len(df['Tout']))]
            DF_nested_list = pd.DataFrame(matrix_from_nested_list)
            weights = [alpha ** i for i in range(0, DF_nested_list.shape[1])][::-1]
            Outdoor_Tc_weight_list.append(df['Tout'][j])

            if j != len(df):
                Differences = abs(np.array(Outdoor_Tc_weight_list) - df['Tout'][j+1])
                indices = np.where(Differences < threshold)[0]
                if len(indices) > 0:
                    new_weights = [alpha ** i for i in range(0, len(indices))][::-1]

                    max_values = np.maximum([weights[i] for i in indices], new_weights)
                    for i in range(len(indices)):
                        weights[indices[i]] = max_values[i]

                    temperature_weight_list = weights
                    temperature_weight_list = np.array(temperature_weight_list)
                    result_weight = (DF_nested_list.multiply(temperature_weight_list, axis=1))
                else:
                    result_weight = DF_nested_list.multiply(weights, axis=1)
            else:
                result_weight = DF_nested_list.multiply(weights, axis=1)
            minindex_cooling = np.argmin(np.sqrt(np.sum(result_weight, axis=1)))
            Data_combine_cooling = pd.DataFrame({
                'Slope': df_c.loc[minindex_cooling, 'Slope_cool'],
                'Intercept': df_c.loc[minindex_cooling, 'Intercept_cool'],
                'Related_Tout': df.loc[j, 'Tout'],
                'Related_input_setpoint': df.loc[j, 'MixedSetPoints']
            }, index=[0])  # or replace 0 with a specific index if needed
            Optimal_slo_inter_cooling = pd.concat([Optimal_slo_inter_cooling, Data_combine_cooling], ignore_index=True)



ComfortGPT(df=df_new, Input_OT=Input_OT)
