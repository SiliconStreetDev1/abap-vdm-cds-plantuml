# ABAP VDM / CDS PlantUML Generator 🚀

**Visualize your SAP CDS Virtual Data Model (VDM) hierarchies with ease.**

The **VDM PlantUML Generator** is a ABAP tool designed to recursively discover and visualize CDS View relationships. It supports `ASSOCIATIONS`, `COMPOSITIONS`, or `INHERITANCE`, this tool parses your metadata via the XCO Framework to generate PlantUML code.
<img width="2339" height="1672" alt="image" src="https://github.com/user-attachments/assets/0ad64a8e-b11d-4d72-9c71-c64c3d4b1895" />

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

## 🛠 Usage & Detailed Examples

The generator is designed for **inline usage**. You pass a `selection` structure to the constructor and call the `generate()` method.

# 🛠 Primary Parameters
| Parameter | Type | Description |
| :--- | :--- | :--- |
| `cds_name` | String | The root CDS view name used as the starting point. The engine typically moves **down** the hierarchy from here, unless `inheritance` is enabled, which triggers an **upward** discovery. |
| `max_allowed_level` | Integer | Defines the recursion depth. This limits how many levels the engine will traverse across `Associations`, `Inheritance` (Upward), and `Compositions`. |

### 1. Basic Generation with Granular Toggles

The engine splits relationship logic into two granular toggle sets. However, to simplify the experience, **enabling a relationship line automatically triggers the discovery of that target.**

| Component | Logic | Description |
| :--- | :--- | :--- |
| **Discovery** | **Manual Search** | Used when you want to find and display entities in the diagram *without* drawing relationship arrows. This is ideal for "Landscape" views where you want to see the entities but avoid "Spaghetti" lines. |
| **Lines** | **Auto-Discovery** | When a specific line type is enabled (e.g., `compositions`), the engine **automatically enables** discovery for that type. You do not need to manually toggle `discovery` if you intend to draw the lines. |

## Discovery Only
```abap
DATA(plantuml) = NEW zcl_vdm_plantuml_generator(
  selection = VALUE #(
    cds_name          = 'I_BUSINESSPARTNER'

    max_allowed_level = 2

    " Discovery: Which entities to find via recursion ( Optional if Lines is also used for a specific relationship type )
    discovery = VALUE #(
      inheritance  = abap_true
      associations = abap_true
      compositions = abap_true
     )
    )
  )->generate( ).
```
<img width="1300" height="530" alt="image" src="https://github.com/user-attachments/assets/b978ba6e-c649-46c7-88a7-176ef5d69fd9" />

## Lines Only
```abap
DATA(plantuml) = NEW zcl_vdm_plantuml_generator(
  selection = VALUE #(
    cds_name          = 'I_BUSINESSPARTNER'

    max_allowed_level = 2

  " Lines:  Which entities to find via recursion and draw relationship lines
  Lines = VALUE #(
      inheritance  = abap_true
      associations = abap_true
      compositions = abap_true
     )
    )
  )->generate( ).
```
<img width="1700" height="250" alt="image" src="https://github.com/user-attachments/assets/351ed75d-2049-402d-bbfd-5aad3a9d7973" />

### 2. Advanced Filtering: Inclusions & Exclusions
You can precisely control which entities appear in your visualization using inclusion and exclusion rules. To prevent accidental empty diagrams, the **root `cds_name` is always included by default**, even if it satisfies a broader exclusion rule.

Typically, you will use either an inclusion or an exclusion strategy, rather than combining both:

* **Inclusion Strategy:** Use this when you want to focus strictly on a specific subset of views. Only the entities explicitly listed will be rendered.
* **Exclusion Strategy:** Use this to "clean up" a diagram by hiding known noise, such as technical mapping entities.

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `include_cds` | Table | **Whitelist:** Only the CDS views specified in this table will be processed and rendered in the diagram. |
| `exclude_cds` | Table | **Blacklist:** These CDS views will be ignored by the engine and omitted from the visualization. |

ABAP (Include)

```abap
DATA(plantuml) = NEW zcl_vdm_plantuml_generator(
  selection = VALUE #(
    cds_name          = 'I_BUSINESSPARTNER'
    max_allowed_level = 2
    lines  = VALUE #( associations  = abap_true  )

    " INCLUSION: ONLY expand these views into boxes
     include_cds = VALUE #(  ( cds_name =  'I_BPDATACONTROLLER'  )
                             ( cds_name =  'I_BPRELATIONSHIP_2' ) )
  )
)->generate( ).
```

ABAP (Include)
```abap
DATA(plantuml) = NEW zcl_vdm_plantuml_generator(
  selection = VALUE #(
    cds_name          = 'I_BUSINESSPARTNER'
    max_allowed_level = 2
    lines  = VALUE #( associations  = abap_true  )

    " Exclude these views from selections
     exclude_cds = VALUE #(  ( cds_name =  'I_BPDATACONTROLLER'  )
                             ( cds_name =  'I_BPRELATIONSHIP_2' ) )
  )
)->generate( ).
```


### 3. Custom Development Filter (Z/Y Namespace)
This mode hides standard SAP noise by only rendering entity boxes for your custom developments.

