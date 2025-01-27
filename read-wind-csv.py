import os
import pandas as pd
import geopandas as gpd

base_path = os.path.expanduser("~")
data_path = os.path.join(base_path, "data", "cimat", "dataset-cimat", "temp4")
prod_path = os.path.join(
    data_path, "ASA_IMP_1PNESA20050425_075225_000000182036_00393_16479_0000"
)

wind_path = os.path.join(prod_path, "wind_07.data", "vector_data")
wind_input_file = os.path.join(wind_path, "WindField.csv")
wind_output_file = os.path.join(wind_path, "WindField_2.csv")

# Open file to remove # characters and :Datatype marks
with open(wind_input_file, "r") as input_file, open(
    wind_output_file, "w"
) as output_file:
    for index, line in enumerate(input_file):
        if line.startswith("#"):
            continue
        if index == 3:
            line = (
                line.replace(":String", "").replace(":Double", "").replace(":Point", "")
            )
        output_file.write(line)

wind_ds = gpd.read_file(wind_output_file)
for index, row in wind_ds.iterrows():
    print(index, row)
    geometry = row.geometry
    speed = row.speed
    print(geometry, speed)
