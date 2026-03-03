#ifndef CDEPS_INTERFACE_H
#define CDEPS_INTERFACE_H

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @file cdeps_interface.h
 * @brief C/C++ interface to CDEPS inline streams.
 *
 * This header provides a high-level API for using CDEPS data streams within
 * a model that manages its own ESMF components, clocks, and meshes.
 */

/**
 * @brief Initialize CDEPS inline streams.
 *
 * @param gcomp_ptr Opaque pointer to the ESMF_GridComp object.
 * @param clock_ptr Opaque pointer to the ESMF_Clock object.
 * @param mesh_ptr Opaque pointer to the ESMF_Mesh object.
 * @param stream_path Path to the stream configuration file.
 * @param rc Return code (ESMF_SUCCESS on success).
 */
void cdeps_init(void* gcomp_ptr, void* clock_ptr, void* mesh_ptr, const char* stream_path, int* rc);

/**
 * @brief Advance CDEPS inline streams to the current model time.
 *
 * @param clock_ptr Opaque pointer to the ESMF_Clock object.
 * @param rc Return code (ESMF_SUCCESS on success).
 */
void cdeps_advance(void* clock_ptr, int* rc);

/**
 * @brief Get a pointer to a field's data for a given stream.
 *
 * @param stream_idx Index of the stream (1-based).
 * @param fldname Name of the field.
 * @param data_ptr Pointer to the field data (output).
 * @param rc Return code (ESMF_SUCCESS on success).
 */
void cdeps_get_field_ptr(int stream_idx, const char* fldname, double** data_ptr, int* rc);

#ifdef __cplusplus
}
#endif

#endif /* CDEPS_INTERFACE_H */
