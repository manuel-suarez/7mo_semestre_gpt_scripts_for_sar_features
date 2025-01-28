import os
import sys
import rasterio
import numpy as np
import geopandas as gpd

from skimage.io import imsave
from rasterio.features import rasterize
from scipy.interpolate import griddata
from matplotlib import pyplot as plt

# Add SNAPPY installation path
sys.path.append("/home/est_posgrado_manuel.suarez/.snap/snap-python")
from esa_snappy import ProductIO, ProductUtils, GPF, HashMap
from osgeo import ogr

fname = "ASA_IMP_1PNESA20050425_075225_000000182036_00393_16479_0000"

base_path = os.path.expanduser("~")
data_path = os.path.join(base_path, "data", "cimat", "dataset-cimat", "temp4")
prod_path = os.path.join(data_path, fname)

# Input and output file paths
input_beamfile = os.path.join(prod_path, "wind_07.dim")
output_shapefile = os.path.join(prod_path, "WindField_Point.shp")

# Load BEAM-DIMAP product...
print("Loading BEAM-DIMAP file...")
product = ProductIO.readProduct(input_beamfile)
if product is None:
    print("Error: could not load product.")
    exit(1)
print(dir(product))

# Extract vector data
print("Extracting windfield data...")
vector_data_group = product.getVectorDataGroup()
if not vector_data_group:
    print("No vector data group found.")
    exit(1)

# Loop through the vector data nodes and extract features
vector_data_node = vector_data_group.get(2)
print(f"Extracting vector data from: {vector_data_node.getName()}")
