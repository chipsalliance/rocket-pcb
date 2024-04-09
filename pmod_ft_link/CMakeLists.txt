cmake_minimum_required(VERSION 3.16)

project(pmod_ft_link
    VERSION 2.0.0
    DESCRIPTION "FT2232HL USB JTAG and UART adapter for FPGA Pmod GPIO ports"
    LANGUAGES NONE
)

find_program(KICADCLI_PROGRAM kicad-cli)
if(NOT KICADCLI_PROGRAM)
    message(FATAL_ERROR "kicad-cli was not found")
endif()
execute_process(COMMAND "${KICADCLI_PROGRAM}" version --format plain
    OUTPUT_VARIABLE KICAD_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE
    RESULT_VARIABLE KICAD_VERSION_RESULT)
if(NOT KICAD_VERSION_RESULT EQUAL 0 OR KICAD_VERSION VERSION_LESS 10.0)
    message(FATAL_ERROR "KiCad 10 or newer is required")
endif()

set(BOARD "${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}.kicad_pcb")
set(SCHEMATIC "${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}.kicad_sch")
set(PROJECT_FILE "${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}.kicad_pro")
set(WORKSHEET "${CMAKE_CURRENT_SOURCE_DIR}/template/chipsalliance.kicad_wks")
set(DESIGN_INPUTS "${BOARD}" "${SCHEMATIC}" "${PROJECT_FILE}"
    "${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}.kicad_dru"
    "${CMAKE_CURRENT_SOURCE_DIR}/sym-lib-table"
    "${CMAKE_CURRENT_SOURCE_DIR}/fp-lib-table" "${WORKSHEET}")

# Always run the checks: project rules and submodule libraries can change
# independently of the schematic and board timestamps.
add_custom_target(erc ALL
    COMMAND "${KICADCLI_PROGRAM}" sch erc --severity-error --exit-code-violations
        -o "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_erc.rpt" "${SCHEMATIC}"
    DEPENDS ${DESIGN_INPUTS}
    VERBATIM)
add_custom_target(drc ALL
    COMMAND "${KICADCLI_PROGRAM}" pcb drc --severity-error --schematic-parity
        --exit-code-violations
        -o "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_drc.rpt" "${BOARD}"
    DEPENDS ${DESIGN_INPUTS}
    VERBATIM)

set(LAYERS "F.Cu,B.Cu,F.Mask,B.Mask,F.Paste,B.Paste,F.SilkS,B.SilkS,Edge.Cuts")
set(PRODUCTION_DIR "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_gerber")
add_custom_target(production ALL
    COMMAND "${CMAKE_COMMAND}" -E make_directory "${PRODUCTION_DIR}"
    COMMAND "${KICADCLI_PROGRAM}" pcb export gerbers
        --disable-aperture-macros --no-x2 --subtract-soldermask --use-drill-file-origin
        -l "${LAYERS}" -o "${PRODUCTION_DIR}/" "${BOARD}"
    COMMAND "${KICADCLI_PROGRAM}" pcb export drill --excellon-separate-th
        --excellon-units mm --excellon-zeros-format suppressleading
        --drill-origin plot --generate-map -o "${PRODUCTION_DIR}/" "${BOARD}"
    COMMAND "${KICADCLI_PROGRAM}" pcb export pos
        --format csv --units mm --use-drill-file-origin --bottom-negate-x
        --exclude-dnp --smd-only
        -o "${PRODUCTION_DIR}/${PROJECT_NAME}_positions.csv" "${BOARD}"
    COMMAND "${KICADCLI_PROGRAM}" sch export bom
        --fields "Reference,Value,Footprint,MPN,LCSC,\${QUANTITY},\${DNP}"
        --labels "Reference,Value,Footprint,MPN,LCSC,Qty,DNP"
        --group-by "Value,Footprint,MPN,LCSC,\${DNP}" --exclude-dnp
        -o "${PRODUCTION_DIR}/${PROJECT_NAME}_bom.csv" "${SCHEMATIC}"
    COMMAND "${CMAKE_COMMAND}" -E tar cf "${PROJECT_NAME}_gerber.zip"
        --format=zip "${PROJECT_NAME}_gerber"
    DEPENDS erc drc ${DESIGN_INPUTS}
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
    VERBATIM)

add_custom_target(pdf ALL
    COMMAND "${KICADCLI_PROGRAM}" sch export pdf --no-background-color
        --drawing-sheet "${WORKSHEET}"
        -o "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_sch.pdf" "${SCHEMATIC}"
    COMMAND "${KICADCLI_PROGRAM}" pcb export pdf --ibt
        --drawing-sheet "${WORKSHEET}" -l "${LAYERS}"
        -o "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_pcb.pdf" "${BOARD}"
    DEPENDS ${DESIGN_INPUTS}
    VERBATIM)
