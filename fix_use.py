import re

with open('streams/dshr_strdata_mod.F90', 'r') as f:
    content = f.read()

# First, consolidate all ESMF use statements into one block if possible, or just fix the messed up ones.
# The previous sed might have made it hard to match. Let's just look at the first few lines.
lines = content.splitlines()
new_lines = []
skip = False
for line in lines:
    if skip:
        if '&' not in line:
            skip = False
        continue
    if 'use ESMF' in line or 'use pio' in line:
        if '&' in line:
            skip = True
        continue
    new_lines.append(line)

# Re-insert consolidated USE statements after line 5 (after "Obtain the model domain...")
final_lines = new_lines[:5]
final_lines.append('  use ESMF             , only : ESMF_Mesh, ESMF_RouteHandle, ESMF_Field, ESMF_FieldBundle, &')
final_lines.append('                             ESMF_Clock, ESMF_VM, ESMF_VMGet, ESMF_VMGetCurrent, &')
final_lines.append('                             ESMF_DistGrid, ESMF_SUCCESS, ESMF_MeshGet, ESMF_DistGridGet, &')
final_lines.append('                             ESMF_VMBroadCast, ESMF_MeshIsCreated, ESMF_MeshCreate, &')
final_lines.append('                             ESMF_CALKIND_NOLEAP, ESMF_CALKIND_GREGORIAN, &')
final_lines.append('                             ESMF_CalKind_Flag, ESMF_Time, ESMF_TimeInterval, &')
final_lines.append('                             ESMF_TimeIntervalGet, ESMF_TYPEKIND_R8, ESMF_FieldCreate, &')
final_lines.append('                             ESMF_FILEFORMAT_ESMFMESH, ESMF_FieldBundleCreate, &')
final_lines.append('                             ESMF_MESHLOC_ELEMENT, ESMF_FieldBundleAdd, &')
final_lines.append('                             ESMF_POLEMETHOD_ALLAVG, ESMF_EXTRAPMETHOD_NEAREST_STOD, &')
final_lines.append('                             ESMF_REGRIDMETHOD_BILINEAR, ESMF_REGRIDMETHOD_NEAREST_STOD, &')
final_lines.append('                             ESMF_REGRIDMETHOD_CONSERVE, ESMF_NORMTYPE_FRACAREA, ESMF_NORMTYPE_DSTAREA, &')
final_lines.append('                             ESMF_ClockGet, operator(-), operator(==), &')
final_lines.append('                             ESMF_Grid, ESMF_GridCreateNoPeriDimUfrm, ESMF_GridGetCoord, ESMF_GridGet, &')
final_lines.append('                             ESMF_INDEX_GLOBAL, ESMF_COORDSYS_SPH_DEG, &')
final_lines.append('                             ESMF_FieldReGridStore, ESMF_FieldRedistStore, ESMF_UNMAPPEDACTION_IGNORE, &')
final_lines.append('                             ESMF_TERMORDER_SRCSEQ, ESMF_FieldRegrid, ESMF_FieldFill, ESMF_FieldIsCreated, &')
final_lines.append('                             ESMF_REGION_TOTAL, ESMF_FieldGet, ESMF_TraceRegionExit, ESMF_TraceRegionEnter, &')
final_lines.append('                             ESMF_LOGMSG_INFO, ESMF_LogWrite')

final_lines.append('  use pio              , only : file_desc_t, iosystem_desc_t, io_desc_t, var_desc_t, &')
final_lines.append('                             pio_openfile, pio_closefile, pio_nowrite, &')
final_lines.append('                             pio_seterrorhandling, pio_initdecomp, pio_freedecomp, &')
final_lines.append('                             pio_inquire, pio_inq_varid, pio_inq_varndims, pio_inq_vardimid, pio_inquire_variable, &')
final_lines.append('                             pio_inq_dimlen, pio_inq_vartype, pio_inq_dimname, pio_inq_dimid, &')
final_lines.append('                             pio_double, pio_real, pio_int, pio_offset_kind, pio_get_var, &')
final_lines.append('                             pio_read_darray, pio_setframe, pio_fill_double, pio_get_att, pio_inq_att, &')
final_lines.append('                             PIO_BCAST_ERROR, PIO_RETURN_ERROR, PIO_NOERR, PIO_INTERNAL_ERROR, PIO_SHORT')

final_lines.extend(new_lines[5:])

with open('streams/dshr_strdata_mod.F90', 'w') as f:
    f.write("\n".join(final_lines))
