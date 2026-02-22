INTERFACE zif_vdm_plantuml_xco_adapter
  PUBLIC .

  METHODS get_cds_type
    IMPORTING
      !cds_name    TYPE sxco_cds_object_name
    RETURNING
      VALUE(type) TYPE zvdm_plantuml_cds_type .
  METHODS get_fields
    IMPORTING
      !cds_name      TYPE sxco_cds_object_name
    RETURNING
      VALUE(fields) TYPE sxco_t_cds_fields .
  METHODS get_associations
    IMPORTING
      !cds_name            TYPE sxco_cds_object_name
    RETURNING
      VALUE(associations) TYPE sxco_t_cds_associations .
  METHODS get_compositions
    IMPORTING
      !cds_name            TYPE sxco_cds_object_name
    RETURNING
      VALUE(compositions) TYPE sxco_t_cds_compositions .
  METHODS get_sources
    IMPORTING
      !cds_name       TYPE sxco_cds_object_name
    RETURNING
      VALUE(sources) TYPE sxco_t_cds_object_names .
  METHODS get_cds_name_from_ddl
    IMPORTING
      !cds_name          TYPE sxco_cds_object_name
    RETURNING
      VALUE(ddlcds_name) TYPE sxco_cds_object_name .
  METHODS get_cardinality
    IMPORTING
      cds_name            TYPE sxco_cds_object_name
      assocname          TYPE string
      hasparent          type abap_bool default abap_false
      currentCardinality TYPE if_xco_cds_association_content=>ts_cardinality
    RETURNING
      VALUE(cardinality) TYPE if_xco_cds_association_content=>ts_cardinality.

ENDINTERFACE.
