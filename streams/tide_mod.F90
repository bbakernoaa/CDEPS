module tide_mod

  use dshr_strdata_mod, only : shr_strdata_type, shr_strdata_init_from_inline, shr_strdata_advance

  implicit none
  private

  public :: tide_init
  public :: tide_advance

contains

  subroutine tide_init(sdat, my_task, logunit, compname, rc, &
       model_clock, model_mesh, &
       stream_meshFile, stream_lev_dimname, stream_mapalgo, &
       stream_filenames, stream_fldListFile, stream_fldListModel, &
       stream_yearFirst, stream_yearLast, stream_yearAlign, &
       stream_offset, stream_taxMode, stream_dtlimit, stream_tintalgo, &
       stream_src_mask, stream_dst_mask, stream_name)

    use shr_kind_mod, only : r8 => shr_kind_r8

    use esmf, only : ESMF_Mesh, ESMF_Clock

    type(shr_strdata_type), intent(inout) :: sdat
    integer, intent(in) :: my_task
    integer, intent(in) :: logunit
    character(len=*), intent(in) :: compname
    integer, intent(out) :: rc
    type(ESMF_Clock), intent(in) :: model_clock
    type(ESMF_Mesh), intent(in) :: model_mesh
    character(len=*), intent(in) :: stream_meshFile
    character(len=*), intent(in) :: stream_lev_dimname
    character(len=*), intent(in) :: stream_mapalgo
    character(len=*), intent(in) :: stream_filenames(:)
    character(len=*), intent(in) :: stream_fldListFile(:)
    character(len=*), intent(in) :: stream_fldListModel(:)
    integer, intent(in) :: stream_yearFirst
    integer, intent(in) :: stream_yearLast
    integer, intent(in) :: stream_yearAlign
    integer, intent(in) :: stream_offset
    character(len=*), intent(in) :: stream_taxMode
    real(r8), intent(in) :: stream_dtlimit
    character(len=*), intent(in) :: stream_tintalgo
    integer, intent(in), optional :: stream_src_mask
    integer, intent(in), optional :: stream_dst_mask
    character(len=*), intent(in) :: stream_name

    call shr_strdata_init_from_inline(sdat, my_task, logunit, compname, &
         model_clock, model_mesh, &
         stream_meshFile, stream_lev_dimname, stream_mapalgo, &
         stream_filenames, stream_fldListFile, stream_fldListModel, &
         stream_yearFirst, stream_yearLast, stream_yearAlign, &
         stream_offset, stream_taxMode, stream_dtlimit, stream_tintalgo, &
         stream_src_mask, stream_dst_mask, stream_name, rc)

  end subroutine tide_init

  subroutine tide_advance(sdat, ymd, tod, logunit, istr, timers, rc)
    use dshr_strdata_mod, only : shr_strdata_type
    type(shr_strdata_type), intent(inout) :: sdat
    integer, intent(in) :: ymd
    integer, intent(in) :: tod
    integer, intent(in) :: logunit
    character(len=*), intent(in) :: istr
    logical, intent(in) :: timers
    integer, intent(out) :: rc

    call shr_strdata_advance(sdat, ymd, tod, logunit, istr, timers, rc)

  end subroutine tide_advance

end module tide_mod