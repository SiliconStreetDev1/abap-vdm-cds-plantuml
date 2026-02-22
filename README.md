# VDM PlantUML Generator 🚀

**Visualize your SAP CDS Virtual Data Model (VDM) hierarchies with ease.**

The **VDM PlantUML Generator** is a high-performance ABAP tool designed to recursively discover and visualize CDS View relationships. Whether you are dealing with complex `ASSOCIATIONS`, `COMPOSITIONS`, or `INHERITANCE`, this tool parses your metadata via the XCO Framework to generate clean, professional PlantUML code.

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

---

## ☁️ Cloud (BTP/ABAP Cloud) vs. On-Premise

The tool is built to be environment-aware using the **Adapter Pattern**, but there are fundamental differences in how metadata is accessed:

* **On-Premise:** Broader access to the ABAP Repository. Includes fallback logic to parse DDL source code via regex if the XCO API encounters unreleased or complex select statements like `UNIONs`.
* **Cloud (BTP / Public Edition):** Restricted to **Tier 1 (Cloud Optimized)** ABAP. The generator only interacts with "Released (API Contract)" entities or those within your own software components. Low-level DDIC table reads are prohibited.

---

## 🛠 Usage

Currently, the tool operates as an ABAP API that returns a `string_table` containing PlantUML code.

### Basic Implementation
```abap
DATA(lt_plantuml) = NEW zcl_vdm_plantuml_generator( 
  selection = VALUE #(
    cds_name          = 'I_BUSINESSPARTNER'
    max_allowed_level = 3
    base              = abap_true
    fields            = abap_true
    keys              = abap_true
    lines             = VALUE #( associations = abap_true compositions = abap_true )
  ) 
)->generate( ).
