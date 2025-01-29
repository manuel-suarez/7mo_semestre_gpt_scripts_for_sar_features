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
import esa_snappy
from esa_snappy import ProductIO, ProductUtils, GPF, HashMap
from osgeo import ogr, osr

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

# Extract vector data
print("Extracting windfield data...")
product_node = product.getVectorDataGroup()
print(type(product_node))
exit(1)
if product_node is None:
    print("No vector data group found.")
    exit(1)

# Loop through the vector data nodes and extract features
print(product_node.getNodeCount())

vector_data_node = None
for index in range(product_node.getNodeCount()):
    node = product_node.get(index)
    if node.getName() == "WindField":
        vector_data_node = node
        break
if vector_data_node is None:
    print("No VectorDataNodeProduct found.")
    exit(1)

print(f"Extracting vector data from: {vector_data_node.getName()}")
print(type(vector_data_node))
print(dir(vector_data_node))
exit(0)

# Prepare OGR for shapefile creation
driver = ogr.GetDriverByName("ESRI Shapefile")
if os.path.exists(output_shapefile):
    driver.DeleteDataSource(output_shapefile)
data_source = driver.CreateDataSource(output_shapefile)

# Create the shapefile layer with WGS84 spatial reference
spatial_ref = osr.SpatialReference()
spatial_ref.ImportFromEPSG(4326)
layer = data_source.CreateLayer("WindField_Point", spatial_ref, ogr.wkbPoint)

# Add fieldds to the shapefile
layer.CreateField(ogr.FieldDefn("speed", ogr.OFTReal))
layer.CreateField(ogr.FieldDefn("heading", ogr.OFTReal))

# Extract the features from the vector data node
for feature in vector_data_node.getFeatureCollection():
    geom = feature.getGeometry()
    attrs = feature.getAttributes()

    if geom is None:
        continue  # Skip invalid geometries

    # Create OGR point feature
    ogr_feature = ogr.Feature(layer.GetLayerDefn())
    point = ogr.Geometry(ogr.wkbPoint)
    point.AddPoint(geom.getLon(), geom.getLat())

    ogr_feature.SetGeometry(point)

    # Set attribute values
    ogr_feature.SetField("speed", attrs.get("speed", 0.0))
    ogr_feature.SetField("heading", attrs.get("heading", 0.0))

    layer.CreateFeature(ogr_feature)

# Save and close
data_source = None
print(f"Shapefile successfully saved: {output_shapefile}")
