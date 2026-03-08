@EndUserText.label: 'CDS selection for VDM Diagrams'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_CE_VDMDIAGRAMCDS'

//  COMING SOON: This is a placeholder for the actual CDS entity that will be implemented in the future.
//  It is currently defined as a custom entity with the necessary fields to hold information about CDS views that are relevant for VDM diagrams.
//  It will be used for a Fiori Application that allows users to select CDS views for VDM diagrams and display their details.
define custom entity ZI_VDMDiagramCDS
{
  key cdsUpperCaseName : sxco_cds_object_name;
      cdsName          : sxco_cds_object_name;
      cdsDescription   : abap.char(60);
      cdsType          : abap.char(30);
}
