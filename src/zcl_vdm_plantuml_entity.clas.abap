"! <p class="shorttext synchronized">VDM PlantUML Generator</p>
"! © 2026 Silicon Street Limited. All Rights Reserved.
"!
"! USAGE TERMS:
"! 1. INTERNAL USE: Permission is granted to use this code for internal
"!    business documentation purposes within a single organization at no cost.
"! 2. NON-REDISTRIBUTION: You may NOT redistribute, sell, or include this
"!    source code (or derivatives thereof) in any commercial software or library.
"! 3. PAID SERVICES: Use of this code to provide paid consulting or
"!    documentation services to third parties requires a Commercial License.
"! 4. MODIFICATIONS: Any modifications remain subject to this license.
"!
"! DISCLAIMER: THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.
"! IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
"! LIABILITY ARISING FROM THE USE OF THE SOFTWARE.
"!
"! FOR COMMERCIAL LICENSING INQUIRIES: admin@siliconst.co.nz

CLASS zcl_vdm_plantuml_entity DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_format_options,
             ortho      TYPE abap_bool, " Use 90-degree straight lines
             polyline   TYPE abap_bool,
             spaced_out TYPE abap_bool, " Increase gaps between entities
             staggered  TYPE abap_bool, " Force lines to different sides (Left/Right)
             modern type abap_bool, " Use modern styling with round corners and no shadows
           END OF ty_format_options.

    METHODS build RETURNING VALUE(plantuml) TYPE string_table.
    METHODS constructor IMPORTING
                          hierarchies TYPE zcl_vdm_plantuml_generator=>tty_cds_hierarchy
                          selection   TYPE zcl_vdm_plantuml_generator=>ty_selection
                          format      TYPE ty_format_options OPTIONAL.
  PROTECTED SECTION.

    DATA hierachies TYPE zcl_vdm_plantuml_generator=>tty_cds_hierarchy .
    DATA plantuml TYPE string_table .
    DATA selection TYPE zcl_vdm_plantuml_generator=>ty_selection .
    DATA format TYPE ty_format_options.


    METHODS _start .
    METHODS _legend .
    METHODS _entity .

    METHODS _end .
    METHODS _add
      IMPORTING
        !plantuml TYPE string .
    METHODS _getfieldname
      IMPORTING
        !field           TYPE REF TO if_xco_cds_field
      RETURNING
        VALUE(fieldname) TYPE string .
  PRIVATE SECTION.
    METHODS _fields
      IMPORTING
        hierarchy TYPE zcl_vdm_plantuml_generator=>ty_cds_hierarchy.
    METHODS _associations
      IMPORTING
        hierarchy TYPE zcl_vdm_plantuml_generator=>ty_cds_hierarchy.
    METHODS _relationships.
    METHODS _base
      IMPORTING
        hierarchy TYPE zcl_vdm_plantuml_generator=>ty_cds_hierarchy.

ENDCLASS.



