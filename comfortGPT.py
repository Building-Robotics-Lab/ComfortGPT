import os
import pandas as pd
import numpy as np


def ComfortGPT(df, Input_OT=None, alpha=0.8, threshold=5, cutoff=16):

    df_c_filename = "Slected_800_c-250.csv"
    df_h_filename = "Slected_800_h-250.csv"

    df_c_path = os.path.join(os.path.dirname(__file__), df_c_filename)
    df_h_path = os.path.join(os.path.dirname(__file__), df_h_filename)

    df_c = pd.read_csv(df_c_path, header=0)
    df_h = pd.read_csv(df_h_path, header=0)

    Error_250_h_list = []
    Outdoor_Th_weight_list = []
    Predict_heating_True = []
    true_error_heating = []

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

            if j != len(df) - 1:
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

    Optimal_slo_inter_heating = pd.DataFrame()
    for j in range(0, len(df)):
        if j == 0:
            Predict_250_h = df['Tout'][j] * df_h['Slope_heat'] + df_h['Intercept_heat']
            setpoint_list_h = np.repeat(df['MixedSetPoints'][j], 250)
            Error_250_h = (Predict_250_h - setpoint_list_h) ** 2
            Error_250_h_list.append(Error_250_h.tolist())
            matrix_from_nested_list_h = np.matrix(Error_250_h_list).T
            minindex_heating = np.argmin(np.sqrt(np.array(Error_250_h)))
            Data_combine_heating = pd.DataFrame({
                'Slope': df_h.loc[minindex_heating, 'Slope_heat'],
                'Intercept': df_h.loc[minindex_heating, 'Intercept_heat']
            }, index=[0])  # or replace 0 with a specific index if needed
            Optimal_slo_inter_heating = pd.concat([Optimal_slo_inter_heating, Data_combine_heating], ignore_index=True)
            Outdoor_Th_weight_list.append(df['Tout'][j])
            Predict_heating_True.append(0)
        else:
            Predicted_h = df['Tout'][j] * df_h['Slope_heat'][minindex_heating] + df_h['Intercept_heat'][minindex_heating]
            Predict_heating_True.append(Predicted_h)
            true_error_heating.append(abs(Predicted_h - df['MixedSetPoints'][j]))
            Predict_250_h = df['Tout'][j] * df_h['Slope_heat'] + df_h['Intercept_heat']
            setpoint_list_h = np.repeat(df['MixedSetPoints'][j], 250)
            Error_250_h = (Predict_250_h - setpoint_list_h) ** 2
            Error_250_h_list.append(Error_250_h.tolist())
            matrix_from_nested_list_h = np.matrix(Error_250_h_list).T

            matrix_from_nested_list_h.columns = [f'X{i+1}' for i in range(len(df['Tout']))]
            DF_nested_list_h = pd.DataFrame(matrix_from_nested_list_h)
            weights_h = [alpha ** i for i in range(0, DF_nested_list_h.shape[1])][::-1]
            Outdoor_Th_weight_list.append(df['Tout'][j])

            if j != len(df) - 1:
                Differences_h = abs(np.array(Outdoor_Th_weight_list) - df['Tout'][j+1])
                indices_h = np.where(Differences_h < threshold)[0]
                if len(indices_h) > 0:
                    new_weights_h = [alpha ** i for i in range(0, len(indices_h))][::-1]

                    max_values_h = np.maximum([weights_h[i] for i in indices_h], new_weights_h)
                    for i in range(len(indices_h)):
                        weights_h[indices_h[i]] = max_values_h[i]

                    temperature_weight_list_h = weights_h
                    temperature_weight_list_h = np.array(temperature_weight_list_h)
                    result_weight_h = (DF_nested_list_h.multiply(temperature_weight_list_h, axis=1))
                else:
                    result_weight_h = DF_nested_list_h.multiply(weights_h, axis=1)
            else:
                result_weight_h = DF_nested_list_h.multiply(weights_h, axis=1)
            minindex_heating = np.argmin(np.sqrt(np.sum(result_weight_h, axis=1)))
            Data_combine_heating = pd.DataFrame({
                'Slope': df_h.loc[minindex_heating, 'Slope_heat'],
                'Intercept': df_h.loc[minindex_heating, 'Intercept_heat']
            }, index=[0])  # or replace 0 with a specific index if needed
            Optimal_slo_inter_heating = pd.concat([Optimal_slo_inter_heating, Data_combine_heating], ignore_index=True)

    latest_optimal_cooling = Optimal_slo_inter_cooling.tail(1)
    latest_optimal_heating = Optimal_slo_inter_heating.tail(1)

    if Input_OT:
        if Input_OT > cutoff:
            # Use cooling scenario for prediction
            prediction = Input_OT * latest_optimal_cooling['Slope'].values[0] + latest_optimal_cooling['Intercept'].values[0]
            print(f"Using cooling pre-trained models. The prediction is: {prediction}")
        else:
            # Use heating scenario for prediction
            prediction = Input_OT * latest_optimal_heating['Slope'].values[0] + latest_optimal_heating['Intercept'].values[0]
            print(f"Using heating pre-trained models. The prediction is: {prediction}")
    else:
        print(f"Latest comfort profile for cooling season: The slope is: {latest_optimal_cooling['Slope'].values[0]} and the intercept is {latest_optimal_cooling['Intercept'].values[0]}. The Setpoint can be calculated by: Slope * Outdoor_temperature + Intercept")
        print(f"Latest comfort profile for heating season: The slope is: {latest_optimal_heating['Slope'].values[0]} and the intercept is {latest_optimal_heating['Intercept'].values[0]}. The Setpoint can be calculated by: Slope * Outdoor_temperature + Intercept")

    return [Optimal_slo_inter_cooling, Optimal_slo_inter_heating]
