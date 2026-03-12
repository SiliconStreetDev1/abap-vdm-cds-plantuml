CLASS zcl_vdm_diagram_graphviz DEFINITION
  PUBLIC
  INHERITING FROM zcl_vdm_diagram_base
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_format,
             ortho             TYPE abap_bool,
             polyline          TYPE abap_bool,
             spaced_out        TYPE abap_bool,
             modern            TYPE abap_bool,
             left_to_right     TYPE abap_bool, " Renders horizontally instead of vertically
             concentrate_edges TYPE abap_bool, " Merges multiple parallel lines into one
             monochrome        TYPE abap_bool, " Forces black-and-white for printing/PDFs
           END OF ty_format.

    METHODS constructor IMPORTING format TYPE ty_format OPTIONAL.

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



CLASS ZCL_VDM_DIAGRAM_GRAPHVIZ IMPLEMENTATION.


  METHOD constructor.
    " Initialize the base diagram generator class
    " Store the visual formatting preferences passed in by the caller
    super->constructor( ).
    me->format = format.
  ENDMETHOD.


  METHOD zif_vdm_diagram_hooks~on_associations.
    " Draw a visual separator line and an italicized header for the associations block
    add_text( '      <HR/>' ).
    add_text( '      <TR><TD ALIGN="LEFT"><I>-- Associations --</I></TD></TR>' ).

    " Iterate through each association alias belonging to the entity.
    " Graphviz uses the PORT attribute to tag a specific HTML table cell.
    " Later, we can bind the relationship line directly to this PORT so the arrow
    " originates from the exact field name rather than the center of the table.
    LOOP AT association_aliases INTO DATA(association).
      add_text( |      <TR><TD ALIGN="LEFT" PORT="{ association }">{ association }</TD></TR>| ).
    ENDLOOP.
  ENDMETHOD.


  METHOD zif_vdm_diagram_hooks~on_base_elements.
    " Draw a visual separator line for the underlying database views or tables
    add_text( '      <HR/>' ).

    " Determine the correct heading text based on the entity type
    DATA(header_text) = COND string( WHEN is_union_entity = abap_true THEN '-- Union --' ELSE '-- Base --' ).
    add_text( |      <TR><TD ALIGN="LEFT"><I>{ header_text }</I></TD></TR>| ).

    " Output each underlying data source as a new row in the HTML table
    LOOP AT base_sources INTO DATA(base_source).
      add_text( |      <TR><TD ALIGN="LEFT">{ base_source }</TD></TR>| ).
    ENDLOOP.
  ENDMETHOD.


  METHOD zif_vdm_diagram_hooks~on_end.
    " Close the master directed graph definition envelope
    add_text( '}' ).
  ENDMETHOD.


  METHOD zif_vdm_diagram_hooks~on_entity_end.
    " Close the HTML-like table and terminate the node declaration
    add_text( '    </TABLE>>' ).
    add_text( '  ];' ).
  ENDMETHOD.


  METHOD zif_vdm_diagram_hooks~on_entity_start.
    " Graphviz uses HTML-like syntax to draw complex nodes like UML classes.
    " Setting the border to 1 and cellborder to 0 gives us the classic UML box look.

    " If this is the main entity being diagrammed, shade the header grey to stand out.
    " However, if monochrome mode is requested, force all backgrounds to white.
    DATA(background_color) = COND string(
      WHEN is_focal_entity = abap_true AND format-monochrome = abap_false THEN 'BGCOLOR="lightgray"'
      ELSE 'BGCOLOR="white"' ).

    " If the user requested the modern format, apply rounded corners to the outer table
    DATA(table_style) = COND string( WHEN format-modern = abap_true THEN 'STYLE="ROUNDED"' ELSE '' ).

    " Declare the node ID and open the HTML label payload
    add_text( |  { alias } [| ).
    add_text( |    label=<| ).
    add_text( |    <TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" { table_style }>| ).
    add_text( |      <TR><TD { background_color }><B>{ alias }</B></TD></TR>| ).
  ENDMETHOD.


  METHOD zif_vdm_diagram_hooks~on_fields.
    " Output primary key fields first, prefixed with a plus sign for visibility
    IF selection-keys = abap_true.
      add_text( '      <HR/>' ).
      LOOP AT key_fields INTO DATA(key_field).
        add_text( |      <TR><TD ALIGN="LEFT">+ { key_field }</TD></TR>| ).
      ENDLOOP.
    ENDIF.

    " Output standard data fields next, indented with spaces to align with the keys
    IF standard_fields IS NOT INITIAL AND selection-fields = abap_true.
      add_text( '      <HR/>' ).
      LOOP AT standard_fields INTO DATA(standard_field).
        add_text( |      <TR><TD ALIGN="LEFT">  { standard_field }</TD></TR>| ).
      ENDLOOP.
    ENDIF.
  ENDMETHOD.


  METHOD zif_vdm_diagram_hooks~on_legend.
    " If monochrome mode is active, the color-coded legend is redundant, so we skip it.
    IF format-monochrome = abap_true.
      RETURN.
    ENDIF.

    " Wrap the legend in a rank=sink block. This forces the Graphviz layout engine
    " to push this specific node to the absolute bottom (or far right, depending on layout direction)
    " of the generated diagram canvas, keeping it completely out of the way of the data flow.
    add_text( '  { rank=sink;' ).
    add_text( '    legend [' ).
    add_text( '      shape=none' ).
    add_text( '      label=<' ).
    add_text( '      <TABLE BORDER="1" CELLBORDER="1" CELLSPACING="0">' ).
    add_text( '        <TR><TD COLSPAN="2" BGCOLOR="lightgray"><B>Legend</B></TD></TR>' ).
    add_text( '        <TR><TD BGCOLOR="green"> </TD><TD ALIGN="LEFT">Association</TD></TR>' ).
    add_text( '        <TR><TD BGCOLOR="blue"> </TD><TD ALIGN="LEFT">Composition</TD></TR>' ).
    add_text( '        <TR><TD BGCOLOR="black"> </TD><TD ALIGN="LEFT">Inheritance</TD></TR>' ).
    add_text( '      </TABLE>>' ).
    add_text( '    ];' ).
    add_text( '  }' ).
  ENDMETHOD.


  METHOD zif_vdm_diagram_hooks~on_relationship.
    " Evaluate the relationship type to determine the color of the connecting line.
    " Parent/child structural associations are colored blue, standard joins are green.
    " If monochrome formatting is active, all lines are forced to standard black.
    DATA(edge_color) = SWITCH string( relationship_type
      WHEN zcl_vdm_diagram_generator=>c_relation_type-association OR zcl_vdm_diagram_generator=>c_relation_type-composition
        THEN COND #( WHEN format-monochrome = abap_true THEN 'black'
                     WHEN is_parent_entity = abap_true OR has_parent_entity = abap_true THEN 'blue'
                     ELSE 'green' )
      ELSE 'black' ).

    " Select the Graphviz arrowhead shape that corresponds to standard UML notation
    DATA(arrow_shape) = SWITCH string( relationship_type
      WHEN zcl_vdm_diagram_generator=>c_relation_type-composition THEN 'diamond'
      WHEN zcl_vdm_diagram_generator=>c_relation_type-inheritance THEN 'empty'
      ELSE 'vee' ).

    " Apply a dotted stroke style for inheritance lines, leaving the rest solid
    DATA(edge_style) = COND string( WHEN relationship_type = zcl_vdm_diagram_generator=>c_relation_type-inheritance THEN 'dotted' ELSE 'solid' ).

    " Construct the source port binding string (Format: NodeID:PortID).
    " This instructs the Graphviz layout engine to draw the arrow directly out of the specific
    " table row containing the association name, rather than the generic node boundary.
    DATA(source_port_binding) = COND string( WHEN selection-associations_fields = abap_true AND association_alias IS NOT INITIAL
                                       THEN |{ source_alias }:{ association_alias }|
                                       ELSE source_alias ).

    " Print the final compiled edge definition combining source, target, cardinality label, and styling
    add_text( |  { source_port_binding } -> { target_alias } [label="{ cardinality_text }", color="{ edge_color }", arrowhead="{ arrow_shape }", style="{ edge_style }"];| ).
  ENDMETHOD.


  METHOD zif_vdm_diagram_hooks~on_start.
    " Open the directed graph payload
    add_text( 'digraph VDM {' ).

    " Apply global font settings to all nodes and edges.
    " Setting shape=none globally ensures our custom HTML tables are rendered bare
    " instead of being drawn inside a default oval or rectangle border.
    add_text( '  node [shape=none, fontname="Helvetica", fontsize=10];' ).
    add_text( '  edge [fontname="Helvetica", fontsize=10];' ).

    " Set the layout direction based on user preference (Left-to-Right vs Top-to-Bottom)
    DATA(layout_direction) = COND string( WHEN format-left_to_right = abap_true THEN 'LR' ELSE 'TB' ).
    add_text( |  rankdir={ layout_direction };| ).

    " Apply custom line routing algorithms based on the constructor format options
    IF format-polyline = abap_true.
      add_text( '  splines=polyline;' ).
    ENDIF.
    IF format-ortho = abap_true.
      add_text( '  splines=ortho;' ).
    ENDIF.

    " Instruct Graphviz to merge parallel edges into a single trunk to reduce visual clutter
    IF format-concentrate_edges = abap_true.
      add_text( '  concentrate=true;' ).
    ENDIF.

    " Increase the canvas coordinate spacing to stretch the diagram out visually
    IF format-spaced_out = abap_true.
      add_text( '  nodesep=1.0;' ).
      add_text( '  ranksep=1.0;' ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
