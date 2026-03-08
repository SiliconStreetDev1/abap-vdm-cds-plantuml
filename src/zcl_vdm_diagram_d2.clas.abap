"! <p class="shorttext synchronized">VDM D2 Lang Specific Renderer</p>
"! © 2026 Silicon Street Limited. All Rights Reserved.
"!
"! Implements the hook interface to output modern D2 declarative syntax.
CLASS zcl_vdm_diagram_d2 DEFINITION PUBLIC INHERITING FROM zcl_vdm_diagram_base FINAL CREATE PUBLIC.
  PUBLIC SECTION.

    " =========================================================================
    " D2-SPECIFIC FORMATTING OPTIONS
    " =========================================================================
    TYPES: BEGIN OF ty_format,
             direction     TYPE string,    " Layout flow: 'down', 'up', 'right', 'left'
             layout_engine TYPE string,    " Engine to use: 'elk' (default) or 'dagre'
             sketch_mode   TYPE abap_bool, " True to render as a hand-drawn whiteboard sketch
             primary_color TYPE string,    " Hex code for the focal entity background (e.g., '#e1f5fe')
           END OF ty_format.

    METHODS constructor IMPORTING format TYPE ty_format OPTIONAL.

    " =========================================================================
    " HOOK REDEFINITIONS
    " =========================================================================
    METHODS zif_vdm_diagram_hooks~on_start REDEFINITION.
    METHODS zif_vdm_diagram_hooks~on_end REDEFINITION.
    METHODS zif_vdm_diagram_hooks~on_entity_start REDEFINITION.
    METHODS zif_vdm_diagram_hooks~on_entity_end REDEFINITION.
    METHODS zif_vdm_diagram_hooks~on_base_elements REDEFINITION.
    METHODS zif_vdm_diagram_hooks~on_fields REDEFINITION.
    METHODS zif_vdm_diagram_hooks~on_associations REDEFINITION.
    METHODS zif_vdm_diagram_hooks~on_relationship REDEFINITION.
    METHODS zif_vdm_diagram_hooks~on_legend REDEFINITION.

  PRIVATE SECTION.
    DATA format TYPE ty_format.
ENDCLASS.