```abap
DATA(plantuml) = NEW zcl_vdm_plantuml_generator(
  selection = VALUE #(
    cds_name                 = 'ZR_BloxUIHeaderTP' "My Custom RAP Model
    max_allowed_level        = 5 "Lets go 5 levels down
    lines  = VALUE #( compositions  = abap_true  associations = abap_true ) " we want compositions and associations remember the association up is a composition but technically a associations so you must add it
    custom_developments_only = abap_true " Only select entities starting with Z* or Y* 
  )
)->generate( ).
```
<img width="290" height="605" alt="image" src="https://github.com/user-attachments/assets/8d38059b-21e2-42c6-a0f1-03a0d619ff26" />

### 4. 🧱 Field Rendering & Association Mapping

The generator provides granular control over the internal structure of the entity boxes. This allows you to toggle between a high-level architectural view and a detailed technical data model.

### Field Type Logic

| Field Type | Toggle | Visual Representation |
| :--- | :--- | :--- |
| **Key Fields** | `keys` | Rendered at the top of the box with a `*` prefix to denote primary identification. |
| **Normal Fields** | `fields` | Standard non-key attributes listed below the keys. |
| **Association Fields** | `associations_fields` | Lists the names of defined associations within the entity box itself. |

## 🎯 Relationship Line Anchoring

The behavior of relationship lines (arrows) changes based on your `associations_fields` setting to ensure maximum clarity:

1. **Standard Mode (`associations_fields = abap_false`):** Relationship lines are drawn from the **border of the source box** to the border of the target box. This is the cleanest view for high-level VDM overviews.
2. **Detailed Mode (`associations_fields = abap_true`):** When associations are listed inside the box, the generator anchors the relationship lines **directly to the specific field name** within the box. 



> **Why use Detailed Mode?** Mapping lines directly to association fields is invaluable when a single CDS view has multiple associations to the same target view (e.g., `_CreatedByUser` and `_LastChangedByUser` both pointing to `I_User`). It explicitly shows which field triggers which relationship.

---

### Implementation Example

```abap
DATA(plantuml) = NEW zcl_vdm_plantuml_generator( 
  selection = VALUE #(
    cds_name            = 'I_BUSINESSPARTNER'
    keys                = abap_true
    fields              = abap_true
    max_allowed_level        = 1
    associations_fields = abap_true " Lines will now point to internal fields
    lines               = VALUE #( associations = abap_true )
  ) 
)->generate( ).
```
<img width="150" height="1360" alt="image" src="https://github.com/user-attachments/assets/07e44e3a-4bda-4754-b6d9-a4fa1a84f905" />

☁️ Cloud (BTP/ABAP Cloud) vs. On-Premise
The tool utilizes the Adapter Pattern to handle environment differences:

On-Premise: Broader access to the ABAP Repository. Includes fallback logic to parse DDL source code via regex if the XCO API encounters unreleased or complex UNION / JOIN statements that the standard API (XCO) cannot yet handle.

Cloud (BTP / Public Edition): Restricted to Tier 1 (Cloud Optimized) ABAP. The generator only interacts with "Released" entities or those within your own software components. Low-level DDIC table reads (like DDDLSVRC) are prohibited.


### 6: Parameter Reference 

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
### 6: Layout & Visual Formatting (`ty_format_options`) 
Controls the PlantUML rendering engine's line routing and aesthetic styling.

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `ortho` | Boolean | Forces all relationship lines to use **90-degree angles**. Prevents diagonal "spaghetti" lines in complex models. |
| `polyline` | Boolean | Uses **segmented, angled lines**. Provides flexible routing in dense clusters to avoid overlapping boxes. |
| `spaced_out` | Boolean | Significantly **increases padding** between entities. Essential for views with many fields to maintain readability. |
| `staggered` | Boolean | Forces lines to enter/exit from the **Left and Right sides** of the box to prevent bunching at the top or bottom. |
| `modern` | Boolean | Applies **modern styling**: rounded corners, flat design, and removes legacy drop-shadows. |

### Usage Example

```abap

DATA(plantuml)  = NEW zcl_vdm_plantuml_generator(
 selection = VALUE #(
   cds_name       = 'I_BUSINESSPARTNER'
   max_allowed_level = 3
   fields = abap_true
   keys = abap_true
   lines = VALUE #(  associations = abap_true )
   include_cds = VALUE #( ( cds_name = 'I_BPRelationship_2' )
                          ( cds_name = 'I_FormOfAddress'  )
                          ( cds_name ='I_Paymentcard' )
                          ( cds_name ='I_BPDataController' )
                            )
                       )
    format = VALUE #(
     ortho      = abap_true  " Clean 90-degree routing
     modern     = abap_true  " Rounded corners, no shadows
     spaced_out = abap_true  " Maximum readability
   )
)->generate( ).
```
<img width="150" height="1250" alt="image" src="https://github.com/user-attachments/assets/22566e09-0542-4954-afcc-8349d797126e" />


## 🗺 Roadmap

* **Fiori Application**: We are planning a full-stack SAP Fiori application to dynamically generate and display PlantUML diagrams within the SAP environment.

---
**Developed with ❤️ by Silicon Street Limited.**
*For inquiries, contact [admin@siliconst.co.nz](mailto:admin@siliconst.co.nz)*
