import os
import rasterio
import numpy as np
import geopandas as gpd

from skimage.io import imsave
from rasterio.features import rasterize
from scipy.interpolate import griddata

fname = "ASA_IMP_1PNESA20050425_075225_000000182036_00393_16479_0000"

base_path = os.path.expanduser("~")
data_path = os.path.join(base_path, "data", "cimat", "dataset-cimat", "temp4")
prod_path = os.path.join(data_path, fname)
tiff_path = os.path.join(data_path, fname + ".tif")

wind_path = os.path.join(prod_path, "wind_07.data", "vector_data")
wind_input_file = os.path.join(wind_path, "WindField.csv")
wind_output_file = os.path.join(wind_path, "WindField_2.csv")

# Open TIFF data and get shape
print("Open TIFF file")
with rasterio.open(tiff_path) as tiff_file:
    sar_image = tiff_file.read(1)
    sar_transform = tiff_file.transform
    sar_shape = sar_image.shape

# Open file to remove # characters and :Datatype marks
print("Open WindField CSV")
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

# Open wind CSV file
wind_gdf = gpd.read_file(wind_output_file)

# Extract wind field points and values
print("Get speed and coordinates values")
points = gpd.GeoSeries.from_wkt(wind_gdf["geometry"])
points = np.array([(geom.x, geom.y) for geom in points])
speed_values = wind_gdf["speed"].values

# Create interpolation grid (for SAR image)
print("Create interpolation grid")
x_coords = np.arange(0, sar_shape[1])
y_coords = np.arange(0, sar_shape[0])
x_grid, y_grid = np.meshgrid(x_coords, y_coords)
lon, lat = rasterio.transform.xy(sar_transform, y_grid, x_grid, offset="center")

grid_points = np.column_stack([lon.flatten(), lat.flatten()])

# Interpolate wind field values onto the SAR grid
print("Interpolate wind data")
interpolated_wind = griddata(
    points, speed_values, grid_points, method="linear", fill_value=0
)
interpolated_wind = interpolated_wind.reshape(sar_shape)

# Save wind field image
print("Save windfield output image")
imsave(
    os.path.join(prod_path, fname + "_wind.png"), interpolated_wind.astype(np.float32)
)
print("Done!")
