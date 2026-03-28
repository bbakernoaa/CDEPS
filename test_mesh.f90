program test_mesh
  use ESMF
  implicit none
  type(ESMF_Mesh) :: mesh
  integer :: rc
  call ESMF_Initialize(rc=rc)
  mesh = ESMF_MeshCreate(parametricDim=2, spatialDim=2, rc=rc)
  call ESMF_MeshAddNodes(mesh, nodeCount=4, nodeIds=[1,2,3,4], &
       nodeCoords=[0.0d0, 0.0d0, 1.0d0, 0.0d0, 1.0d0, 1.0d0, 0.0d0, 1.0d0], &
       nodeOwners=[0,0,0,0], rc=rc)
  call ESMF_MeshAddElements(mesh, elementCount=1, elementIds=[1], &
       elementTypes=[ESMF_MESHELEMTYPE_QUAD], elementConn=[1,2,3,4], rc=rc)
  call ESMF_Finalize(rc=rc)
end program test_mesh
