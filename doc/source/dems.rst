.. _dems:

Data Emissions (DEMS)
=====================

DEMS is used to provide emission forcing data to other prognostic components.
It supports both gridded data streams and point source data.

.. _dems-datamodes:

--------------------
Supported Data Modes
--------------------

DEMS has its own set of supported ``datamode`` values that appear in the
``dems_in`` namelist input. The datamode specifies what additional
operations need to be done by DEMS on the input streams defined in the
``dems.streams.xml`` file.

CLMNCEP
  - In conjunction with NCEP climatological atmosphere data, provides
    the atmosphere forcing favored by the CESM Land Model Working Group.

CORE2_NYF
  - Coordinated Ocean-ice Reference Experiments (CORE) Version 2
    Normal Year Forcing.

CORE2_IAF
  - CORE Version 2 interannual forcing.

CORE_IAF_JRA
  - JRA-55 interannual year forcing.

ERA5
  - Fifth generation ECMWF atmospheric reanalysis.

SIMPLE
  - Namelist-configurable, constant emissions forcing for simple experiments.

CPLHIST
  - Forcing data from coupler history files.

----------------------
Point Source Handling
----------------------

DEMS supports point source data provided in a UGRID-compliant NetCDF file.
Point sources are handled via the ``point_source_mode`` namelist variable:

collapsed
  - Point sources are spatially mapped to the model grid and their fluxes
    are summed into the corresponding grid cells. The resulting gridded
    field is exported as ``Point_Flux``.

uncollapsed
  - Point sources maintain their unique identities and are exported using
    an ``ESMF_LocStream``. This is useful when multiple sources share the
    same grid cell but must be treated separately. The export field is
    named ``Point_Flux_Uncollapsed``.

The point source data file should follow the UGRID convention, using
dimensions like ``nNodes`` and variables such as ``node_lat``, ``node_lon``,
and ``flux``.

.. _dems-cime-vars:

--------------------------
Configuring DEMS from CIME
--------------------------

If CDEPS is coupled to the CIME-CCS then the CIME ``$CASEROOT`` xml
variable ``DEMS_MODE`` will be generated based on the compset
specification ``DEMS%{DEMS_MODE}``.

The following DEMS specific CIME-CCS xml variables appear in ``$CASEROOT/env_run.xml``:

DEMS_MODE
   - Mode for data emissions component (e.g., CORE2_NYF, CLM_QIAN, ERA5).

DEMS_PRESAERO
   - Prescribed aerosol forcing mode.

DEMS_PRESNDEP
   - Prescribed nitrogen deposition forcing mode.

DEMS_PRESO3
   - Prescribed ozone forcing mode.

DEMS_TOPO
   - Surface topography forcing.

DEMS_CO2_TSERIES
   - CO2 time series mode.

DEMS_YR_START
   - Starting year to loop data over.

DEMS_YR_END
   - Ending year to loop data over.

DEMS_YR_ALIGN
   - Simulation year corresponding to ``DEMS_YR_START``.

DEMS_SKIP_RESTART_READ
   - If set to true, DEMS restarts will not be read on a continuation run.

-------------------
Namelist Variables
-------------------

The ``dems_in`` namelist (``dems_nml`` group) includes:

- ``datamode``: Data mode (see above).
- ``point_source_mode``: 'collapsed' or 'uncollapsed'.
- ``point_source_filename``: Path to the point source NetCDF file.
- ``model_meshfile``: Path to the model mesh file.
- ``model_maskfile``: Path to the model mask file.
- ``nx_global``, ``ny_global``, ``nz_global``: Global grid dimensions.
- ``export_all``: If true, export all fields regardless of connection status.