CLASS ZCL_VDM_PLANTUML_ENTITY IMPLEMENTATION.


  METHOD build.
    " Primary method to build the PlantUML representation.

    " ---> Start the PlantUML diagram with the necessary header
    _start( ).

    " ---> Construct the entity definitions
    _entity( ).

    " ---> Build relationships between entities
    _relationships( ).

    " ---> Add Legend
    _legend( ).

    " ---> End PlantUML
    _end( ).

    plantuml = me->plantuml.
  ENDMETHOD.


  METHOD constructor.
    "Set Globals for Class
    me->hierachies = hierarchies.
    me->selection = selection.
    me->format = format.   " Additional formatting options
  ENDMETHOD.


  METHOD _add.
    APPEND plantuml TO me->plantuml.
  ENDMETHOD.


  METHOD _end.
    _add( '@enduml' ).
  ENDMETHOD.


  METHOD _entity.

    LOOP AT hierachies ASSIGNING FIELD-SYMBOL(<hierarchy>).

      " Add Entity with Alias and Color if it's the primary entity
      IF to_upper( selection-cds_name ) = <hierarchy>-cds_name_uppercase. " Primary entity colored light blue
        _add( |entity "{ <hierarchy>-alias }" #LightBlue| ).
      ELSE.
        _add( |entity "{ <hierarchy>-alias }"| ).
      ENDIF.

      _add( '{' ). " Opening Bracket so start of Entity Content

      " Build Base
      _base( <hierarchy> ).

      " Build fields ( keys and non-keys )
      _fields(  <hierarchy> ).

      " Build Associations block (text-only list)
      _associations( <hierarchy> ).

      _add( '}' ). " Closing Bracket so end of Entity Content

    ENDLOOP.
  ENDMETHOD.


  METHOD _getfieldname.

    "Set Field name to Alias if it exists
    DATA(content) = field->content(  ).

    fieldname = content->get_alias( ). " Alias is our first best Option

    IF fieldname IS INITIAL.
      fieldname = content->get_original_name( ). " Fallback back to Original Name
    ENDIF.
    IF fieldname IS INITIAL.
      fieldname = field->name.  " Final Option is just the field name but this should never be needed as get_original_name should always return something
    ENDIF.


  ENDMETHOD.


  METHOD _legend. " Build Legend for the diagram to explain colors and line types
    _add( 'legend right' ).
    _add( '|Color| Type |' ).
    _add( '|<#green>|Association|' ).
    _add( '|<#blue>|Composition|' ).
    _add( '|<#black>|Inheritance|' ).
    _add( 'endlegend' ).
  ENDMETHOD.


  METHOD _start.

    _add( '@startuml' ).

    IF format-polyline = abap_true.
      _add( 'skinparam linetype polyline' ).
    ENDIF.

    " Control Line Style
    IF format-ortho = abap_true.
      _add( 'skinparam linetype ortho' ).
    ENDIF.

    " Control Spacing
    IF format-spaced_out = abap_true.
      _add( 'skinparam nodesep 150' ).
      _add( 'skinparam ranksep 150' ).
    ENDIF.

    " Visual Style
    IF format-modern = abap_true.
      _add( 'skinparam shadowing false' ).
      _add( 'skinparam roundcorner 15' ).
    ENDIF.

    _add( 'top to bottom direction' ).

  ENDMETHOD.


  METHOD _fields.

    "Build Field sections ( KEY and Non-Key ) if either were requested

    IF selection-keys = abap_true OR selection-fields = abap_true.

      DATA(normal_field_names) = VALUE string_table( ).

      IF selection-keys = abap_true.
        _add( |---| ).
      ENDIF.

      LOOP AT hierarchy-fields REFERENCE INTO DATA(field).

        DATA(is_key) = field->*->content( )->get_key_indicator( ). " Is this a Key
        DATA(name)   = _getfieldname( field->* ). " Retrieve Real Field Name ( So Alias if it exists, otherwise original name )

        " Dirty Check for associations to avoid duplicates if fields is actually an association ( NEED TO CHANGE THIS!!! )
        IF ( name(1) = '_' ).
          CONTINUE.
        ENDIF.

        " Add As Key
        IF is_key = abap_true.
          IF selection-keys = abap_true.
            _add( |*{  name }| ).
          ENDIF.
        ELSEIF selection-fields = abap_true.
          APPEND name TO normal_field_names. " Normal Fields
        ENDIF.

      ENDLOOP.

      "Build Normal Fields after the loop to ensure they are always below the keys and separated by a line
      IF normal_field_names IS NOT INITIAL AND selection-fields = abap_true.
        _add( |---| ).
        LOOP AT normal_field_names INTO DATA(field_name).
          _add( field_name ).
        ENDLOOP.
      ENDIF.

    ENDIF.
  ENDMETHOD.


  METHOD _associations.

    " Add Associations to the entity block if the fields were requested
    IF selection-associations_Fields = abap_true.
      _add( |-- Associations --| ).
      LOOP AT hierarchy-associations INTO DATA(association).
        _add( CONV #( association->content(  )->get_alias(  )  ) ).
      ENDLOOP.
    ENDIF.

  ENDMETHOD.


  METHOD _relationships.

  "Build Relationships between entities with cardinality and styling based on relationship types

    CONSTANTS many_int TYPE i VALUE 2147483647.

    LOOP AT hierachies ASSIGNING FIELD-SYMBOL(<hierarchy>). "  We need to loop through the hierarchies to get the source and target for the relationships

      LOOP AT <hierarchy>-relationships ASSIGNING FIELD-SYMBOL(<relationship>). " Loop through relationships for each hierarchy and build arrows based on the relationship type and cardinality

        " 1. Scope check: Skip rendering arrow if target isn't in our current scope
        IF selection-force_render_all_relationships = abap_false. "Force Render
          IF NOT line_exists( hierachies[ cds_name_uppercase = to_upper( <relationship>-target ) ]  ).
            CONTINUE.
          ENDIF.
        ENDIF.

        " 2. Granular Line Check
        " Skip if not rendering this relationship type based on user selection
        CASE <relationship>-type.
          WHEN zcl_vdm_plantuml_generator=>c_relation_type-association.
            IF selection-lines-associations = abap_false. CONTINUE. ENDIF.
          WHEN zcl_vdm_plantuml_generator=>c_relation_type-composition.
            IF selection-lines-compositions = abap_false. CONTINUE. ENDIF.
          WHEN zcl_vdm_plantuml_generator=>c_relation_type-inheritance.
            IF selection-lines-inheritance = abap_false. CONTINUE. ENDIF.
        ENDCASE.

        " 3. Map Cardinality
        DATA(min_str) = COND string( WHEN <relationship>-cardinality-min = many_int
                                     THEN '*' ELSE |{ <relationship>-cardinality-min }| ).
        DATA(max_str) = COND string( WHEN  <relationship>-cardinality-max = many_int
                                     THEN '*' ELSE |{ <relationship>-cardinality-max }| ).
        DATA(cardinality) = COND string( WHEN min_str = max_str THEN min_str ELSE |{ min_str }..{ max_str }| ).



        " 4. Determine Style (Colors)
        DATA(color_style) = SWITCH string( <relationship>-type
          WHEN zcl_vdm_plantuml_generator=>c_relation_type-association OR
               zcl_vdm_plantuml_generator=>c_relation_type-composition THEN
            COND #( WHEN <relationship>-is_parent  = abap_true OR <relationship>-has_parent = abap_true THEN '#blue' ELSE '#green' ) " Blue for parent-child relationships ( Compositions ) , Green for siblings
          ELSE '#black' ).

        " 5. Build Arrow Logic
        DATA(arrow) = SWITCH string( <relationship>-type
                        WHEN zcl_vdm_plantuml_generator=>c_relation_type-composition THEN |*-[{ color_style }]->| " Composition with Diamond
                        WHEN zcl_vdm_plantuml_generator=>c_relation_type-inheritance THEN |.[{ color_style }].>| " Inheritance with Dashed Line
                        ELSE |-[{ color_style }]->| ). " Association with normal line

        " 6. Determine Source Anchor - Point to the field alias ONLY if associationsFields are rendered
        DATA(source_anchor) = COND string( WHEN selection-associations_Fields = abap_true AND <relationship>-alias IS NOT INITIAL
                                           THEN |{ <hierarchy>-alias }::{ <relationship>-alias }| " Point to the field alias if association fields are rendered and alias exists
                                           ELSE |{ <hierarchy>-alias }| ). " Otherwise point to the entity as a whole

        " 7. Add to PlantUML output
        _add( |{  source_anchor } { arrow } { <relationship>-target } : { cardinality }| ).

      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.


  METHOD _base.
  "Add Base Entities to the top of the entity block if requested with a divider line
    IF selection-base = abap_true.
      _add( COND #( WHEN hierarchy-union = abap_true THEN '-- Union --' ELSE '-- Base --' ) ).
      LOOP AT hierarchy-sources INTO DATA(source). " We need to loop through the sources as there can be multiple base entities in the case of unions or joins
        _add( CONV #( source ) ).
      ENDLOOP.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
