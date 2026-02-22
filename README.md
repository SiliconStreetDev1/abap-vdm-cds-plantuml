# VDM PlantUML Generator 🚀

**Visualize your SAP CDS Virtual Data Model (VDM) hierarchies with ease.**

The **VDM PlantUML Generator** is a ABAP tool designed to recursively discover and visualize CDS View relationships. It supports `ASSOCIATIONS`, `COMPOSITIONS`, or `INHERITANCE`, this tool parses your metadata via the XCO Framework to generate PlantUML code.

---

## 📄 License & Terms

**© 2026 Silicon Street Limited. All Rights Reserved.**

### Usage Terms:
1. **INTERNAL USE:** Permission is granted to use this code for internal business documentation purposes within a single organization at no cost.
2. **NON-REDISTRIBUTION:** You may **NOT** redistribute, sell, or include this source code (or derivatives thereof) in any commercial software, package, or library.
3. **PAID SERVICES:** Use of this code to provide paid consulting or documentation services to third parties requires a **Commercial License**.
4. **MODIFICATIONS:** Any modifications remain subject to this license.

**DISCLAIMER:** THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY ARISING FROM THE USE OF THE SOFTWARE.

**FOR COMMERCIAL LICENSING INQUIRIES:** [admin@siliconst.co.nz](mailto:admin@siliconst.co.nz)

---

## 📋 Compatibility & Requirements

* **Primary Support:** **SAP S/4HANA 2023** and higher.
* **Legacy Support (S/4HANA 2022):** The tool may function on 2022, but it is **not fully supported**. 
    * *Note:* The XCO Framework underwent significant API changes between 2022 and 2023. You may encounter "Method Not Found" exceptions or incorrect cardinality mapping on older releases.
* **XCO Framework:** Standard availability in modern S/4HANA and BTP is required.
2: Technical Usage & Granular Examples
Markdown
## 🛠 Usage & Detailed Examples

The generator is designed for **inline usage**. You pass a `selection` structure to the constructor and call the `generate()` method.

### 1. Basic Generation with Granular Toggles
Discovery and Lines are split into granular toggles. This allows you to find a parent CDS (Discovery) but choose not to draw the inheritance line (Lines) to keep the diagram clean.

```abap
DATA(lt_plantuml) = NEW zcl_vdm_plantuml_generator( 
  selection = VALUE #(
    cds_name          = 'I_BUSINESSPARTNER'
    max_allowed_level = 3
    base              = abap_true " Show underlying tables/views
    keys              = abap_true " Show key fields with *
    fields            = abap_true " Show non-key fields
    associations_fields = abap_true " List associations names inside the box
    
    " Discovery: Which entities to find via recursion
    discovery = VALUE #( 
      inheritance  = abap_true 
      associations = abap_true 
      compositions = abap_true 
    )

    " Lines: Which arrows to actually draw between boxes
    lines = VALUE #( 
      inheritance  = abap_true 
      associations = abap_true 
      compositions = abap_true 
    )
  ) 
)->generate( ).
```

2. Advanced Filtering: Inclusions & Exclusions
Control the scope of discovery. The root cds_name is always included by default to ensure the diagram generates, even if it matches an exclusion rule.

ABAP
```abap
DATA(lt_plantuml) = NEW zcl_vdm_plantuml_generator( 
  selection = VALUE #(
    cds_name          = 'I_BUSINESSPARTNER'
    max_allowed_level = 5
    " INCLUSION: ONLY expand these views into boxes
    include_cds = VALUE #( ( cds_name = 'I_BPDATACONTROLLER' ) 
                           ( cds_name = 'I_BPCUSTOMER' ) )
    " EXCLUSION: Block these views from discovery entirely
    exclude_cds = VALUE #( ( cds_name = 'I_SADL_MAPPING' ) )
  ) 
)->generate( ).
```

### 3. Custom Development Filter (Z/Y Namespace)
This mode hides standard SAP noise by only rendering entity boxes for your custom developments.

```abap
DATA(lt_plantuml) = NEW zcl_vdm_plantuml_generator( 
  selection = VALUE #(
    cds_name                 = 'Z_MY_CUSTOM_ROOT'
    max_allowed_level        = 3
    custom_developments_only = abap_true " Only select entities starting with Z* or Y*
    " Force Render: Shows entities as classes even if they are not part of the levels allowed. Only the name will be displatyed
    force_render_all_relationships = abap_true 
  ) 
)->generate( ).
```
☁️ Cloud (BTP/ABAP Cloud) vs. On-Premise
The tool utilizes the Adapter Pattern to handle environment differences:

On-Premise: Broader access to the ABAP Repository. Includes fallback logic to parse DDL source code via regex if the XCO API encounters unreleased or complex UNION / JOIN statements that the standard API (XCO) cannot yet handle.

Cloud (BTP / Public Edition): Restricted to Tier 1 (Cloud Optimized) ABAP. The generator only interacts with "Released" entities or those within your own software components. Low-level DDIC table reads (like DDDLSVRC) are prohibited.


### BLOCK 4: Parameter Reference & Roadmap
markdown
## ⚙️ Parameter Reference

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `cds_name` | String | The root CDS view to start discovery from. |
| `max_allowed_level` | Integer | Max recursion depth. Recommended: 3-5. |
| `discovery` | Toggle | Logic for finding `inheritance`, `associations`, or `compositions`. |
| `lines` | Toggle | Visualization settings for drawing arrows between boxes. |
| `base` | Boolean | If `true`, shows the data source (tables/views) at the top. |
| `keys` | Boolean | If `true`, displays key fields with a `*` prefix. |
| `fields` | Boolean | If `true`, displays all non-key fields. |
| `associations_fields` | Boolean | Lists association names inside the entity box. |
| `custom_developments_only`| Boolean | Only draws boxes for the `Z*` and `Y*` namespaces. |
| `include_cds` | Table | Exclusive list: Only these views  / entities will be expanded into boxes. |
| `exclude_cds` | Table | Block list: These views / entities will be ignored by the generator. |

---

## 🗺 Roadmap

* **Fiori Application**: We are planning a full-stack SAP Fiori application to dynamically generate and display PlantUML diagrams within the SAP environment.

---
**Developed with ❤️ by Silicon Street Limited.**
*For inquiries, contact [admin@siliconst.co.nz](mailto:admin@siliconst.co.nz)*
