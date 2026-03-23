import netCDF4 as nc
import numpy as np

# Create a new NetCDF file
dataset = nc.Dataset('test_stream.nc', 'w', format='NETCDF4')

# Create dimensions
time_dim = dataset.createDimension('time', None)
lat_dim = dataset.createDimension('lat', 2)
lon_dim = dataset.createDimension('lon', 2)

# Create variables
time_var = dataset.createVariable('time', np.float64, ('time',))
lat_var = dataset.createVariable('lat', np.float32, ('lat',))
lon_var = dataset.createVariable('lon', np.float32, ('lon',))
data_var = dataset.createVariable('data', np.float32, ('time', 'lat', 'lon'))

# Add attributes
time_var.units = 'days since 2000-01-01 00:00:00'
time_var.calendar = 'noleap'
time_var.long_name = 'time'

lat_var.units = 'degrees_north'
lat_var.long_name = 'latitude'

lon_var.units = 'degrees_east'
lon_var.long_name = 'longitude'

data_var.units = 'K'
data_var.long_name = 'temperature'

# Assign values
time_var[:] = [0.0, 1.0, 2.0]
lat_var[:] = [-90.0, 90.0]
lon_var[:] = [0.0, 180.0]
data_var[0, :, :] = [[273.15, 273.15], [273.15, 273.15]]
data_var[1, :, :] = [[274.15, 274.15], [274.15, 274.15]]
data_var[2, :, :] = [[275.15, 275.15], [275.15, 275.15]]

# Close the file
dataset.close()
print("test_stream.nc generated successfully.")