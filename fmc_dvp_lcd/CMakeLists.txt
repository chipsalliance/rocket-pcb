cmake_minimum_required(VERSION 3.18)
project(fmc_dvp_lcd VERSION 0.1.0 LANGUAGES NONE
    DESCRIPTION "FMC DVP camera and 8080 LCD peripheral card")

find_program(KICADCLI_PROGRAM kicad-cli REQUIRED)
find_program(FRUGY_PROGRAM frugy REQUIRED)

file(GLOB PROJECT_SCH_FILES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/*.kicad_sch")
file(GLOB PROJECT_SYMBOL_LIBRARIES CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/library/CHIPSAlliance_*.kicad_sym")
file(GLOB PROJECT_FOOTPRINT_LIBRARIES CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/library/CHIPSAlliance_*.pretty/*.kicad_mod")
set(PROJECT_BASE "${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}")
set(PROJECT_WKS "${CMAKE_CURRENT_SOURCE_DIR}/template/chipsalliance.kicad_wks")
set(PROJECT_INPUTS ${PROJECT_SCH_FILES}
    ${PROJECT_SYMBOL_LIBRARIES}
    "${PROJECT_BASE}.kicad_pro" "${CMAKE_CURRENT_SOURCE_DIR}/sym-lib-table")

add_custom_target(erc DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_erc.rpt")
add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_erc.rpt"
    COMMAND ${KICADCLI_PROGRAM} sch erc --severity-all --exit-code-violations
        -o "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_erc.rpt"
        "${PROJECT_BASE}.kicad_sch"
    DEPENDS ${PROJECT_INPUTS}
    VERBATIM)

add_custom_target(drc DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_drc.json")
add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_drc.json"
    # Check all errors and warnings while honoring documented project exclusions.
    COMMAND ${KICADCLI_PROGRAM} pcb drc --severity-error --severity-warning --schematic-parity
        --exit-code-violations --format json
        -o "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_drc.json"
        "${PROJECT_BASE}.kicad_pcb"
    DEPENDS "${PROJECT_BASE}.kicad_pcb" ${PROJECT_INPUTS}
        "${PROJECT_BASE}.kicad_dru"
        ${PROJECT_FOOTPRINT_LIBRARIES}
        "${CMAKE_CURRENT_SOURCE_DIR}/fp-lib-table"
    VERBATIM)

add_custom_target(pdf DEPENDS
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_sch.pdf"
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_pcb.pdf")
add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_sch.pdf"
    COMMAND ${KICADCLI_PROGRAM} sch export pdf --no-background-color
        --drawing-sheet "${PROJECT_WKS}"
        -o "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_sch.pdf"
        "${PROJECT_BASE}.kicad_sch"
    DEPENDS ${PROJECT_INPUTS} "${PROJECT_WKS}"
    VERBATIM)
add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_pcb.pdf"
    COMMAND ${KICADCLI_PROGRAM} pcb export pdf --ibt
        --drawing-sheet "${PROJECT_WKS}" -l "F.Cu,B.Cu,F.SilkS,B.SilkS,Edge.Cuts,Dwgs.User"
        -o "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_pcb.pdf"
        "${PROJECT_BASE}.kicad_pcb"
    DEPENDS "${PROJECT_BASE}.kicad_pcb" "${PROJECT_BASE}.kicad_pro" "${PROJECT_WKS}"
    VERBATIM)

add_custom_target(eeprom DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/fmc_fru_eeprom.bin")
add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/fmc_fru_eeprom.bin"
    COMMAND ${FRUGY_PROGRAM} "${CMAKE_CURRENT_SOURCE_DIR}/data/fmc_fru_eeprom.yml"
        -o "${CMAKE_CURRENT_BINARY_DIR}/fmc_fru_eeprom.bin" -e 8192
    DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/data/fmc_fru_eeprom.yml"
    VERBATIM)

find_program(FREECADCMD_PROGRAM NAMES FreeCADCmd freecadcmd)
if(FREECADCMD_PROGRAM)
    add_custom_target(mechanical
        COMMAND ${CMAKE_COMMAND} -E env
            "FMC_MECHANICAL_OUTPUT=${CMAKE_CURRENT_BINARY_DIR}/mechanical/camera_lcd"
            "PYTHONDONTWRITEBYTECODE=1"
            ${FREECADCMD_PROGRAM}
            "${CMAKE_CURRENT_SOURCE_DIR}/mechanical/camera_lcd/assembly.py"
        DEPENDS
            "${CMAKE_CURRENT_SOURCE_DIR}/mechanical/camera_lcd/assembly.py"
            "${CMAKE_CURRENT_SOURCE_DIR}/mechanical/camera_lcd/parameters.json"
            "${CMAKE_CURRENT_SOURCE_DIR}/mechanical/camera_lcd/reference.FCStd"
            "${PROJECT_BASE}.kicad_pcb"
        COMMENT "Generate the camera and LCD mechanical prototype"
        VERBATIM)
endif()

# Exporting this development scaffold does not constitute manufacturing approval.
set(PRODUCTION_DIR "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_gerber")
add_custom_target(production DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_gerber.zip")
add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_gerber.zip"
    COMMAND ${CMAKE_COMMAND} -E rm -rf "${PRODUCTION_DIR}"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${PRODUCTION_DIR}"
    COMMAND ${KICADCLI_PROGRAM} pcb export gerbers --disable-aperture-macros --no-x2
        -o "${PRODUCTION_DIR}/"
        -l "F.Cu,In1.Cu,In2.Cu,In3.Cu,In4.Cu,B.Cu,F.Mask,B.Mask,F.Paste,B.Paste,F.SilkS,B.SilkS,Edge.Cuts"
        "${PROJECT_BASE}.kicad_pcb"
    COMMAND ${KICADCLI_PROGRAM} pcb export drill --excellon-separate-th
        --excellon-units mm -o "${PRODUCTION_DIR}/" "${PROJECT_BASE}.kicad_pcb"
    COMMAND ${KICADCLI_PROGRAM} sch export bom
        --fields "Reference,Value,Footprint,\${QUANTITY},\${DNP},MPN,LCSC,AssemblyNote"
        --labels "Reference,Value,Footprint,Qty,DNP,MPN,LCSC,AssemblyNote"
        --group-by "Value,Footprint,\${DNP},MPN,LCSC,AssemblyNote"
        -o "${PRODUCTION_DIR}/${PROJECT_NAME}_bom.csv" "${PROJECT_BASE}.kicad_sch"
    COMMAND ${KICADCLI_PROGRAM} sch export netlist --format kicadxml
        -o "${PRODUCTION_DIR}/${PROJECT_NAME}_bom.xml" "${PROJECT_BASE}.kicad_sch"
    COMMAND ${CMAKE_COMMAND} -E tar cf "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_gerber.zip"
        --format=zip "${PROJECT_NAME}_gerber"
    DEPENDS "${PROJECT_BASE}.kicad_pcb" ${PROJECT_INPUTS}
    VERBATIM)