CLASS ZCL_VDM_DIAGRAM_D2 IMPLEMENTATION.


  METHOD constructor.
    super->constructor( ).
    me->format = format.

    " -------------------------------------------------------------------------
    " SMART DEFAULTS FOR D2 RENDERING
    " -------------------------------------------------------------------------
    " PORT SNAPPING FIX: Default to 'right' (Horizontal Layout)
    " D2 struggles to route row-level arrows cleanly in vertical ('down') layouts.
    " A left-to-right flow allows lines to cleanly exit the sides of the sql_table.
    IF me->format-direction IS INITIAL.
      me->format-direction = 'right'.
    ENDIF.

    " ENGINE FIX: Default to 'elk'
    " Dagre (D2's default engine) miscalculates table row heights, causing lines
    " to float. ELK is specifically designed for complex port routing.
    IF me->format-layout_engine IS INITIAL.
      me->format-layout_engine = 'elk'.
    ENDIF.

    " Default primary focal entity color
    IF me->format-primary_color IS INITIAL.
      me->format-primary_color = 'gray'.
    ENDIF.
  ENDMETHOD.


  METHOD zif_vdm_diagram_hooks~on_associations.
    " Render Associations as rows inside the sql_table so lines can connect to them
    IF selection-associations_fields = abap_true.
      LOOP AT association_aliases INTO DATA(assoc).
        " ---------------------------------------------------------------------
        " GHOST ROW FIX: Force uppercase and remove whitespace
        " D2 is strictly case-sensitive. If the row name doesn't exactly match
        " the relationship anchor, D2 creates invisible "ghost rows".
        " ---------------------------------------------------------------------
        DATA(clean_assoc) = to_upper( condense( assoc ) ).

        " Label the type as 'association' for clarity inside the table box
        add_text( |  "{ clean_assoc }": association| ).
      ENDLOOP.
    ENDIF.
  ENDMETHOD.


  METHOD zif_vdm_diagram_hooks~on_base_elements.
    " Skipped: D2 sql_tables expect strict Key:Value pairs. Adding arbitrary
    " text blocks like union/base sources breaks the visual shape.
  ENDMETHOD.


  METHOD zif_vdm_diagram_hooks~on_end.
    " D2 requires no closing tags for the document itself, so this remains empty.
  ENDMETHOD.


  METHOD zif_vdm_diagram_hooks~on_entity_end.
    " Close the sql_table shape definition block
    add_text( '}' ).
  ENDMETHOD.


  METHOD zif_vdm_diagram_hooks~on_entity_start.
    " -------------------------------------------------------------------------
    " NAMESPACE FIX: Always wrap the alias in double quotes
    " This protects SAP namespaces (like /DMO/I_FLIGHT) from breaking the D2 parser.
    " -------------------------------------------------------------------------
    add_text( |"{ alias }": \{| ).

    " Utilize D2's native 'sql_table' shape
    add_text( '  shape: sql_table' ).

    " Apply the global 'primary' class if this is the root entity
    IF is_focal_entity = abap_true.
      add_text( '  class: primary' ).
    ENDIF.
  ENDMETHOD.


  METHOD zif_vdm_diagram_hooks~on_fields.
    " Render Primary Keys
    IF selection-keys = abap_true.
      LOOP AT key_fields INTO DATA(key).
        " Quoted field names protect underscores (e.g., _DATA).
        " D2 constraint applies the key visual indicator.
        add_text( |  "{ key }": * \{ constraint: primary_key \}| ).
      ENDLOOP.
    ENDIF.

    " Render Standard Fields
    IF selection-fields = abap_true.
      LOOP AT standard_fields INTO DATA(field).
        " Dashes represent standard columns in D2 sql_tables
        add_text( |  "{ field }": -| ).
      ENDLOOP.
    ENDIF.
  ENDMETHOD.


  METHOD zif_vdm_diagram_hooks~on_legend.
    " Skipped: D2 does not natively support floating legends like PlantUML.
  ENDMETHOD.


  METHOD zif_vdm_diagram_hooks~on_relationship.
    " Determine connection line color logically based on relationship type
    DATA(color) = SWITCH string( relationship_type
      WHEN zcl_vdm_diagram_generator=>c_relation_type-association OR zcl_vdm_diagram_generator=>c_relation_type-composition
        THEN COND #( WHEN is_parent_entity = abap_true OR has_parent_entity = abap_true THEN 'blue' ELSE 'green' )
      ELSE 'black' ).

    " Create dashed lines specifically for Inheritance
    DATA(arrow_style) = SWITCH string( relationship_type
      WHEN zcl_vdm_diagram_generator=>c_relation_type-inheritance THEN 'style.stroke-dash: 5'
      ELSE '' ).

    " -------------------------------------------------------------------------
    " THE CONNECTION FIX: Strict "Table"."Field" notation with forced casing
    " -------------------------------------------------------------------------
    " 1. Clean the alias exactly the same way we did in on_associations
    DATA(clean_assoc_alias) = to_upper( condense( association_alias ) ).

    " 2. Build the anchor. By quoting BOTH the table and the field ("Table"."Field"),
    " D2 knows exactly which row inside the sql_table the arrow should originate from.
    DATA(source_anchor) = COND string(
      WHEN selection-associations_fields = abap_true AND clean_assoc_alias IS NOT INITIAL
        THEN |"{ source_alias }"."{ clean_assoc_alias }"|
        ELSE |"{ source_alias }"| ).

    " 3. Prevent a syntax error if cardinality is empty by formatting the label cleanly
    DATA(label_part) = COND string(
      WHEN cardinality_text IS NOT INITIAL
        THEN |: "{ cardinality_text }"|
        ELSE '' ).

    " 4. Render the final connection string (e.g., "I_FLIGHT"."_CARRIER" -> "I_CARRIER" : "[1..1]" { )
    add_text( |{ source_anchor } -> "{ target_alias }"{ label_part } \{| ).

    " Apply edge styling
    add_text( |  style.stroke: { color }| ).
    IF arrow_style IS NOT INITIAL.
      add_text( |  { arrow_style }| ).
    ENDIF.

    add_text( '}' ).
  ENDMETHOD.


  METHOD zif_vdm_diagram_hooks~on_start.
    " -------------------------------------------------------------------------
    " GLOBAL D2 CONFIGURATION
    " -------------------------------------------------------------------------
    " Inject the requested layout engine into the file's global vars.
    " Escaping the curly braces \{ \} is required in ABAP string templates.
    add_text( |vars: \{ d2-config: \{ layout-engine: { format-layout_engine } \} \}| ).

    " Apply the global layout direction for the entire D2 board
    add_text( |direction: { format-direction }| ).

    " Apply hand-drawn sketch mode if requested by the user
    IF format-sketch_mode = abap_true.
      add_text( 'sketch: true' ).
    ENDIF.

    " Define global class styles for reusability.
    " 'primary' class applies the requested background color to focal entities.
    add_text( 'classes: {' ).
    add_text( |  primary: \{ style.fill: "{ format-primary_color }" \}| ).
    add_text( '}' ).
  ENDMETHOD.
ENDCLASS.
